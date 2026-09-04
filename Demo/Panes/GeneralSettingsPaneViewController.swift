//
//  GeneralSettingsPaneViewController.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/01/20.
//

import Cocoa

// Section-based layout
class GeneralSettingsPaneViewController: SettingsPaneViewController {

	/// The narrowest width this pane is laid out for
	private static let minimumPaneWidth: CGFloat = 530
	
	/// Keeps the item column from stretching across the whole pane
	private static let itemColumnMaximumWidth: CGFloat = 260
	
	private var layoutView: SettingsLayoutView?
	
	/// Sub-options that follow the enabled state of "Allow notifications"
	private var notificationSubOptionCheckboxes = [NSButton]()
	
	
	// MARK: -
	
	override func loadView() {
		view = NSView()
	}
	
	override func buildPaneContent() {
		buildSections()
		sizePaneToFitContent(minimumWidth: Self.minimumPaneWidth)
	}
	
	private func buildSections() {
		// Layout with section stack
		
		let layoutView = SettingsLayoutView()
		layoutView.install(in: view)
		self.layoutView = layoutView
		
		// Section with a single item. The upper bound passed here governs the item column of every section
		let startup = layoutView.addColumnSection(label: String(localized: "Startup"),
												  itemColumnMaximumWidth: Self.itemColumnMaximumWidth,
												  identifier: .init("Startup"))
		startup.addCheckbox(title: String(localized: "Open at login"),
							target: self,
							action: nil)
		
		// Section with multiple items. Items added to the same section are stacked downward
		let behavior = layoutView.addColumnSection(label: String(localized: "Behavior"),
												   identifier: .init("Behavior"))
		behavior.addCheckbox(title: String(localized: "Confirm before quitting"),
							 isOn: true,
							 target: self,
							 action: nil)
		behavior.addCheckbox(title: String(localized: "Restore windows on launch"),
							 isOn: true,
							 target: self,
							 action: nil)
		behavior.addCheckbox(title: String(localized: "Send usage data"),
							 target: self,
							 action: nil)
		
		// Section with a pop-up button
		let downloads = layoutView.addColumnSection(label: String(localized: "Save Downloads To"),
													identifier: .init("Downloads"))
		let downloadLocation = downloads.addPopUpButton(target: self, action: nil)
		downloadLocation.addItems(withTitles: [String(localized: "Downloads Folder"),
											   String(localized: "Desktop"),
											   String(localized: "Ask Each Time")])
		downloads.addDescriptionLabel(String(localized: "GENERAL_DOWNLOADS_DESCRIPTION"))
		
		// Section with indented sub-options. The indentation level insets each item under its parent checkbox
		let notifications = layoutView.addColumnSection(label: String(localized: "Notifications"),
														identifier: .init("Notifications"))
		notifications.addCheckbox(
			title: String(localized: "Allow notifications"),
			isOn: true,
			target: self,
			action: #selector(toggleAllowNotifications(_:)))
		let playSound = notifications.addCheckbox(
			title: String(localized: "Play sound"),
			indentationLevel: 1,
			target: self,
			action: nil)
		let showPreviews = notifications.addCheckbox(
			title: String(localized: "Show previews"),
			isOn: true,
			indentationLevel: 1,
			target: self,
			action: nil)
		notificationSubOptionCheckboxes = [playSound, showPreviews]
		notifications.addDescriptionLabel(String(localized: "GENERAL_NOTIFICATIONS_DESCRIPTION"))
		
		layoutView.addSeparatorSection()
		
		// Section with a push button
		let cache = layoutView.addColumnSection(label: String(localized: "Cache"),
												identifier: .init("Cache"))
		cache.addButton(title: String(localized: "Clear Cache…"),
						target: self,
						action: nil)
		cache.addDescriptionLabel(String(localized: "GENERAL_CACHE_DESCRIPTION"))
		
		layoutView.addSeparatorSection()
		
		// Section holding an arbitrary control. The switch reveals the debug wireframes of this pane
		let wireframes = layoutView.addColumnSection(label: String(localized: "Wireframes"),
													 identifier: .init("Wireframes"))
		let wireframeSwitch = DemoSwitch(sizingWindow: tabViewController?.view.window) { [weak self] isOn in
			self?.layoutView?.debug_setWireframes(isOn)
		}
		wireframes.addCustomView(wireframeSwitch, verticalAlignment: .centerY)

		let layoutNoteLabel = SettingsWrappingLabel(string: String(localized: "Section-based layout 1"))
		layoutNoteLabel.alignment = .center
		layoutView.addCustomSection(layoutNoteLabel, identifier: .init("Layout Note"))
	}

	@objc private func toggleAllowNotifications(_ sender: Any) {
		let allowsNotifications = (sender as? NSButton)?.state == .on
		notificationSubOptionCheckboxes.forEach { $0.isEnabled = allowsNotifications }
	}

}
