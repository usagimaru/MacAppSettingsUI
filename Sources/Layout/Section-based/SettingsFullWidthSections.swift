//
//  SettingsFullWidthSections.swift
//
//  Created by usagimaru on 2026/08/04.
//

import Cocoa

/// Horizontal placement of a control inside the section content box
public enum SettingsSectionAlignment {

	case leading
	case center
	case trailing

}

/// A separator that spans the section content box
open class SettingsSeparatorSectionView: SettingsSectionView {

	public private(set) var separator: NSBox!

	public override init(identifier: NSUserInterfaceItemIdentifier? = nil) {
		super.init(identifier: identifier)

		separator = NSBox()
		separator.boxType = .separator
		separator.translatesAutoresizingMaskIntoConstraints = false
		addSubview(separator)

		NSLayoutConstraint.activate([
			separator.topAnchor.constraint(equalTo: topAnchor),
			separator.bottomAnchor.constraint(equalTo: bottomAnchor),
			separator.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
			separator.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
		])
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

/// A section that places a single button in the section content box
open class SettingsButtonSectionView: SettingsSectionView {

	public private(set) var button: NSButton!

	public init(title: String,
				controlSize: NSControl.ControlSize = .regular,
				alignment: SettingsSectionAlignment = .center,
				indentationLevel: Int = 0,
				indentationPerLevel: CGFloat = SettingsLayoutMetrics.indentationPerLevel,
				identifier: NSUserInterfaceItemIdentifier? = nil,
				target: AnyObject?,
				action: Selector?)
	{
		super.init(identifier: identifier)

		let indentation = Self.indentation(forLevel: indentationLevel, perLevel: indentationPerLevel)

		button = NSButton(title: title, target: target, action: action)
		button.bezelStyle = .push
		Self.applyControlSize(controlSize, to: button)
		button.translatesAutoresizingMaskIntoConstraints = false
		addSubview(button)

		var constraints = [
			button.topAnchor.constraint(equalTo: topAnchor),
			button.bottomAnchor.constraint(equalTo: bottomAnchor),
			button.leadingAnchor.constraint(greaterThanOrEqualTo: contentGuide.leadingAnchor, constant: indentation),
			button.trailingAnchor.constraint(lessThanOrEqualTo: contentGuide.trailingAnchor),
		]

		switch alignment {
			case .leading:
				constraints.append(button.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor,
																  constant: indentation))

			case .center:
				// The inset shifts the center, or an indented button would sit where an unindented one does
				constraints.append(button.centerXAnchor.constraint(equalTo: contentGuide.centerXAnchor,
																  constant: indentation / 2))

			case .trailing:
				constraints.append(button.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor))
		}

		NSLayoutConstraint.activate(constraints)
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

/// A section that places a leading-aligned checkbox in the section content box, optionally with a description
open class SettingsCheckboxSectionView: SettingsSectionView {

	public private(set) var checkbox: NSButton!
	public private(set) var descriptionLabel: SettingsWrappingLabel?

	private let indentation: CGFloat

	public init(title: String,
				isOn: Bool = false,
				description: String? = nil,
				indentationLevel: Int = 0,
				indentationPerLevel: CGFloat = SettingsLayoutMetrics.indentationPerLevel,
				identifier: NSUserInterfaceItemIdentifier? = nil,
				target: AnyObject?,
				action: Selector?)
	{
		self.indentation = Self.indentation(forLevel: indentationLevel, perLevel: indentationPerLevel)
		super.init(identifier: identifier)

		checkbox = NSButton(checkboxWithTitle: title, target: target, action: action)
		checkbox.state = isOn ? .on : .off
		checkbox.translatesAutoresizingMaskIntoConstraints = false
		addSubview(checkbox)

		var constraints = [
			checkbox.topAnchor.constraint(equalTo: topAnchor),
			checkbox.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: indentation),
			checkbox.trailingAnchor.constraint(lessThanOrEqualTo: contentGuide.trailingAnchor),
		]

		if let description {
			let label = SettingsWrappingLabel(string: description)
			descriptionLabel = label
			label.translatesAutoresizingMaskIntoConstraints = false
			addSubview(label)

			constraints += [
				label.topAnchor.constraint(equalTo: checkbox.bottomAnchor,
										   constant: SettingsLayoutMetrics.itemSpacing),
				label.leadingAnchor.constraint(equalTo: checkbox.leadingAnchor),
				label.trailingAnchor.constraint(lessThanOrEqualTo: contentGuide.trailingAnchor),
				label.bottomAnchor.constraint(equalTo: bottomAnchor),
			]
		}
		else {
			constraints.append(checkbox.bottomAnchor.constraint(equalTo: bottomAnchor))
		}

		NSLayoutConstraint.activate(constraints)
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	open override func layout() {
		super.layout()
		// The label starts at the indented leading edge, so the inset comes off its wrapping width
		descriptionLabel?.availableWidth = contentGuide.frame.width - indentation
	}

}
