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
		// Case 1. Create panes and hand them to the window controller

		let generalPane = GeneralSettingsPaneViewController(
			tabName: String(localized: "General"),
			tabImage: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil),
			tabIdentifier: "General",
			isResizableView: false)
		
		let viewPane = ViewSettingsPaneViewController(
			tabName: String(localized: "View"),
			tabImage: NSImage(systemSymbolName: "eyeglasses", accessibilityDescription: nil),
			tabIdentifier: "View",
			isResizableView: false)
		
		let accountPane = AccountSettingsPaneViewController(
			tabName: String(localized: "Account"),
			tabImage: NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: nil),
			tabIdentifier: "Account",
			isResizableView: false)

		let extensionsPane = ExtensionsSettingsPaneViewController(
			tabName: String(localized: "Extensions"),
			tabImage: NSImage(systemSymbolName: "puzzlepiece.extension", accessibilityDescription: nil),
			tabIdentifier: "Extensions",
			isResizableView: true)
		
		
		// Case 2. Create a pane from storyboard
		let advancedPane = AdvancedSettingsPaneViewController.fromStoryboard()
		
		
		settingsWindowController = .init(with: [
			generalPane,
			viewPane,
			accountPane,
			extensionsPane,
			advancedPane,
		], centersWindowPositionAlways: DemoOptions.centersWindowAlways)
		
		guard let settingsWindowController else { return }
		
		
		// Case 3. You can also insert additional panes manually.
		
		//   Insert "Updates" tab to "[Extensions] [HERE] [Advanced]"
		settingsWindowController.tabViewController.insert(panes: [
			UpdateSettingsPaneViewController(
				tabName: String(localized: "Updates"),
				tabImage: NSImage(systemSymbolName: "arrow.trianglehead.2.clockwise.rotate.90", accessibilityDescription: nil),
				tabIdentifier: "Updates",
				isResizableView: false)
		], at: settingsWindowController.tabViewController.panes.count-1)
		
		//   Insert "Developer" tab to the last
		settingsWindowController.tabViewController.add(panes: [
			DeveloperSettingsPaneViewController(
				tabName: String(localized: "Developer"),
				tabImage: NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: nil),
				tabIdentifier: "Developer",
				isResizableView: true)
		])
		
		
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
			settingsWindowController.settingsWindow.defaultWindowTitle = String(localized: "Settings")
		}
		else {
			settingsWindowController.settingsWindow.defaultWindowTitle = String(localized: "Preferences")
		}
		
		
		// Released on close, so the panes are rebuilt on the next open. Tab restoration survives that release
		settingsWindowController.restoresLastSelectedTab = true
		settingsWindowController.windowCloseHandler = { [weak self] in
			self?.settingsWindowController = nil
		}

		settingsWindowController.applyAnimationOption()
		settingsWindowController.tabViewController.loadingLabelText = String(localized: "Loading…")

		// Only the pane that actually waits shows the label
		settingsWindowController.tabViewController.showsLoadingLabelWhileLoading = false
	}

	// <<<====================================================
	
}

extension AppDelegate {

	static var shared: AppDelegate {
		NSApp.delegate as! Self
	}
	
	func applicationWillFinishLaunching(_ notification: Notification) {
		// Localizing after the launch finished is too late for the menu bar
		localizeMainMenuTitles()
	}
	
	@IBAction func openSettings(_ sender: Any) {
		// Built on demand, since it is released every time the window closes
		if settingsWindowController == nil {
			setupForSettingsWindow()
		}

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
