//
//  AppDelegate.swift
//  MacAppSettingsUI
//
//  Created by usagimaru on 2024/03/07.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
	
	static var shared: AppDelegate {
		NSApp.delegate as! Self
	}

	private var settingsWindowController: SettingsWindowController!
	
	func applicationWillFinishLaunching(_ notification: Notification) {
		// Localize the menu bar
		// `applicationDidFinishLaunching(_:)` is too late
		localizeMainMenuTitles()
	}

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Prepare setting panes
		settingsWindowController = .windowController(with: [
			
			// Make pane from storyboard file
			GeneralSettingsPaneViewController.fromStoryboard(),
			ViewSettingsPaneViewController.fromStoryboard(),
			ExtensionsSettingsPaneViewController.fromStoryboard(),
			AdvancedSettingsPaneViewController.fromStoryboard(),
			
			// Make pane programatically
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

extension SettingsPaneViewController {
	
	class func fromStoryboard(tabViewController: SettingsTabViewController? = nil,
							  tabName: String? = nil,
							  localizeKeyForTabName: String? = nil,
							  tabImage: NSImage? = nil,
							  tabIdentifier: String? = nil,
							  isResizableView: Bool? = nil) -> Self {
		let vc = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "\(Self.self)") as! Self
		vc.tabViewController = tabViewController
		
		if let tabName {
			vc.tabName = tabName
		}
		if let localizeKeyForTabName {
			vc.localizeKeyForTabName = localizeKeyForTabName
		}
		if let tabImage {
			vc.tabImage = tabImage
		}
		if let tabIdentifier {
			vc.tabIdentifier = tabIdentifier
		}
		if let isResizableView {
			vc.isResizableView = isResizableView
		}
		
		return vc
	}
	
}

class GeneralSettingsPaneViewController: SettingsPaneViewController {}

class ViewSettingsPaneViewController: SettingsPaneViewController {}

class ExtensionsSettingsPaneViewController: SettingsPaneViewController {}

class AdvancedSettingsPaneViewController: SettingsPaneViewController {}

class DemoViewController: NSViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		DispatchQueue.main.async {
			self.view.window?.isMovableByWindowBackground = true
		}
	}
	
}
