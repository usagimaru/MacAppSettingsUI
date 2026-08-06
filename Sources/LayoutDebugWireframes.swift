//
//  LayoutDebugWireframes.swift
//
//  Created by usagimaru on 2026/08/06.
//

import Cocoa

/// Colors that tell the levels of a layout apart
public enum LayoutDebugWireframeColor {

	/// Whole container
	public static let container = NSColor.systemBlue
	/// Section border
	public static let section = NSColor.systemOrange
	/// Section area. Told apart from the border, so both can be read at once
	public static let sectionFill = NSColor.systemBlue
	/// Label column box
	public static let labelColumn = NSColor.systemRed
	/// Item column box
	public static let itemColumn = NSColor.systemGreen
	/// Labels and controls
	public static let control = NSColor.systemPurple

}

/// Edge a rule follows. Read off the frame, so it does not flip with the writing direction
public enum LayoutDebugWireframeEdge {

	case minX
	case maxX
	case minY
	case maxY
	case centerX
	case centerY

}

/// Outlines views and layout guides for debugging, and draws rules that tell whether edges line up.
/// A view is outlined through its own layer, while a guide has a layer laid into the host on its behalf
public final class LayoutDebugWireframes {

	/// Line width shared by every outline and rule
	public static let lineWidth: CGFloat = 1
	/// Alpha applied to the colors, so a line never hides what sits under it
	public static let colorAlpha: CGFloat = 0.5
	/// Alpha of a filled area. Kept far lighter than a line, since it covers the content rather than bordering it
	public static let fillAlpha: CGFloat = 0.12
	/// Alpha of a readout. Glyphs are thin, so they need more weight than a line to stay legible
	public static let textAlpha: CGFloat = 0.85
	/// Gap between a readout and the rect it measures
	public static let readoutSpacing: CGFloat = 2
	/// Alpha of a hatch. Lines leave the content visible between them, so they can carry more weight than a flat fill
	public static let hatchAlpha: CGFloat = 0.15
	/// Gap between the hatch lines
	public static let hatchSpacing: CGFloat = 6

	/// How far a rule runs past the host bounds. Lets a rule reach the edges of the view the host was laid into
	public var ruleOverhang: CGFloat = 0 {
		didSet {
			updateLayout()
		}
	}

	/// Whether the wireframes are visible. Assigning true has no effect outside a DEBUG build
	public var isEnabled: Bool {
		get {
			isVisible
		}
		set {
#if DEBUG
			isVisible = newValue
#else
			isVisible = false
#endif
			applyVisibility()
		}
	}

	private unowned let host: NSView
	private var isVisible = false
	private var viewEntries = [ViewEntry]()
	private var boxEntries = [LayerEntry]()
	private var ruleEntries = [LayerEntry]()
	private var readoutEntries = [ReadoutEntry]()

	/// Holds the boxes and fills. A container keeps them stacked in the order they were registered
	private lazy var backdropLayer = makeContainerLayer(zPosition: -1000)
	/// Holds the rules. A thin line would be lost behind a control, so it is pulled to the very front
	private lazy var overlayLayer = makeContainerLayer(zPosition: 1000)


	// MARK: - Initialization

	public init(host: NSView) {
		self.host = host
	}


	// MARK: - Registration

	/// Outline a view through its own layer. Auto Layout keeps the border in place, so it needs no update.
	/// Passing `descendantColor` outlines the views inside it as well
	public func add(view: NSView, color: NSColor, descendantColor: NSColor? = nil) {
		viewEntries.append(ViewEntry(view: view, color: color, descendantColor: descendantColor))
		applyVisibility()
	}

	/// Outline a layout guide. A guide owns no view, so a layer stands in for it behind the content
	public func add(guide: NSLayoutGuide, color: NSColor) {
		addBox(style: .outline, resolver: frameResolver(for: guide), color: color)
	}

