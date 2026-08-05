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
	
	private(set) var settingsWindowController: SettingsWindowController?
	
	func setupForSettingsWindow() {
		// Prepare setting panes
		
		// Case 1. Create panes with storyboard (See `DemoViewControllers.swift` and Main.storyboard for details).
		
		//   The “General” and “View” panes have no storyboard scene. Their views and sections are built entirely in code.
		let generalPane = GeneralSettingsPaneViewController(tabName: String(localized: "General"),
															tabImage: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil),
															tabIdentifier: "General",
															isResizableView: false)
		
		let viewPane = ViewSettingsPaneViewController(tabName: String(localized: "View"),
													  tabImage: NSImage(systemSymbolName: "eyeglasses", accessibilityDescription: nil),
													  tabIdentifier: "View",
													  isResizableView: false)
		
		settingsWindowController = .init(with: [
			generalPane,
			viewPane,
			ExtensionsSettingsPaneViewController.fromStoryboard(),
			AdvancedSettingsPaneViewController.fromStoryboard(),
		])


		// Case 2. You can also insert additional panes manually.
		
		guard let settingsWindowController else { return }
		
		//   Insert "Updates" tab to "Extensions [HERE] Advanced"
		settingsWindowController.tabViewController.insert(panes: [
			UpdateSettingsPaneViewController(tabName: String(localized: "Updates"),
											 tabImage: NSImage(systemSymbolName: "arrow.trianglehead.2.clockwise.rotate.90", accessibilityDescription: nil),
											 tabIdentifier: "Updates",
											 isResizableView: false)
		], at: settingsWindowController.tabViewController.panes.count-1)
		
		//   Insert "Developer" tab to the last
		settingsWindowController.tabViewController.add(panes: [
			DeveloperSettingsPaneViewController(tabName: String(localized: "Developer"),
												tabImage: NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: nil),
												tabIdentifier: "Developer",
												isResizableView: true)
		])


		// `defaultWindowTitle` is used for the title on the window menu.
		if #available(macOS 13, *) {
			settingsWindowController.settingsWindow.defaultWindowTitle = String(localized: "Settings")
		}
		else {
			settingsWindowController.settingsWindow.defaultWindowTitle = String(localized: "Preferences")
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
		settingsWindowController?.showWindow(sender)
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
