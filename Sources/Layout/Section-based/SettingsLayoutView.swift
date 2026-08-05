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

	/// Width a section declares for the item column. Not required, so that wider items can still push the column open
	public static let itemColumnDeclaredWidth = NSLayoutConstraint.Priority(rawValue: 999)
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

/// A container that builds a settings pane out of sections. Column widths come from the content and this view owns the section spacing
open class SettingsLayoutView: NSView {

	/// Guide that aggregates the label column width. It carries no position, only a shared width
	public private(set) var labelColumnWidthGuide = NSLayoutGuide()
	/// Guide that aggregates the item column width. It carries no position, only a shared width
	public private(set) var itemColumnWidthGuide = NSLayoutGuide()
	/// Guide that aggregates the width of both columns plus the spacing. Every section matches it, so their edges line up
	public private(set) var contentBlockWidthGuide = NSLayoutGuide()

	/// Outline of this container. Each section owns the outlines of its own boxes
	public lazy var debugWireframes = LayoutDebugWireframes(host: self)

	/// Lower bound of the label column width. nil leaves the width to the labels themselves
	open var labelColumnMinimumWidth: CGFloat? {
		didSet {
			updateMinimumWidthConstraint(labelColumnMinimumWidthConstraint, to: labelColumnMinimumWidth)
		}
	}

	/// Lower bound of the item column width. nil leaves the width to the sections and their items
	open var itemColumnMinimumWidth: CGFloat? {
		didSet {
			updateMinimumWidthConstraint(itemColumnMinimumWidthConstraint, to: itemColumnMinimumWidth)
		}
	}

	private let stackView = NSStackView()
	/// Stands in for the item column next to the label column, so the block width can be read off its trailing edge
	private let itemColumnMeasuringGuide = NSLayoutGuide()
	/// Content block where it really appears. The width guides carry no position, so the debug rules read these instead
	private let blockPositionGuide = NSLayoutGuide()
	private let labelColumnPositionGuide = NSLayoutGuide()
	private let itemColumnPositionGuide = NSLayoutGuide()
	private var labelColumnMinimumWidthConstraint: NSLayoutConstraint?
	private var itemColumnMinimumWidthConstraint: NSLayoutConstraint?
	/// Holds the narrowest width the sections declared. Inactive while no section declares one
	private var itemColumnDeclaredWidthConstraint: NSLayoutConstraint?
	private var itemColumnShrinkConstraint: NSLayoutConstraint?


	// MARK: - Initialization

	public init() {
		super.init(frame: .zero)
		setUpGuides()
		setUpStackView()

		setUpDebugRules()
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

		// A declaration only caps the column, so the same value comes back as a lower bound and the column stops hugging narrower
		itemColumnDeclaredWidthConstraint = itemColumnWidthGuide.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)
		itemColumnDeclaredWidthConstraint?.priority = SettingsLayoutPriority.itemColumnDeclaredWidth

