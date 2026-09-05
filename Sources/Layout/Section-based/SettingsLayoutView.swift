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
	
	/// Leading inset one indentation level adds to an item
	public static let indentationPerLevel: CGFloat = 20

}

/// Margins between a settings pane and the layout view laid into it
public enum SettingsLayoutMargins {

	/// System standard spacing on all four edges
	case systemSpacing
	
	/// Fixed insets. The leading and trailing sides follow the writing direction
	case insets(NSDirectionalEdgeInsets)

}

/// Vertical placement of the content in a settings pane
public enum SettingsLayoutVerticalAlignment {

	/// Stack from the top edge, taking in the surplus height downward
	case top
	
	/// Center in the height available, splitting the surplus above and below
	case center

}

/// Ladder of layout priorities of a settings pane
public enum SettingsLayoutPriority {

	/// Width a section declares for the item column. Not required, so wider items can still push it open
	public static let itemColumnDeclaredWidth = NSLayoutConstraint.Priority(rawValue: 999)
	
	/// Width a description label asks of the item column. Loses to a declared width, beats the shrink
	public static let descriptionWidthDemand = NSLayoutConstraint.Priority(rawValue: 500)
	
	/// Force that hugs the item column to what its items need
	public static let itemColumnWidthShrink = NSLayoutConstraint.Priority(rawValue: 300)
	
	/// Force that hugs the label column to its longest label
	public static let labelColumnWidthShrink = NSLayoutConstraint.Priority(rawValue: 250)
	
	/// Force that fills the container. Weakest of the three, so a shrinking column always wins
	public static let contentWidthGrow = NSLayoutConstraint.Priority(rawValue: 200)
	
	/// Horizontal priority of controls that take no part in deciding a column width
	public static let nonContributing = NSLayoutConstraint.Priority(rawValue: 50)
	
	/// Bottom margin a view keeps to its container. Not required, so content too tall runs over instead of breaking
	public static let paneBottomMargin = NSLayoutConstraint.Priority(rawValue: 999)
	
	/// Top margin a centered view keeps to its container. Not required for the same reason as the bottom margin
	public static let paneTopMargin = NSLayoutConstraint.Priority(rawValue: 999)
	
	/// Force that fills the pane vertically. Not required, so a pane dragged shorter bends instead of breaking
	public static let contentHeightGrow = NSLayoutConstraint.Priority(rawValue: 999)
	
	/// Height a stretching section asks for. Beats the shrink, gives way to a shorter pane
	public static let sectionPreferredHeight = NSLayoutConstraint.Priority(rawValue: 251)
	
	/// Force that hugs a stretching section to its lower bound. Weakest of all, so the surplus lands there
	public static let sectionHeightShrink = NSLayoutConstraint.Priority(rawValue: 1)

}

extension SettingsLayoutMargins {

	/// Bottom pinning that lets taller content run over instead of breaking
	func bottomConstraints(pinning view: NSView, in parentView: NSView) -> [NSLayoutConstraint] {
		let fill: NSLayoutConstraint
		let margin: NSLayoutConstraint

		switch self {
			case .systemSpacing:
				fill = parentView.bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: view.bottomAnchor, multiplier: 1)
				margin = parentView.bottomAnchor.constraint(equalToSystemSpacingBelow: view.bottomAnchor, multiplier: 1)

			case .insets(let insets):
				fill = parentView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: insets.bottom)
				margin = parentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom)
		}

		margin.priority = SettingsLayoutPriority.paneBottomMargin

		return [fill, margin]
	}

}

