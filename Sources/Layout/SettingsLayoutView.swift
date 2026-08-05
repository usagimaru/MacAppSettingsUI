//
//  SettingsLayoutView.swift
//
//  Created by usagimaru on 2026/08/04.
//

import Cocoa

/// Layout metrics of a settings pane
public enum SettingsLayoutMetrics {

	/// Spacing between sections
	public static let sectionSpacing: CGFloat = 20
	/// Spacing between the label column and the item column
	public static let columnSpacing: CGFloat = 8
	/// Spacing between items within a section
	public static let itemSpacing: CGFloat = 6

}

/// Margins between a settings pane and the layout view laid into it
public enum SettingsLayoutMargins {

	/// System standard spacing on all four edges
	case systemSpacing
	/// Fixed insets. The leading and trailing sides follow the writing direction
	case insets(NSDirectionalEdgeInsets)

}

/// Ladder of layout priorities of a settings pane
public enum SettingsLayoutPriority {

	/// Upper bound of the item column width. Not required, so that the minimum width wins on conflict
	public static let itemColumnMaximumWidth = NSLayoutConstraint.Priority(rawValue: 999)
	/// Upper bound of the label column width. Beats the compression resistance of ordinary controls
	public static let labelColumnMaximumWidth = NSLayoutConstraint.Priority(rawValue: 751)
	/// Width a description label asks of the item column. Loses to the upper bound, beats the shrink
	public static let descriptionWidthDemand = NSLayoutConstraint.Priority(rawValue: 500)
	/// Force that hugs the item column to what its items need
	public static let itemColumnWidthShrink = NSLayoutConstraint.Priority(rawValue: 300)
	/// Force that hugs the label column to its longest label
	public static let labelColumnWidthShrink = NSLayoutConstraint.Priority(rawValue: 250)
	/// Force that fills the container. Weakest of the three, so it only takes effect while no column shrinks it
	public static let contentWidthGrow = NSLayoutConstraint.Priority(rawValue: 200)
	/// Horizontal priority of controls that take no part in deciding a column width
	public static let nonContributing = NSLayoutConstraint.Priority(rawValue: 50)

}

/// Wireframe drawing for debugging. Colors differ per level so the levels stay distinguishable
public enum SettingsDebugWireframe {

	/// Whole container
	public static let containerColor = NSColor.systemBlue
	/// Section
	public static let sectionColor = NSColor.systemOrange
	/// Label column box
	public static let labelColumnColor = NSColor.systemRed
	/// Item column box
	public static let itemColumnColor = NSColor.systemGreen
	/// Labels and controls
	public static let controlColor = NSColor.systemPurple

	public static func tinted(_ color: NSColor) -> NSColor {
		color.withAlphaComponent(0.5)
	}

	/// Outline a view together with its descendants
	public static func apply(_ flag: Bool, to view: NSView, color: NSColor) {
		setBorder(flag, to: view, color: color)
		view.subviews.forEach { apply(flag, to: $0, color: color) }
	}

	/// Outline a section itself and the controls inside it in separate colors
	public static func applyToSection(_ flag: Bool, section: NSView) {
		setBorder(flag, to: section, color: sectionColor)
		section.subviews.forEach { apply(flag, to: $0, color: controlColor) }
	}

	private static func setBorder(_ flag: Bool, to view: NSView, color: NSColor) {
		view.wantsLayer = true
		view.layer?.borderWidth = flag ? 1 : 0
		view.layer?.borderColor = flag ? tinted(color).cgColor : nil
	}

}

/// A container that builds a settings pane out of sections. Column widths come from the content and this view owns the section spacing
open class SettingsLayoutView: NSView {

	/// Guide that aggregates the label column width. It carries no position, only a shared width
	public private(set) var labelColumnWidthGuide = NSLayoutGuide()
	/// Guide that aggregates the item column width. It carries no position, only a shared width
	public private(set) var itemColumnWidthGuide = NSLayoutGuide()
	/// Guide that aggregates the width of both columns plus the spacing. Every section matches it, so their edges line up
	public private(set) var contentBlockWidthGuide = NSLayoutGuide()