	/// Tint the area a view occupies. The fill goes behind the content, so the view keeps its own background
	public func addFill(view: NSView, color: NSColor) {
		addBox(style: .fill, resolver: frameResolver(for: view), color: color)
	}

	/// Tint the area a layout guide occupies
	public func addFill(guide: NSLayoutGuide, color: NSColor) {
		addBox(style: .fill, resolver: frameResolver(for: guide), color: color)
	}

	/// Hatch the area a view occupies with 45-degree lines. Tells a wide area apart from the flat fills inside it
	public func addHatch(view: NSView, color: NSColor) {
		addBox(style: .hatch, resolver: frameResolver(for: view), color: color)
	}

	/// Draw a rule across the host at the given edge of a layout guide
	public func addRule(at edge: LayoutDebugWireframeEdge, of guide: NSLayoutGuide, color: NSColor) {
		addRule(at: edge, resolver: frameResolver(for: guide), color: color)
	}

	/// Draw a rule across the host at the given edge of a view
	public func addRule(at edge: LayoutDebugWireframeEdge, of view: NSView, color: NSColor) {
		addRule(at: edge, resolver: frameResolver(for: view), color: color)
	}

	/// Print the measured width of a layout guide just above the guide rect.
	/// Only the horizontal cases of `alignedTo` are read, since the readout always sits on top
	public func addWidthReadout(of guide: NSLayoutGuide,
								alignedTo edge: LayoutDebugWireframeEdge,
								color: NSColor)
	{
		addWidthReadout(resolver: frameResolver(for: guide), alignedTo: edge, color: color)
	}

	/// Print the measured width of a view just above it
	public func addWidthReadout(of view: NSView,
								alignedTo edge: LayoutDebugWireframeEdge,
								color: NSColor)
	{
		addWidthReadout(resolver: frameResolver(for: view), alignedTo: edge, color: color)
	}

	/// Draw the wireframes again. Call after views were put inside an already registered view
	public func refresh() {
		applyVisibility()
	}

	/// Drop every registration and clear the wireframes already drawn
	public func removeAll() {
		isEnabled = false

		(boxEntries + ruleEntries).forEach { $0.layer.removeFromSuperlayer() }
		readoutEntries.forEach { $0.layer.removeFromSuperlayer() }
		boxEntries.removeAll()
		ruleEntries.removeAll()
		readoutEntries.removeAll()
		viewEntries.removeAll()
	}


	// MARK: - Layout

	/// Write the current frames into the layers. Call this from the host’s `layout()`
	public func updateLayout() {
		guard !boxEntries.isEmpty || !ruleEntries.isEmpty || !readoutEntries.isEmpty else { return }

		let scale = host.window?.backingScaleFactor ?? 1.0

		CATransaction.begin()
		CATransaction.setDisableActions(true)

		// The containers share the host coordinates, so their children can be placed in host terms
		[backdropLayer, overlayLayer].forEach { $0.frame = host.bounds }

		boxEntries.forEach { entry in
			guard let rect = entry.frameInHost() else { return }

			entry.layer.frame = rect
			entry.layer.contentsScale = scale

			// A hatch is a path rather than a color, so it has to be redrawn whenever the box resizes
			if let shapeLayer = entry.layer as? CAShapeLayer {
				shapeLayer.path = Self.hatchPath(in: rect.size)
			}
		}

		ruleEntries.forEach { entry in
			guard let rect = entry.frameInHost(), let edge = entry.edge else { return }

			entry.layer.frame = ruleFrame(at: edge, of: rect)
			entry.layer.contentsScale = scale
		}

		readoutEntries.forEach { entry in
			guard let rect = entry.frameInHost() else { return }

			// Auto Layout hands out fractions, so a decimal is kept to expose a hair of misalignment
			entry.layer.string = String(format: "%.1f", rect.width)
			entry.layer.contentsScale = scale

			let size = entry.layer.preferredFrameSize()
			entry.layer.frame = CGRect(x: readoutOriginX(for: entry.alignment, of: rect, width: size.width),
									   y: rect.maxY + Self.readoutSpacing,
									   width: size.width,
									   height: size.height)
		}

		CATransaction.commit()
	}


