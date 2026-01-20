//
//  AppDelegate.swift
//  MacAppSettingsUI
//
//  Created by usagimaru on 2024/03/07.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
	
	// MARK: - Setup the Setting Window (demo)
	// ====================================================>>>

	private(set) var settingsWindowController: SettingsWindowController!
	
	func setupForSettingsWindow() {
		// Prepare setting panes
		
		// Case 1. Create panes with storyboard (See `DemoViewControllers.swift` and Main.storyboard for details).
		//   “General”, “Appearance”, “Extensions”, “Advanced”
		settingsWindowController = .init(with: [
			GeneralSettingsPaneViewController.fromStoryboard(),
			ViewSettingsPaneViewController.fromStoryboard(),
			ExtensionsSettingsPaneViewController.fromStoryboard(),
			AdvancedSettingsPaneViewController.fromStoryboard(),
		])
		
		
		// Case 2. You can also insert additional panes manually.
		
		let tabName_updates: String
		let tabName_developer: String
		
		if #available(macOS 12, *) {
			tabName_updates = String(localized: "Updates")
			tabName_developer = String(localized: "Developer")
		}
		else {
			tabName_updates = NSLocalizedString("Updates", comment: "")
			tabName_developer = NSLocalizedString("Developer", comment: "")
		}
		
		//   Insert “Updates” tab to "Extensions [HERE] Advanced"
		settingsWindowController.tabViewController.insert(panes: [
			UpdateSettingsPaneViewController(tabName: tabName_updates,
											 tabImage: NSImage(systemSymbolName: "arrow.trianglehead.2.clockwise.rotate.90", accessibilityDescription: nil),
											 tabIdentifier: "Updates",
											 isResizableView: false)
		], at: settingsWindowController.tabViewController.panes.count-1)
		
		//   Insert “Developer” tab to the last
		settingsWindowController.tabViewController.add(panes: [
			DeveloperSettingsPaneViewController(tabName: tabName_developer,
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

extension AppDelegate {
	
	static var shared: AppDelegate {
		NSApp.delegate as! Self
	}
	
	func applicationWillFinishLaunching(_ notification: Notification) {
		// Localize the menu bar
		// `applicationDidFinishLaunching(_:)` is too late
		localizeMainMenuTitles()
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		setupForSettingsWindow()
	}
	
	@IBAction func openSettings(_ sender: Any) {
		settingsWindowController.showWindow(sender)
	}
	
	/// Localize menu items in the menu bar
	private func localizeMainMenuTitles() {
		guard let mainMenuItems = NSApp.mainMenu?.items else {return}
		
		func setLocalizedTitle(to menuItems: [NSMenuItem], isRoot: Bool) {
			for menuItem in menuItems {
				if menuItem.isSeparatorItem {continue}
				
				let newTitle = NSLocalizedString(menuItem.title, comment: "")
				menuItem.title = newTitle
				
				// Change the submenu’s title when it is the root
				if isRoot {
					menuItem.submenu?.title = newTitle
				}
				
				if let submenuItems = menuItem.submenu?.items {
					setLocalizedTitle(to: submenuItems, isRoot: false)
				}
			}
		}
		
		setLocalizedTitle(to: mainMenuItems, isRoot: true)
	}
	
}
