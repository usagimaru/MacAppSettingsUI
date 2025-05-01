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
		
		// Case 1. Create panes with storyboard (See Auxiliaries.swift and Main.storyboard for details).
		settingsWindowController = .init(with: [
			GeneralSettingsPaneViewController.fromStoryboard(),
			ViewSettingsPaneViewController.fromStoryboard(),
			ExtensionsSettingsPaneViewController.fromStoryboard(),
			AdvancedSettingsPaneViewController.fromStoryboard(),
		])
		
		
		// Case 2. You can also insert additional panes manually.
		settingsWindowController.tabViewController.insert(panes: [
			UpdateSettingsPaneViewController(tabName: "Updates",
											 localizeKeyForTabName: "Updates",
											 tabImage: NSImage(systemSymbolName: "arrow.trianglehead.2.clockwise.rotate.90", accessibilityDescription: nil),
											 tabIdentifier: "Updates",
											 isResizableView: false)
		], at: settingsWindowController.tabViewController.panes.count-1)
		
		settingsWindowController.tabViewController.add(panes: [
			DeveloperSettingsPaneViewController(tabName: "Developer",
												localizeKeyForTabName: "Developer",
												tabImage: NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: nil),
												tabIdentifier: "Developer",
												isResizableView: true)
		])
		
		
		// `defaultWindowTitle` is used for the title on the window menu.
		if #available(macOS 13, *) {
			settingsWindowController.settingsWindow.defaultWindowTitle = NSLocalizedString("Settings", comment: "")
		}
		else {
			settingsWindowController.settingsWindow.defaultWindowTitle = NSLocalizedString("Preferences", comment: "")
		}
		
		
		/*
		 Notes about “Settings” and “Preferences”:
		 
		 Starting with macOS Ventura (version 13), Apple began using the label `Settings` instead of `Preferences` in U.S. English to describe a preferences UI.
		 Therefore, all Mac apps must label preferences as “Settings”.
		 
		 If there is a “Preferences…” menu item in the Main Menu, the system automatically relabels it with “Settings…” in the runtime when the app is launched, so we no need to implement an extra program.
		 Also we can disable this behavior through the “NSMenuShouldUpdateSettingsTitle” as Bool in the environment variables. (Not that we need to.)
		 
		 For labels outside of this mechanism on the Main Menu, developers will need to deal with them themselves.
		 */
	}
	
	// <<<====================================================

}