	// MARK: - Drawing

	private func addBox(style: LayerStyle, resolver: @escaping () -> CGRect?, color: NSColor) {
		let layer = makeLayer(color: color, style: style)
		backdropLayer.addSublayer(layer)

		boxEntries.append(LayerEntry(frameInHost: resolver, layer: layer))
		applyVisibility()
	}

	private func addWidthReadout(resolver: @escaping () -> CGRect?,
								 alignedTo edge: LayoutDebugWireframeEdge,
								 color: NSColor)
	{
		let layer = makeReadoutLayer(color: color)
		overlayLayer.addSublayer(layer)

		readoutEntries.append(ReadoutEntry(frameInHost: resolver, layer: layer, alignment: edge))
		applyVisibility()
	}

	private func addRule(at edge: LayoutDebugWireframeEdge,
						 resolver: @escaping () -> CGRect?,
						 color: NSColor)
	{
		let layer = makeLayer(color: color, style: .rule)
		overlayLayer.addSublayer(layer)

		ruleEntries.append(LayerEntry(frameInHost: resolver, layer: layer, edge: edge))
		applyVisibility()
	}

	/// zPosition decides the depth, so a subview added later cannot slip in front of a rule
	private func makeContainerLayer(zPosition: CGFloat) -> CALayer {
		host.wantsLayer = true

		let layer = CALayer()
		layer.zPosition = zPosition
		host.layer?.addSublayer(layer)

		return layer
	}

	/// Follow the side the measured column is aligned to, so the number sits over the content it describes
	private func readoutOriginX(for alignment: LayoutDebugWireframeEdge, of rect: CGRect, width: CGFloat) -> CGFloat {
		switch alignment {
			case .maxX:
				return rect.maxX - width

			case .centerX:
				return rect.midX - width / 2

			default:
				return rect.minX
		}
	}

	private func makeReadoutLayer(color: NSColor) -> CATextLayer {
		host.wantsLayer = true

		let fontSize = NSFont.smallSystemFontSize
		let layer = CATextLayer()
		layer.isHidden = true
		layer.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .semibold)
		layer.fontSize = fontSize
		layer.foregroundColor = color.withAlphaComponent(Self.textAlpha).cgColor