	/// Lower bound of the item column width. The pane never goes below it, so this effectively decides the minimum pane width
	open var itemColumnMinimumWidth: CGFloat = 200 {
		didSet {
			itemColumnMinimumWidthConstraint?.constant = itemColumnMinimumWidth
		}
	}

	private let stackView = NSStackView()
	/// Stands in for the item column at its real position, so the block width can be read off its trailing edge
	private let itemColumnMeasuringGuide = NSLayoutGuide()
	private var itemColumnMinimumWidthConstraint: NSLayoutConstraint?
	private var itemColumnShrinkConstraint: NSLayoutConstraint?
	private var debugWireframeLayer = CALayer()
	private var isDebugWireframesEnabled = false


	// MARK: - Initialization

	public init() {
		super.init(frame: .zero)
		setUpGuides()
		setUpStackView()
		setUpDebugLayer()
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	/// Lay this view into a pane view. Leaving `margins` out gives the system standard spacing on all four edges
	open func install(in parentView: NSView, margins: SettingsLayoutMargins = .systemSpacing) {
		translatesAutoresizingMaskIntoConstraints = false
		parentView.addSubview(self, positioned: .below, relativeTo: nil)

		switch margins {
			case .systemSpacing:
				NSLayoutConstraint.activate([
					topAnchor.constraint(equalToSystemSpacingBelow: parentView.topAnchor, multiplier: 1),
					leadingAnchor.constraint(equalToSystemSpacingAfter: parentView.leadingAnchor, multiplier: 1),
					parentView.trailingAnchor.constraint(equalToSystemSpacingAfter: trailingAnchor, multiplier: 1),
					parentView.bottomAnchor.constraint(equalToSystemSpacingBelow: bottomAnchor, multiplier: 1),
				])

			case .insets(let insets):
				NSLayoutConstraint.activate([
					topAnchor.constraint(equalTo: parentView.topAnchor, constant: insets.top),
					leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: insets.leading),
					parentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: insets.trailing),
					parentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: insets.bottom),
				])
		}
	}

	private func setUpGuides() {
		[labelColumnWidthGuide, itemColumnWidthGuide].forEach { guide in
			addLayoutGuide(guide)

			// Only the width matters, but an undefined position counts as ambiguous, so pin the guide to the origin
			NSLayoutConstraint.activate([
				guide.leadingAnchor.constraint(equalTo: leadingAnchor),
				guide.topAnchor.constraint(equalTo: topAnchor),
				guide.heightAnchor.constraint(equalToConstant: 0),
			])
		}

		let labelColumnShrink = labelColumnWidthGuide.widthAnchor.constraint(equalToConstant: 0)
		labelColumnShrink.priority = SettingsLayoutPriority.labelColumnWidthShrink
		labelColumnShrink.isActive = true

		// Held back until a column section exists, or a pane of full-width sections alone would collapse to the minimum
		itemColumnShrinkConstraint = itemColumnWidthGuide.widthAnchor.constraint(equalToConstant: 0)
		itemColumnShrinkConstraint?.priority = SettingsLayoutPriority.itemColumnWidthShrink

		labelColumnWidthGuide.identifier = .init("SettingsLayoutView.LabelColumnWidthGuide")
		itemColumnWidthGuide.identifier = .init("SettingsLayoutView.ItemColumnWidthGuide")

		// Keep the label column from crushing the item column in languages with long wordings
		let labelColumnMaximumWidth = labelColumnWidthGuide.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor,
																				  multiplier: 0.4)
		labelColumnMaximumWidth.priority = SettingsLayoutPriority.labelColumnMaximumWidth

		itemColumnMinimumWidthConstraint = itemColumnWidthGuide.widthAnchor
			.constraint(greaterThanOrEqualToConstant: itemColumnMinimumWidth)

		NSLayoutConstraint.activate([labelColumnMaximumWidth, itemColumnMinimumWidthConstraint!])

		setUpContentBlockWidthGuide()
	}

	private func setUpContentBlockWidthGuide() {
		[itemColumnMeasuringGuide, contentBlockWidthGuide].forEach { addLayoutGuide($0) }

		// Anchors cannot be summed, so lay a stand-in guide after the label column and read the total off its trailing edge
		NSLayoutConstraint.activate([
			itemColumnMeasuringGuide.topAnchor.constraint(equalTo: topAnchor),
			itemColumnMeasuringGuide.heightAnchor.constraint(equalToConstant: 0),
			itemColumnMeasuringGuide.leadingAnchor.constraint(equalTo: labelColumnWidthGuide.trailingAnchor,
															  constant: SettingsLayoutMetrics.columnSpacing),
			itemColumnMeasuringGuide.widthAnchor.constraint(equalTo: itemColumnWidthGuide.widthAnchor),

			contentBlockWidthGuide.topAnchor.constraint(equalTo: topAnchor),
			contentBlockWidthGuide.heightAnchor.constraint(equalToConstant: 0),
			contentBlockWidthGuide.leadingAnchor.constraint(equalTo: labelColumnWidthGuide.leadingAnchor),
			contentBlockWidthGuide.trailingAnchor.constraint(equalTo: itemColumnMeasuringGuide.trailingAnchor),
		])

		// The single force that fills the container. Keeping it here stops separators and other sections from voting on the width
		let blockGrow = contentBlockWidthGuide.trailingAnchor.constraint(equalTo: trailingAnchor)
		blockGrow.priority = SettingsLayoutPriority.contentWidthGrow
		blockGrow.isActive = true
	}

	private func setUpStackView() {
		stackView.orientation = .vertical
		stackView.spacing = SettingsLayoutMetrics.sectionSpacing
		stackView.alignment = .width
		stackView.distribution = .fill
		stackView.detachesHiddenViews = true
		stackView.setHuggingPriority(.defaultLow, for: .horizontal)
		// Tying the bottom with an equality spreads the slack into the sections and stretches the controls vertically
		stackView.setHuggingPriority(.required, for: .vertical)

		stackView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(stackView)

		NSLayoutConstraint.activate([
			stackView.topAnchor.constraint(equalTo: topAnchor),
			stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
			stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
		])
	}


	// MARK: - Adding sections

	/// Add a two-column label–item section. `itemColumnMaximumWidth` applies to the item column of every section
	@discardableResult
	public func addColumnSection(label: String,
								 itemColumnMaximumWidth: CGFloat? = nil,
								 identifier: NSUserInterfaceItemIdentifier? = nil) -> SettingsColumnSectionView
	{
		let section = SettingsColumnSectionView(labelTitle: label,
												labelColumnWidthGuide: labelColumnWidthGuide,
												itemColumnWidthGuide: itemColumnWidthGuide,
												itemColumnMaximumWidth: itemColumnMaximumWidth,
												identifier: identifier)
		appendSection(section)
		section.activateColumnWidthConstraints()
		itemColumnShrinkConstraint?.isActive = true
		return section
	}

	/// Add a separator section. A separator divides the whole pane, so it always spans the container width
	@discardableResult
	public func addSeparatorSection(identifier: NSUserInterfaceItemIdentifier? = nil) -> SettingsSeparatorSectionView {
		let section = SettingsSeparatorSectionView(identifier: identifier)
		appendSection(section, widthMode: .fullWidth)
		return section
	}

	/// Add a section that places a single button. `widthMode` decides the area the button is aligned in
	@discardableResult
	public func addButtonSection(title: String,
								 controlSize: NSControl.ControlSize = .regular,
								 alignment: SettingsSectionAlignment = .center,
								 widthMode: SettingsSectionWidthMode = .fullWidth,
								 identifier: NSUserInterfaceItemIdentifier? = nil,
								 target: AnyObject?,
								 action: Selector?) -> SettingsButtonSectionView
	{
		let section = SettingsButtonSectionView(title: title,
												controlSize: controlSize,
												alignment: alignment,
												identifier: identifier,
												target: target,
												action: action)
		appendSection(section, widthMode: widthMode)
		return section
	}

	/// Add a section that places a leading-aligned checkbox. `widthMode` decides the area it is laid out in
	@discardableResult
	public func addCheckboxSection(title: String,
								   isOn: Bool = false,
								   description: String? = nil,
								   widthMode: SettingsSectionWidthMode = .fullWidth,
								   identifier: NSUserInterfaceItemIdentifier? = nil,
								   target: AnyObject?,
								   action: Selector?) -> SettingsCheckboxSectionView
	{
		let section = SettingsCheckboxSectionView(title: title,
												  isOn: isOn,
												  description: description,
												  identifier: identifier,
												  target: target,
												  action: action)
		appendSection(section, widthMode: widthMode)
		return section
	}

	/// Add an arbitrary view as a section. `widthMode` decides the area the view is fitted to
	@discardableResult
	public func addCustomSection(_ view: NSView,
								 widthMode: SettingsSectionWidthMode = .fullWidth,
								 identifier: NSUserInterfaceItemIdentifier? = nil) -> SettingsCustomSectionView
	{
		let section = SettingsCustomSectionView(contentView: view, identifier: identifier)
		appendSection(section, widthMode: widthMode)
		return section
	}

	private func appendSection(_ section: SettingsSectionView, widthMode: SettingsSectionWidthMode = .contentBlock) {
		stackView.addArrangedSubview(section)
		section.adoptContentWidth(from: contentBlockWidthGuide)
		section.widthMode = widthMode
		section.debug_setWireframes(isDebugWireframesEnabled)
	}


	// MARK: - Handling sections

	/// The sections already added, in order. Separators and buttons are included
	public var sections: [SettingsSectionView] {
		stackView.arrangedSubviews.compactMap { $0 as? SettingsSectionView }
	}

	/// Only the two-column sections, in order
	public var columnSections: [SettingsColumnSectionView] {
		sections.compactMap { $0 as? SettingsColumnSectionView }
	}

	/// Take out a section by its identifier
	public func section(with identifier: NSUserInterfaceItemIdentifier) -> SettingsSectionView? {
		sections.first { $0.identifier == identifier }
	}

	/// Take out a two-column section by its identifier
	public func columnSection(with identifier: NSUserInterfaceItemIdentifier) -> SettingsColumnSectionView? {
		section(with: identifier) as? SettingsColumnSectionView
	}

	/// Move a section to the given position in the order
	public func moveSection(_ identifier: NSUserInterfaceItemIdentifier, to index: Int) {
		guard let section = section(with: identifier) else { return }

		stackView.removeArrangedSubview(section)
		stackView.insertArrangedSubview(section, at: min(index, stackView.arrangedSubviews.count))
	}

	/// Swap the order of two sections
	public func swapSections(_ first: NSUserInterfaceItemIdentifier, _ second: NSUserInterfaceItemIdentifier) {
		guard let firstSection = section(with: first),
			  let secondSection = section(with: second),
			  let firstIndex = stackView.arrangedSubviews.firstIndex(of: firstSection),
			  let secondIndex = stackView.arrangedSubviews.firstIndex(of: secondSection),
			  firstIndex != secondIndex
		else { return }

		let (formerIndex, latterIndex) = firstIndex < secondIndex ? (firstIndex, secondIndex) : (secondIndex, firstIndex)
		let former = stackView.arrangedSubviews[formerIndex]
		let latter = stackView.arrangedSubviews[latterIndex]

		// Inserting the latter section first shifts the remaining sections back by one and frees its original slot
		stackView.removeArrangedSubview(latter)
		stackView.insertArrangedSubview(latter, at: formerIndex)
		stackView.removeArrangedSubview(former)
		stackView.insertArrangedSubview(former, at: latterIndex)
	}


	// MARK: - Debug

	private func setUpDebugLayer() {
		wantsLayer = true
		layer?.insertSublayer(debugWireframeLayer, at: 0)
		debugWireframeLayer.borderWidth = 1
		debugWireframeLayer.borderColor = SettingsDebugWireframe.tinted(SettingsDebugWireframe.containerColor).cgColor
		debugWireframeLayer.isHidden = true
	}

	/// Visualize the boxes of every level as wireframes. Calling it before adding sections still affects sections added later
	open func debug_setWireframes(_ flag: Bool) {
#if DEBUG
		isDebugWireframesEnabled = flag
#else
		isDebugWireframesEnabled = false
#endif
		debugWireframeLayer.isHidden = !isDebugWireframesEnabled
		sections.forEach { $0.debug_setWireframes(isDebugWireframesEnabled) }
	}

	open override func layout() {
		super.layout()

		CATransaction.begin()
		CATransaction.setDisableActions(true)
		debugWireframeLayer.frame = bounds
		debugWireframeLayer.contentsScale = window?.backingScaleFactor ?? 1.0
		CATransaction.commit()
	}

}
