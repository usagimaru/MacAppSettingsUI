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
			
			// Case 1. Create panes with storyboard (Auxiliaries.swift and Main.storyboard for details).
			GeneralSettingsPaneViewController.fromStoryboard(),
			ViewSettingsPaneViewController.fromStoryboard(),
			ExtensionsSettingsPaneViewController.fromStoryboard(),
			AdvancedSettingsPaneViewController.fromStoryboard(),
			
			// Case 2. You can also create panes manually.
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
		
		
		/*
		 Notes about “Settings” and “Preferences”:
		 
		 Starting with macOS Ventura (version 13), Apple began using the label `Settings` instead of `Preferences` in U.S. English to describe a preferences UI.
		 Therefore, all Mac apps must label preferences as “Settings”.
		 
		 If there is a “Preferences…” menu item in the Main Menu, the system automatically relabels it with “Settings…” in the runtime when the app is launched, so we no need to implement an extra program.
		 Also we can disable this behavior through the “NSMenuShouldUpdateSettingsTitle” as Bool in the environment variables. (Not that we need to.)
		 
		 For labels outside of this mechanism on the Main Menu, developers will need to deal with them themselves.
		 */
		
		// `defaultWindowTitle` is used for the title on the window menu.
		if #available(macOS 13, *) {
			settingsWindowController.tabViewController.defaultWindowTitle = NSLocalizedString("Settings", comment: "")
		}
		else {
			settingsWindowController.tabViewController.defaultWindowTitle = NSLocalizedString("Preferences", comment: "")
		}
	}
	
	// <<<====================================================

}