		return layer
	}

	private func makeLayer(color: NSColor, style: LayerStyle) -> CALayer {
		host.wantsLayer = true

		let layer: CALayer

		switch style {
			case .outline:
				let borderedLayer = CALayer()
				borderedLayer.borderWidth = Self.lineWidth
				borderedLayer.borderColor = Self.tinted(color).cgColor
				layer = borderedLayer

			case .rule:
				let filledLayer = CALayer()
				filledLayer.backgroundColor = Self.tinted(color).cgColor
				layer = filledLayer

			case .fill:
				let filledLayer = CALayer()
				filledLayer.backgroundColor = color.withAlphaComponent(Self.fillAlpha).cgColor
				layer = filledLayer

			case .hatch:
				// The path starts outside the box, so the ends have to be clipped away
				let shapeLayer = CAShapeLayer()
				shapeLayer.strokeColor = color.withAlphaComponent(Self.hatchAlpha).cgColor
				shapeLayer.fillColor = nil
				shapeLayer.lineWidth = Self.lineWidth
				shapeLayer.masksToBounds = true
				layer = shapeLayer
		}

		layer.isHidden = true

		return layer
	}

	/// Lines at 45 degrees, laid from the left edge until the whole box is covered
	private static func hatchPath(in size: CGSize) -> CGPath {
		let path = CGMutablePath()
		var x = -size.height

		while x < size.width {
			path.move(to: CGPoint(x: x, y: 0))
			path.addLine(to: CGPoint(x: x + size.height, y: size.height))
			x += hatchSpacing
		}

		return path
	}

	/// Span the host along one axis and sit on the given edge of the target on the other
	private func ruleFrame(at edge: LayoutDebugWireframeEdge, of rect: CGRect) -> CGRect {
		// A layer is not clipped to the host, so the overhang simply widens the span
		let bounds = host.bounds.insetBy(dx: -ruleOverhang, dy: -ruleOverhang)
		let thickness = Self.lineWidth

		switch edge {
			case .minX:
				return CGRect(x: rect.minX, y: bounds.minY, width: thickness, height: bounds.height)

			case .maxX:
				return CGRect(x: rect.maxX - thickness, y: bounds.minY, width: thickness, height: bounds.height)

			case .centerX:
				return CGRect(x: rect.midX - thickness / 2, y: bounds.minY, width: thickness, height: bounds.height)

			case .minY:
				return CGRect(x: bounds.minX, y: rect.minY, width: bounds.width, height: thickness)

			case .maxY:
				return CGRect(x: bounds.minX, y: rect.maxY - thickness, width: bounds.width, height: thickness)

			case .centerY:
				return CGRect(x: bounds.minX, y: rect.midY - thickness / 2, width: bounds.width, height: thickness)
		}
	}

	private func applyVisibility() {
		viewEntries.forEach { entry in
			guard let view = entry.view else { return }

			setBorder(to: view, color: entry.color)

			// Walked on every pass, so views added after the registration are outlined as well
			if let descendantColor = entry.descendantColor {
				view.subviews.forEach { setBorderRecursively(to: $0, color: descendantColor) }
			}
		}

		(boxEntries + ruleEntries).forEach { $0.layer.isHidden = !isVisible }
		readoutEntries.forEach { $0.layer.isHidden = !isVisible }
		updateLayout()
	}

	private func setBorderRecursively(to view: NSView, color: NSColor) {
		setBorder(to: view, color: color)
		view.subviews.forEach { setBorderRecursively(to: $0, color: color) }
	}

	private func setBorder(to view: NSView, color: NSColor) {
		view.wantsLayer = true
		view.layer?.borderWidth = isVisible ? Self.lineWidth : 0
		view.layer?.borderColor = isVisible ? Self.tinted(color).cgColor : nil
	}

	private static func tinted(_ color: NSColor) -> NSColor {
		color.withAlphaComponent(colorAlpha)
	}


	// MARK: - Resolving frames

	/// `self` is captured weakly, or the host that owns this object would never be released
	private func frameResolver(for guide: NSLayoutGuide) -> () -> CGRect? {
		{ [weak self] in
			guard let self, let owningView = guide.owningView else { return nil }

			return owningView === self.host ? guide.frame : self.host.convert(guide.frame, from: owningView)
		}
	}

	private func frameResolver(for view: NSView) -> () -> CGRect? {
		{ [weak self, weak view] in
			guard let self, let view else { return nil }

			return view === self.host ? self.host.bounds : self.host.convert(view.bounds, from: view)
		}
	}


	// MARK: - Entries

	/// A view is held weakly, or a host that registers itself would never be released
	private struct ViewEntry {

		weak var view: NSView?
		let color: NSColor
		let descendantColor: NSColor?

	}

	/// How a layer marks its target
	private enum LayerStyle {

		/// Border along the target rect
		case outline
		/// Line spanning the host at one edge of the target
		case rule
		/// Tint over the whole target rect
		case fill
		/// Diagonal lines over the whole target rect
		case hatch

	}

	/// A box or a rule drawn by a layer of its own. `edge` is set only for a rule
	private struct LayerEntry {

		let frameInHost: () -> CGRect?
		let layer: CALayer
		var edge: LayoutDebugWireframeEdge?

	}

	/// A measurement printed over the layout. Its text is rewritten on every layout pass
	private struct ReadoutEntry {

		let frameInHost: () -> CGRect?
		let layer: CATextLayer
		let alignment: LayoutDebugWireframeEdge

	}

}
