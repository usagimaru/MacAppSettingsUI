//
//  AccountSettingsPaneViewController.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/09/04.
//

import Cocoa

// Section-based layout, kept sparse so the minimum height and the centered content can be seen
class AccountSettingsPaneViewController: SettingsPaneViewController {
	
	private static let minimumPaneSize = NSSize(width: 530, height: 250)
	private var layoutView: SettingsLayoutView?
	
	
	// MARK: -
	
	override func loadView() {
		view = NSView()
	}
	
	override func buildPaneContent() {
		buildSections()
		sizePaneToFitContent(minimumWidth: Self.minimumPaneSize.width, minimumHeight: Self.minimumPaneSize.height)
	}
	
	private func buildSections() {
		let layoutView = SettingsLayoutView()
		layoutView.install(in: view)
		
		// Surplus height is split above and below the sections
		layoutView.verticalAlignment = .center
		self.layoutView = layoutView
		
		let account = layoutView.addColumnSection(label: String(localized: "Account"),
												  identifier: .init("Account"))
		account.addCheckbox(title: String(localized: "Sync with iCloud"),
							isOn: true,
							target: self,
							action: nil)
		account.addButton(title: String(localized: "Manage Account…"),
						  target: self,
						  action: nil)
		
		let wireframes = layoutView.addColumnSection(label: String(localized: "Wireframes"), identifier: .init("Wireframes"))
		let wireframeSwitch = DemoSwitch(sizingWindow: tabViewController?.view.window) { [weak self] isOn in
			self?.layoutView?.debug_setWireframes(isOn)
		}
		wireframes.addCustomView(wireframeSwitch, verticalAlignment: .centerY)

		let layoutNoteLabel = SettingsWrappingLabel(string: String(localized: "Sparse content, centered"))
		layoutNoteLabel.alignment = .center
		layoutView.addCustomSection(layoutNoteLabel, identifier: .init("Layout Note"))
	}
	
}
