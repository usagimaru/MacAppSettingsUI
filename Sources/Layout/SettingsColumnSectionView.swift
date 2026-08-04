//
//  SettingsColumnSectionView.swift
//
//  Created by usagimaru on 2026/08/04.
//

import Cocoa

/// Vertical alignment of an item in a section against its label
public enum SettingsItemVerticalAlignment {

	case firstBaseline
	case top
	case centerY

}

/// A two-column section made of one trailing-aligned label and any number of leading-aligned items
open class SettingsColumnSectionView: SettingsSectionView {

	public private(set) var titleLabel: NSTextField!

	/// Upper bound of the item column width. nil lets the column follow whatever its items need
	open var itemColumnMaximumWidth: CGFloat? {
		didSet {
			updateItemColumnMaximumWidthConstraint()
		}
	}

	/// Box of the label column. Its width comes from the container guide
	private let labelBoxGuide = NSLayoutGuide()
	/// Box of the item column. It sits on the trailing side of the label column
	private let itemBoxGuide = NSLayoutGuide()

	private unowned let labelColumnWidthGuide: NSLayoutGuide
	private unowned let itemColumnWidthGuide: NSLayoutGuide

	private var items = [NSView]()
	private var bottomConstraint: NSLayoutConstraint?
	private var itemColumnMaximumWidthConstraint: NSLayoutConstraint?
	/// Constraints that let the label decide the height while no item has been added yet
	private var labelOnlyVerticalConstraints = [NSLayoutConstraint]()

	private var debugLabelBoxLayer = CALayer()
	private var debugItemBoxLayer = CALayer()
	private var isDebugWireframesEnabled = false


	// MARK: - Initialization

	public init(labelTitle: String,
				labelColumnWidthGuide: NSLayoutGuide,
				itemColumnWidthGuide: NSLayoutGuide,
				itemColumnMaximumWidth: CGFloat? = nil,
				identifier: NSUserInterfaceItemIdentifier? = nil)
	{
		self.labelColumnWidthGuide = labelColumnWidthGuide
		self.itemColumnWidthGuide = itemColumnWidthGuide
		self.itemColumnMaximumWidth = itemColumnMaximumWidth
		super.init(identifier: identifier)

		setUpGuides()
		setUpTitleLabel(labelTitle)
		setUpDebugLayers()
		updateItemColumnMaximumWidthConstraint()
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setUpGuides() {
		[labelBoxGuide, itemBoxGuide].forEach { addLayoutGuide($0) }

		// The two columns fill the content box exactly, so centering and width are left to the base class
		NSLayoutConstraint.activate([
			labelBoxGuide.topAnchor.constraint(equalTo: topAnchor),
			labelBoxGuide.bottomAnchor.constraint(equalTo: bottomAnchor),
			labelBoxGuide.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
			itemBoxGuide.topAnchor.constraint(equalTo: topAnchor),
			itemBoxGuide.bottomAnchor.constraint(equalTo: bottomAnchor),
			itemBoxGuide.leadingAnchor.constraint(equalTo: labelBoxGuide.trailingAnchor,
												  constant: SettingsLayoutMetrics.columnSpacing),
			itemBoxGuide.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
		])
	}

	/// The container shares the item column width guide across every section, so this bound reaches the whole layout
	private func updateItemColumnMaximumWidthConstraint() {
		itemColumnMaximumWidthConstraint?.isActive = false
		itemColumnMaximumWidthConstraint = nil

		guard let itemColumnMaximumWidth else { return }

		let constraint = itemColumnWidthGuide.widthAnchor.constraint(lessThanOrEqualToConstant: itemColumnMaximumWidth)
		constraint.priority = SettingsLayoutPriority.itemColumnMaximumWidth
		constraint.isActive = true
		itemColumnMaximumWidthConstraint = constraint
	}

	private func setUpTitleLabel(_ title: String) {
		// The colon comes from here so that a localization key holds the wording alone
		titleLabel = NSTextField()
		titleLabel.stringValue = "\(title):"
		titleLabel.isEditable = false
		titleLabel.isBordered = false
		titleLabel.isSelectable = false
		titleLabel.backgroundColor = .clear
		titleLabel.textColor = .labelColor
		titleLabel.alignment = .right
		titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize)

		// Left in wrapping mode the label gains no intrinsic width and the column collapses to zero
		titleLabel.usesSingleLineMode = true
		titleLabel.lineBreakMode = .byTruncatingTail
		titleLabel.cell?.isScrollable = false

		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		addSubview(titleLabel)

		NSLayoutConstraint.activate([
			titleLabel.trailingAnchor.constraint(equalTo: labelBoxGuide.trailingAnchor),
			titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: labelBoxGuide.leadingAnchor),
			titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
			titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
		])