/// A container that builds a settings pane out of sections, owning the column widths and the section spacing
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

	/// Vertical placement of the sections. Ignored while a section takes in the surplus height
	open var verticalAlignment: SettingsLayoutVerticalAlignment = .top {
		didSet {
			updateVerticalAlignment()
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
	
	/// Pulls the stack down to the pane bottom. Inactive while no section takes in surplus height
	private var stackFillConstraint: NSLayoutConstraint?
	
	/// Pins the stack to the top edge. Swapped for the centering constraint by the vertical alignment
	private var stackTopConstraint: NSLayoutConstraint?
	
	private var stackCenterYConstraint: NSLayoutConstraint?
	
	/// Ties the stretching sections to one another. Rebuilt whenever the set of them changes
	private var flexibleSectionLinkConstraints = [NSLayoutConstraint]()


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

	/// Lay this view into a pane view, with the system standard spacing on all four edges by default
	open func install(in parentView: NSView, margins: SettingsLayoutMargins = .systemSpacing) {
		translatesAutoresizingMaskIntoConstraints = false
		parentView.addSubview(self, positioned: .below, relativeTo: nil)

		switch margins {
			case .systemSpacing:
				NSLayoutConstraint.activate([
					topAnchor.constraint(equalToSystemSpacingBelow: parentView.topAnchor, multiplier: 1),
					leadingAnchor.constraint(equalToSystemSpacingAfter: parentView.leadingAnchor, multiplier: 1),
					parentView.trailingAnchor.constraint(equalToSystemSpacingAfter: trailingAnchor, multiplier: 1),
				])

			case .insets(let insets):
				NSLayoutConstraint.activate([
					topAnchor.constraint(equalTo: parentView.topAnchor, constant: insets.top),
					leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: insets.leading),
					parentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: insets.trailing),
				])
		}

		NSLayoutConstraint.activate(margins.bottomConstraints(pinning: self, in: parentView))
	}

	private func setUpGuides() {
		[labelColumnWidthGuide, itemColumnWidthGuide].forEach { guide in
			addLayoutGuide(guide)

			// Only the width matters, but an undefined position counts as ambiguous
			NSLayoutConstraint.activate([
				guide.leadingAnchor.constraint(equalTo: leadingAnchor),
				guide.topAnchor.constraint(equalTo: topAnchor),
				guide.heightAnchor.constraint(equalToConstant: 0),
			])
		}

		let labelColumnShrink = labelColumnWidthGuide.widthAnchor.constraint(equalToConstant: 0)
		labelColumnShrink.priority = SettingsLayoutPriority.labelColumnWidthShrink
		labelColumnShrink.isActive = true

		// Held back until a column section exists, or a full-width-only pane would collapse to the minimum
		itemColumnShrinkConstraint = itemColumnWidthGuide.widthAnchor.constraint(equalToConstant: 0)
		itemColumnShrinkConstraint?.priority = SettingsLayoutPriority.itemColumnWidthShrink

		labelColumnWidthGuide.identifier = .init("SettingsLayoutView.LabelColumnWidthGuide")
		itemColumnWidthGuide.identifier = .init("SettingsLayoutView.ItemColumnWidthGuide")

		// A declaration only caps the column, so the same value comes back as a lower bound
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

		// Anchors cannot be summed, so the total is read off the trailing edge of a stand-in guide
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

		// The single force that fills the container, so no section votes on the width on its own
		let blockGrow = contentBlockWidthGuide.trailingAnchor.constraint(equalTo: trailingAnchor)
		blockGrow.priority = SettingsLayoutPriority.contentWidthGrow
		blockGrow.isActive = true

		setUpPositionGuides()
	}

	/// The width guides sit at the origin, so these stand where the content really is, for the debug rules
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
		// Otherwise the slack would spread into the sections and stretch the controls vertically
		stackView.setHuggingPriority(.required, for: .vertical)

		stackView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(stackView)

		NSLayoutConstraint.activate([
			stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
			stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
		])

		stackTopConstraint = stackView.topAnchor.constraint(equalTo: topAnchor)
		stackTopConstraint?.isActive = true

		// Held back until the alignment centers the stack
		stackCenterYConstraint = stackView.centerYAnchor.constraint(equalTo: centerYAnchor)

		// Held back until a section asks for the surplus
		stackFillConstraint = stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
		stackFillConstraint?.priority = SettingsLayoutPriority.contentHeightGrow
	}

	/// A section taking in the surplus height leaves nothing to center, so the centering steps aside
	private func updateVerticalAlignment() {
		let centersStack = verticalAlignment == .center && !sections.contains { $0.isVerticallyFlexible }

		// Swapped one at a time, or the stack would be over-constrained in between
		if centersStack {
			stackTopConstraint?.isActive = false
			stackCenterYConstraint?.isActive = true
		}
		else {
			stackCenterYConstraint?.isActive = false
			stackTopConstraint?.isActive = true
		}
	}


	// MARK: - Adding sections

	/// Add a two-column label–item section. `itemColumnMaximumWidth` applies to the item column of every section
	@discardableResult
	public func addColumnSection(label: String,
								 itemColumnMaximumWidth: CGFloat? = nil,
								 heightMode: SettingsSectionHeightMode = .fitsContent,
								 identifier: NSUserInterfaceItemIdentifier? = nil) -> SettingsColumnSectionView
	{
		let section = SettingsColumnSectionView(labelTitle: label,
												labelColumnWidthGuide: labelColumnWidthGuide,
												itemColumnWidthGuide: itemColumnWidthGuide,
												itemColumnMaximumWidth: itemColumnMaximumWidth,
												identifier: identifier)
		appendSection(section, heightMode: heightMode)
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
								 indentationLevel: Int = 0,
								 indentationPerLevel: CGFloat = SettingsLayoutMetrics.indentationPerLevel,
								 widthMode: SettingsSectionWidthMode = .fullWidth,
								 identifier: NSUserInterfaceItemIdentifier? = nil,
								 target: AnyObject?,
								 action: Selector?) -> SettingsButtonSectionView
	{
		let section = SettingsButtonSectionView(title: title,
												controlSize: controlSize,
												alignment: alignment,
												indentationLevel: indentationLevel,
												indentationPerLevel: indentationPerLevel,
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
								   indentationLevel: Int = 0,
								   indentationPerLevel: CGFloat = SettingsLayoutMetrics.indentationPerLevel,
								   widthMode: SettingsSectionWidthMode = .fullWidth,
								   identifier: NSUserInterfaceItemIdentifier? = nil,
								   target: AnyObject?,
								   action: Selector?) -> SettingsCheckboxSectionView
	{
		let section = SettingsCheckboxSectionView(title: title,
												  isOn: isOn,
												  description: description,
												  indentationLevel: indentationLevel,
												  indentationPerLevel: indentationPerLevel,
												  identifier: identifier,
												  target: target,
												  action: action)
		appendSection(section, widthMode: widthMode)
		return section
	}

	/// Add an arbitrary view as a section. `widthMode` decides the area the view is fitted to
	@discardableResult
	public func addCustomSection(_ view: NSView,
								 indentationLevel: Int = 0,
								 indentationPerLevel: CGFloat = SettingsLayoutMetrics.indentationPerLevel,
								 widthMode: SettingsSectionWidthMode = .fullWidth,
								 heightMode: SettingsSectionHeightMode = .fitsContent,
								 identifier: NSUserInterfaceItemIdentifier? = nil) -> SettingsCustomSectionView
	{
		let section = SettingsCustomSectionView(contentView: view,
												indentationLevel: indentationLevel,
												indentationPerLevel: indentationPerLevel,
												identifier: identifier)
		appendSection(section, widthMode: widthMode, heightMode: heightMode)
		return section
	}

	private func appendSection(_ section: SettingsSectionView,
							   widthMode: SettingsSectionWidthMode = .contentBlock,
							   heightMode: SettingsSectionHeightMode = .fitsContent)
	{
		stackView.addArrangedSubview(section)
		// Assigned before the modes, so a height change reaches this container
		section.layoutView = self
		section.adoptContentWidth(from: contentBlockWidthGuide)
		section.widthMode = widthMode
		section.heightMode = heightMode
		section.debug_setWireframes(debugWireframes.isEnabled)
	}


	// MARK: - Section height

	/// Rebuild the vertical setup after a section changed its height mode
	func invalidateFlexibleSections() {
		NSLayoutConstraint.deactivate(flexibleSectionLinkConstraints)
		flexibleSectionLinkConstraints.removeAll()

		let flexibleSections = sections.filter { $0.isVerticallyFlexible }

		// No section takes in the surplus, so the pane keeps stacking upward
		guard let firstSection = flexibleSections.first else {
			stackView.setHuggingPriority(.required, for: .vertical)
			stackFillConstraint?.isActive = false
			updateVerticalAlignment()
			return
		}

		stackView.setHuggingPriority(.defaultLow, for: .vertical)
		stackFillConstraint?.isActive = true
		updateVerticalAlignment()

		// Sharing the surplus rather than the height keeps each lower bound independent
		let firstMinimumHeight = firstSection.flexibleMinimumHeight ?? 0
		flexibleSectionLinkConstraints = flexibleSections.dropFirst().map { section in
			section.heightAnchor.constraint(equalTo: firstSection.heightAnchor,
											constant: (section.flexibleMinimumHeight ?? 0) - firstMinimumHeight)
		}
		NSLayoutConstraint.activate(flexibleSectionLinkConstraints)
	}

	/// Drop the height requests while the pane measures its lower bound
	func setPreferredSectionHeightsActive(_ flag: Bool) {
		sections.forEach { $0.setPreferredHeightActive(flag) }
	}


	// MARK: - Item column width

	/// Take in the widths the sections declared. The narrowest is the only one that satisfies them all
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

	/// The sections already added, in order, separators and buttons included
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
		invalidateFlexibleSections()
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

		// Inserting the latter one first shifts the rest back by one and frees its original slot
		stackView.removeArrangedSubview(latter)
		stackView.insertArrangedSubview(latter, at: formerIndex)
		stackView.removeArrangedSubview(former)
		stackView.insertArrangedSubview(former, at: latterIndex)
		invalidateFlexibleSections()
	}


	// MARK: - Debug

	private func setUpDebugRules() {
		debugWireframes.add(view: self, color: LayoutDebugWireframeColor.container)

		// A rule runs the height of the pane, so a section whose edge is off shows up at a glance
		debugWireframes.addRule(at: .minX, of: self, color: LayoutDebugWireframeColor.container)
		debugWireframes.addRule(at: .maxX, of: self, color: LayoutDebugWireframeColor.container)
		debugWireframes.addRule(at: .centerX, of: self, color: LayoutDebugWireframeColor.container)
		debugWireframes.addRule(at: .minX, of: blockPositionGuide, color: LayoutDebugWireframeColor.section)
		debugWireframes.addRule(at: .maxX, of: blockPositionGuide, color: LayoutDebugWireframeColor.section)
		debugWireframes.addRule(at: .maxX, of: labelColumnPositionGuide, color: LayoutDebugWireframeColor.labelColumn)
		debugWireframes.addRule(at: .minX, of: itemColumnPositionGuide, color: LayoutDebugWireframeColor.itemColumn)

		// Each readout takes the side its column is aligned to, so it reads against the content below
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

	/// Visualize the boxes of every level as wireframes. It reaches the sections added later as well
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

	/// Widest margin to the parent view. Measured from the frames, since system spacing settles during layout
	private func marginToParentView() -> CGFloat {
		guard let superview else { return 0 }
		
		let margins = [
			frame.minX - superview.bounds.minX,
			superview.bounds.maxX - frame.maxX,
			frame.minY - superview.bounds.minY,
			superview.bounds.maxY - frame.maxY
		]
		
		return max(margins.max() ?? 0, 0)
	}

}
