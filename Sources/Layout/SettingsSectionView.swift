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

	/// Width of the section itself, which the container has already stretched to its full width
	private var fullWidthConstraint: NSLayoutConstraint?
	/// Width shared with the two-column block. Absent while the section stands outside a container
	private var contentBlockWidthConstraint: NSLayoutConstraint?

	public init(identifier: NSUserInterfaceItemIdentifier? = nil) {
		super.init(frame: .zero)
		self.identifier = identifier
		setUpContentGuide()
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
		SettingsDebugWireframe.applyToSection(isDebugWireframesAllowed(flag), section: self)
	}

	/// Wireframes never appear in release builds
	public func isDebugWireframesAllowed(_ flag: Bool) -> Bool {
#if DEBUG
		flag
#else
		false
#endif
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
