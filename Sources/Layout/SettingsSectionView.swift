//
//  SettingsSectionView.swift
//
//  Created by usagimaru on 2026/08/04.
//

import Cocoa

/// A unit of view stacked in a SettingsLayoutView
open class SettingsSectionView: NSView {

	/// Box holding the section content. The container gives it the shared block width and it stays centered
	public let contentGuide = NSLayoutGuide()

	/// Width used while the section stands outside a container
	private var standaloneWidthConstraint: NSLayoutConstraint?

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

		standaloneWidthConstraint = contentGuide.widthAnchor.constraint(equalTo: widthAnchor)
		standaloneWidthConstraint?.isActive = true
	}

	/// Follow the container's shared block width. Only the two-column sections decide it, so the rest stop asking for a width
	func adoptContentWidth(from widthGuide: NSLayoutGuide) {
		standaloneWidthConstraint?.isActive = false
		standaloneWidthConstraint = nil
		contentGuide.widthAnchor.constraint(equalTo: widthGuide.widthAnchor).isActive = true
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

/// A section that fits an arbitrary view to the full container width
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