		labelOnlyVerticalConstraints = [
			titleLabel.topAnchor.constraint(equalTo: topAnchor),
			titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
		]
		NSLayoutConstraint.activate(labelOnlyVerticalConstraints)
	}

	/// Activate the constraints that cross into the container column width guides. Call it after joining the view hierarchy
	public func activateColumnWidthConstraints() {
		NSLayoutConstraint.activate([
			labelBoxGuide.widthAnchor.constraint(equalTo: labelColumnWidthGuide.widthAnchor),
			itemBoxGuide.widthAnchor.constraint(equalTo: itemColumnWidthGuide.widthAnchor),
			labelColumnWidthGuide.widthAnchor.constraint(greaterThanOrEqualTo: titleLabel.widthAnchor),
		])
	}


	// MARK: - Adding items

	/// Checkbox
	@discardableResult
	public func addCheckbox(title: String, isOn: Bool = false, target: AnyObject?, action: Selector?) -> NSButton {
		let checkbox = NSButton(checkboxWithTitle: title, target: target, action: action)
		checkbox.state = isOn ? .on : .off
		appendItem(checkbox, verticalAlignment: .firstBaseline, contributesToColumnWidth: true)
		return checkbox
	}

	/// Supplementary description label. Its width comes from the column and it takes no part in deciding the column width
	@discardableResult
	public func addDescriptionLabel(_ string: String) -> SettingsWrappingLabel {
		let label = SettingsWrappingLabel(string: string)
		appendItem(label, verticalAlignment: .firstBaseline, contributesToColumnWidth: false)
		return label
	}

	/// Button
	@discardableResult
	public func addButton(title: String,
						  controlSize: NSControl.ControlSize = .regular,
						  target: AnyObject?,
						  action: Selector?) -> NSButton
	{
		let button = NSButton(title: title, target: target, action: action)
		button.bezelStyle = .push
		Self.applyControlSize(controlSize, to: button)
		appendItem(button, verticalAlignment: .firstBaseline, contributesToColumnWidth: true)
		return button
	}

	/// Pop-up button
	@discardableResult
	public func addPopUpButton(controlSize: NSControl.ControlSize = .regular,
							   target: AnyObject?,
							   action: Selector?) -> NSPopUpButton
	{
		let popUpButton = NSPopUpButton(frame: .zero, pullsDown: false)
		popUpButton.target = target
		popUpButton.action = action
		Self.applyControlSize(controlSize, to: popUpButton)
		appendItem(popUpButton, verticalAlignment: .firstBaseline, contributesToColumnWidth: true)
		return popUpButton
	}

	/// Arbitrary view
	public func addCustomView(_ view: NSView, verticalAlignment: SettingsItemVerticalAlignment = .firstBaseline) {
		appendItem(view, verticalAlignment: verticalAlignment, contributesToColumnWidth: true)
	}

	/// Attach an accessory view next to an item added earlier
	@discardableResult
	public func addAccessoryView(_ accessoryView: NSView,
								 to item: NSView,
								 spacing: CGFloat = SettingsLayoutMetrics.columnSpacing) -> NSView
	{
		accessoryView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(accessoryView)

		// A guide across both is needed to demand the combined width of the item and the accessory view from the column
		let pairGuide = NSLayoutGuide()
		addLayoutGuide(pairGuide)

		NSLayoutConstraint.activate([
			accessoryView.centerYAnchor.constraint(equalTo: item.centerYAnchor),
			accessoryView.leadingAnchor.constraint(equalTo: item.trailingAnchor, constant: spacing),
			accessoryView.trailingAnchor.constraint(lessThanOrEqualTo: itemBoxGuide.trailingAnchor),
			accessoryView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
			accessoryView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),

			pairGuide.leadingAnchor.constraint(equalTo: item.leadingAnchor),
			pairGuide.trailingAnchor.constraint(equalTo: accessoryView.trailingAnchor),
			pairGuide.topAnchor.constraint(equalTo: topAnchor),
			pairGuide.heightAnchor.constraint(equalToConstant: 0),
			itemColumnWidthGuide.widthAnchor.constraint(greaterThanOrEqualTo: pairGuide.widthAnchor),
		])

		SettingsDebugWireframe.apply(isDebugWireframesEnabled, to: accessoryView, color: SettingsDebugWireframe.controlColor)

		return accessoryView
	}

	private func appendItem(_ item: NSView,
							verticalAlignment: SettingsItemVerticalAlignment,
							contributesToColumnWidth: Bool)
	{
		let previousItem = items.last

		item.translatesAutoresizingMaskIntoConstraints = false
		addSubview(item)

		var constraints = [item.leadingAnchor.constraint(equalTo: itemBoxGuide.leadingAnchor)]

		if contributesToColumnWidth {
			constraints.append(item.trailingAnchor.constraint(lessThanOrEqualTo: itemBoxGuide.trailingAnchor))
			constraints.append(itemColumnWidthGuide.widthAnchor.constraint(greaterThanOrEqualTo: item.widthAnchor))
		}
		else {
			// The wrapping width arrives through `availableWidth`, so the box only needs to stay inside the column
			constraints.append(item.trailingAnchor.constraint(lessThanOrEqualTo: itemBoxGuide.trailingAnchor))

			// Asking with the box width would be circular, because that width is what this demand decides.
			// Round up, or integralizing the box can land a point short of the text and wrap it needlessly
			if let label = item as? SettingsWrappingLabel {
				let demand = itemColumnWidthGuide.widthAnchor
					.constraint(greaterThanOrEqualToConstant: label.naturalTextWidth.rounded(.up))
				demand.priority = SettingsLayoutPriority.descriptionWidthDemand
				constraints.append(demand)
			}
		}

		if let previousItem {
			constraints.append(item.topAnchor.constraint(equalTo: previousItem.bottomAnchor,
														 constant: SettingsLayoutMetrics.itemSpacing))
		}
		else {
			constraints.append(item.topAnchor.constraint(equalTo: topAnchor))
		}

		NSLayoutConstraint.activate(constraints)

		if previousItem == nil {
			NSLayoutConstraint.deactivate(labelOnlyVerticalConstraints)
			activateLabelAlignment(to: item, verticalAlignment: verticalAlignment)
		}

		bottomConstraint?.isActive = false
		bottomConstraint = bottomAnchor.constraint(equalTo: item.bottomAnchor)
		bottomConstraint?.isActive = true

		SettingsDebugWireframe.apply(isDebugWireframesEnabled, to: item, color: SettingsDebugWireframe.controlColor)

		items.append(item)
	}

	private func activateLabelAlignment(to item: NSView, verticalAlignment: SettingsItemVerticalAlignment) {
		switch verticalAlignment {
			case .firstBaseline:
				titleLabel.firstBaselineAnchor.constraint(equalTo: item.firstBaselineAnchor).isActive = true

			case .top:
				titleLabel.topAnchor.constraint(equalTo: item.topAnchor).isActive = true

			case .centerY:
				titleLabel.centerYAnchor.constraint(equalTo: item.centerYAnchor).isActive = true
		}
	}


	// MARK: - Debug

	private func setUpDebugLayers() {
		wantsLayer = true

		[debugLabelBoxLayer, debugItemBoxLayer].forEach {
			layer?.insertSublayer($0, at: 0)
			$0.borderWidth = 1
			$0.isHidden = true
		}

		debugLabelBoxLayer.borderColor = SettingsDebugWireframe.tinted(SettingsDebugWireframe.labelColumnColor).cgColor
		debugItemBoxLayer.borderColor = SettingsDebugWireframe.tinted(SettingsDebugWireframe.itemColumnColor).cgColor
	}

	open override func debug_setWireframes(_ flag: Bool) {
		isDebugWireframesEnabled = isDebugWireframesAllowed(flag)
		[debugLabelBoxLayer, debugItemBoxLayer].forEach { $0.isHidden = !isDebugWireframesEnabled }
		super.debug_setWireframes(isDebugWireframesEnabled)
	}

	open override func layout() {
		super.layout()

		let itemColumnWidth = itemBoxGuide.frame.width
		items.forEach { ($0 as? SettingsWrappingLabel)?.availableWidth = itemColumnWidth }

		CATransaction.begin()
		CATransaction.setDisableActions(true)
		debugLabelBoxLayer.frame = labelBoxGuide.frame
		debugItemBoxLayer.frame = itemBoxGuide.frame
		[debugLabelBoxLayer, debugItemBoxLayer].forEach {
			$0.contentsScale = window?.backingScaleFactor ?? 1.0
		}
		CATransaction.commit()
	}

}
