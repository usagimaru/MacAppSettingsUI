//
//  SettingsSectionView.swift
//
//  Created by usagimaru on 2026/08/04.
//

import Cocoa

/// Width a section content spans
public enum SettingsSectionWidthMode {

	/// Line up with the two-column block, so the section edges match the column sections
	case contentBlock
	/// Span the whole container width, regardless of how wide the columns are
	case fullWidth

}

/// Height a section takes
public enum SettingsSectionHeightMode {

	/// Follow the height of the content
	case fitsContent
	/// Take in the surplus height of the pane, never falling below the minimum height
	case flexible(minimumHeight: CGFloat, preferredHeight: CGFloat)

}

/// A unit of view stacked in a SettingsLayoutView
open class SettingsSectionView: NSView {

	/// Box holding the section content. Its width follows the width mode and it stays centered
	public let contentGuide = NSLayoutGuide()

	/// Which width the content box follows. Switching it swaps the active width constraint
	open var widthMode: SettingsSectionWidthMode = .contentBlock {
		didSet {
			updateContentWidthConstraint()
		}
	}

	/// Whether the section takes in surplus height. Switching it swaps the active height constraints
	open var heightMode: SettingsSectionHeightMode = .fitsContent {
		didSet {
			updateHeightConstraints()
			layoutView?.invalidateFlexibleSections()
		}
	}

	/// Outlines of this section and everything inside it. Subclasses add their own boxes to it
	public lazy var debugWireframes = LayoutDebugWireframes(host: self)

	/// The container this section was added to
	weak var layoutView: SettingsLayoutView?

	/// Width of the section itself, which the container has already stretched to its full width
	private var fullWidthConstraint: NSLayoutConstraint?
	/// Width shared with the two-column block. Absent while the section stands outside a container
	private var contentBlockWidthConstraint: NSLayoutConstraint?
	/// Lower bound the section keeps while it takes in surplus height
	private var minimumHeightConstraint: NSLayoutConstraint?
	/// Height the section asks for. It gives way once the pane is dragged shorter
	private var preferredHeightConstraint: NSLayoutConstraint?

	public init(identifier: NSUserInterfaceItemIdentifier? = nil) {
		super.init(frame: .zero)
		self.identifier = identifier
		setUpContentGuide()

		// Hatched rather than filled, so the flat column tints inside it stay readable
		debugWireframes.addHatch(view: self, color: LayoutDebugWireframeColor.sectionFill)
		debugWireframes.add(view: self,
							color: LayoutDebugWireframeColor.section,
							descendantColor: LayoutDebugWireframeColor.control)
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setUpContentGuide() {
		addLayoutGuide(contentGuide)

		NSLayoutConstraint.activate([
			contentGuide.topAnchor.constraint(equalTo: topAnchor),
			contentGuide.bottomAnchor.constraint(equalTo: bottomAnchor),
			contentGuide.centerXAnchor.constraint(equalTo: centerXAnchor),
			contentGuide.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
			contentGuide.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
		])

		fullWidthConstraint = contentGuide.widthAnchor.constraint(equalTo: widthAnchor)
		updateContentWidthConstraint()
	}

	/// Take over the container's shared block width. Whether the section actually follows it is up to the width mode
	func adoptContentWidth(from widthGuide: NSLayoutGuide) {
		contentBlockWidthConstraint = contentGuide.widthAnchor.constraint(equalTo: widthGuide.widthAnchor)
		updateContentWidthConstraint()
	}

	private func updateContentWidthConstraint() {
		// Outside a container there is no block to follow, so the section width stays the only width available
		let followsContentBlock = (widthMode == .contentBlock && contentBlockWidthConstraint != nil)

		// Drop the old width before putting up the new one, so the two never coexist
		if followsContentBlock {
			fullWidthConstraint?.isActive = false
			contentBlockWidthConstraint?.isActive = true
		}
		else {
			contentBlockWidthConstraint?.isActive = false
			fullWidthConstraint?.isActive = true
		}
	}


	// MARK: - Height

	/// Whether this section takes in the surplus height of the pane
	var isVerticallyFlexible: Bool {
		if case .flexible = heightMode {
			return true
		}
		return false
	}

	/// Lower bound this section keeps while stretching. nil while it follows its content
	var flexibleMinimumHeight: CGFloat? {
		guard case .flexible(let minimumHeight, _) = heightMode else { return nil }
		return minimumHeight
	}

	private func updateHeightConstraints() {
		minimumHeightConstraint?.isActive = false
		preferredHeightConstraint?.isActive = false
		minimumHeightConstraint = nil
		preferredHeightConstraint = nil

		guard case .flexible(let minimumHeight, let preferredHeight) = heightMode else {
			setContentHuggingPriority(.defaultLow, for: .vertical)
			return
		}

		// The stack hands its surplus to the least hugging section
		setContentHuggingPriority(SettingsLayoutPriority.sectionHeightShrink, for: .vertical)

		let minimum = heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight)
		minimum.isActive = true
		minimumHeightConstraint = minimum

		// A lower bound, so the tallest request decides the height the pane opens at
		let preferred = heightAnchor.constraint(greaterThanOrEqualToConstant: preferredHeight)
		preferred.priority = SettingsLayoutPriority.sectionPreferredHeight
		preferred.isActive = true
		preferredHeightConstraint = preferred
	}

	/// Drop the height request while the pane measures its lower bound
	func setPreferredHeightActive(_ flag: Bool) {
		preferredHeightConstraint?.isActive = flag
	}


	// MARK: -

	/// Leading inset for an indentation level. Negative levels count as zero
	public static func indentation(forLevel level: Int, perLevel: CGFloat = SettingsLayoutMetrics.indentationPerLevel) -> CGFloat {
		CGFloat(max(level, 0)) * perLevel
	}

	/// Apply a control size together with the font size that matches it
	public static func applyControlSize(_ controlSize: NSControl.ControlSize, to control: NSControl) {
		control.controlSize = controlSize

		if controlSize == .small {
			control.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
		}
	}


	// MARK: - Debug

	/// Outline this section and the controls inside it
	open func debug_setWireframes(_ flag: Bool) {
		debugWireframes.isEnabled = flag
	}

	open override func layout() {
		super.layout()
		debugWireframes.updateLayout()
	}

	// Moving between displays changes the scale without moving the layout, so the layers are refreshed here as well
	open override func viewDidChangeBackingProperties() {
		super.viewDidChangeBackingProperties()
		debugWireframes.updateLayout()
	}

}

/// A section that fits an arbitrary view to the section content box
open class SettingsCustomSectionView: SettingsSectionView {

	public private(set) var contentView: NSView

	public init(contentView: NSView, identifier: NSUserInterfaceItemIdentifier? = nil) {
		self.contentView = contentView
		super.init(identifier: identifier)

		contentView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(contentView)

		NSLayoutConstraint.activate([
			contentView.topAnchor.constraint(equalTo: topAnchor),
			contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
			contentView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
			contentView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
		])
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
