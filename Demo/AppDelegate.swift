//
//  AppDelegate.swift
//  MacAppSettingsUI
//
//  Created by usagimaru on 2024/03/07.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
	
	// MARK: - Setup the Setting Window
	// ====================================================>>>

	private(set) var settingsWindowController: SettingsWindowController!
	
	func setupForSettingsWindow() {
		// Prepare setting panes
		settingsWindowController = .init(with: [
			
			// Make a pane from storyboard file (Refer to auxiliary codes in Auxiliaries.swift and Main.storyboard)
			GeneralSettingsPaneViewController.fromStoryboard(),
			ViewSettingsPaneViewController.fromStoryboard(),
			ExtensionsSettingsPaneViewController.fromStoryboard(),
			AdvancedSettingsPaneViewController.fromStoryboard(),
			
			// Make a pane manually
			SettingsPaneViewController(tabName: "Developer",
									   localizeKeyForTabName: "Developer",
									   tabImage: NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: nil),
									   tabIdentifier: "Developer",
									   isResizableView: true)
		])
		
		// --------------------------------------
		// Optional:
		
		// You can also use these builder methods for `General` and `Advanced` panes.
		
		// settingsWindowController.addGeneralPane(localizeKeyForTabName: "General", isResizableView: false)
		// let advancedPane = settingsWindowController.addAdvancedPane(localizeKeyForTabName: "Advanced", isResizableView: true)
		
		
		// Starting with macOS Ventura (ver. 13), Apple began using the name `Settings` instead of `Preferences` in U.S. English.
		// You should not realistically care about `defaultWindowTitle` property,
		// as there can be no situation where there are zero tabs in the settings window.
		if #available(macOS 13, *) {
			settingsWindowController.tabViewController.defaultWindowTitle = NSLocalizedString("Settings", comment: "")
		}
		else {
			settingsWindowController.tabViewController.defaultWindowTitle = NSLocalizedString("Preferences", comment: "")
		}
	}
	
	// <<<====================================================

}