		// Both lower bounds stay inactive until a width is given, so an unset column keeps following its content
		labelColumnMinimumWidthConstraint = labelColumnWidthGuide.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)
		itemColumnMinimumWidthConstraint = itemColumnWidthGuide.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)

		setUpContentBlockWidthGuide()
	}

	private func updateMinimumWidthConstraint(_ constraint: NSLayoutConstraint?, to width: CGFloat?) {
		guard let width else {
			constraint?.isActive = false
			return
		}

		constraint?.constant = width
		constraint?.isActive = true
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

		setUpPositionGuides()
	}

	/// The width guides sit at the origin, so they say nothing about where the columns appear.
	/// These guides stand where the content really is, which is what the debug rules need
	private func setUpPositionGuides() {
		[blockPositionGuide, labelColumnPositionGuide, itemColumnPositionGuide].forEach { addLayoutGuide($0) }

		NSLayoutConstraint.activate([
			// Sections center their content box, so the block position follows the center as well
			blockPositionGuide.topAnchor.constraint(equalTo: topAnchor),
			blockPositionGuide.heightAnchor.constraint(equalToConstant: 0),
			blockPositionGuide.centerXAnchor.constraint(equalTo: centerXAnchor),
			blockPositionGuide.widthAnchor.constraint(equalTo: contentBlockWidthGuide.widthAnchor),

			labelColumnPositionGuide.topAnchor.constraint(equalTo: topAnchor),
			labelColumnPositionGuide.heightAnchor.constraint(equalToConstant: 0),
			labelColumnPositionGuide.leadingAnchor.constraint(equalTo: blockPositionGuide.leadingAnchor),
			labelColumnPositionGuide.widthAnchor.constraint(equalTo: labelColumnWidthGuide.widthAnchor),

			itemColumnPositionGuide.topAnchor.constraint(equalTo: topAnchor),
			itemColumnPositionGuide.heightAnchor.constraint(equalToConstant: 0),
			itemColumnPositionGuide.leadingAnchor.constraint(equalTo: labelColumnPositionGuide.trailingAnchor,
															constant: SettingsLayoutMetrics.columnSpacing),
			itemColumnPositionGuide.widthAnchor.constraint(equalTo: itemColumnWidthGuide.widthAnchor),
		])
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
		section.layoutView = self
		appendSection(section)
		section.activateColumnWidthConstraints()
		itemColumnShrinkConstraint?.isActive = true
		invalidateItemColumnDeclaredWidth()
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
		section.debug_setWireframes(debugWireframes.isEnabled)
	}


	// MARK: - Item column width

	/// Take in the widths the sections declared. Only the narrowest one satisfies every declaration at once, so that becomes the column width
	func invalidateItemColumnDeclaredWidth() {
		guard let narrowestDeclaredWidth = columnSections.compactMap({ $0.itemColumnMaximumWidth }).min()
		else {
			itemColumnDeclaredWidthConstraint?.isActive = false
			return
		}

		itemColumnDeclaredWidthConstraint?.constant = narrowestDeclaredWidth
		itemColumnDeclaredWidthConstraint?.isActive = true
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

	private func setUpDebugRules() {
		debugWireframes.add(view: self, color: LayoutDebugWireframeColor.container)

		// Rules run the height of the pane, so a section whose edge is off shows up at a glance
		debugWireframes.addRule(at: .minX, of: self, color: LayoutDebugWireframeColor.container)
		debugWireframes.addRule(at: .maxX, of: self, color: LayoutDebugWireframeColor.container)
		debugWireframes.addRule(at: .centerX, of: self, color: LayoutDebugWireframeColor.container)
		debugWireframes.addRule(at: .minX, of: blockPositionGuide, color: LayoutDebugWireframeColor.section)
		debugWireframes.addRule(at: .maxX, of: blockPositionGuide, color: LayoutDebugWireframeColor.section)
		debugWireframes.addRule(at: .maxX, of: labelColumnPositionGuide, color: LayoutDebugWireframeColor.labelColumn)
		debugWireframes.addRule(at: .minX, of: itemColumnPositionGuide, color: LayoutDebugWireframeColor.itemColumn)

		// Each readout takes the side its column is aligned to, so it reads against the content below it
		debugWireframes.addWidthReadout(of: labelColumnPositionGuide,
										alignedTo: .maxX,
										color: LayoutDebugWireframeColor.labelColumn)
		debugWireframes.addWidthReadout(of: itemColumnPositionGuide,
										alignedTo: .minX,
										color: LayoutDebugWireframeColor.itemColumn)
		debugWireframes.addWidthReadout(of: blockPositionGuide,
										alignedTo: .maxX,
										color: LayoutDebugWireframeColor.section)
		// Kept on the left, or it would land on the block width that shares the same right edge
		debugWireframes.addWidthReadout(of: self,
										alignedTo: .minX,
										color: LayoutDebugWireframeColor.container)
	}

	/// Visualize the boxes of every level as wireframes. Calling it before adding sections still affects sections added later
	open func debug_setWireframes(_ flag: Bool) {
		debugWireframes.isEnabled = flag
		sections.forEach { $0.debug_setWireframes(debugWireframes.isEnabled) }
	}

	open override func layout() {
		super.layout()

		// The rules are meant to reach the pane edges, so the margin this view sits in is handed back to them
		debugWireframes.ruleOverhang = marginToParentView()
		debugWireframes.updateLayout()
	}

	// Moving between displays changes the scale without moving the layout, so the layers are refreshed here as well
	open override func viewDidChangeBackingProperties() {
		super.viewDidChangeBackingProperties()
		debugWireframes.updateLayout()
	}

	/// Widest margin between this view and the view it was laid into.
	/// System spacing settles during layout, so it is measured from the frames rather than read off the constraints
	private func marginToParentView() -> CGFloat {
		guard let superview else { return 0 }

		let margins = [frame.minX - superview.bounds.minX,
					   superview.bounds.maxX - frame.maxX,
					   frame.minY - superview.bounds.minY,
					   superview.bounds.maxY - frame.maxY]

		return max(margins.max() ?? 0, 0)
	}

}
