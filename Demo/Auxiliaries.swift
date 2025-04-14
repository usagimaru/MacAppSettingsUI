//
//  Auxiliaries.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2024/03/09.
//

import Cocoa

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


// MARK: -

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
	
	@IBOutlet var centerAlways: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		DispatchQueue.main.async {
			self.view.window?.isMovableByWindowBackground = true
		}
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		DispatchQueue.main.async {
			AppDelegate.shared.settingsWindowController.centersWindowPositionAlways = self.centerAlways.state == .on
		}
	}
	
	@IBAction func toggleCenterAlways(_ sender: NSButton) {
		AppDelegate.shared.settingsWindowController.centersWindowPositionAlways = sender.state == .on
	}
	
	@IBAction func removeAutosaveFrame(_ sender: Any) {
		AppDelegate.shared.settingsWindowController.removeAutosavedWindowFrame()
	}
	
}

extension NSButton {
	
	@IBInspectable var titleLocalizable: String {
		get {
			self.titleLocalizable
		}
		set {
			title = NSLocalizedString(newValue, comment: "")
		}
	}
	
	@IBInspectable var altTitleLocalizable: String {
		get {
			self.altTitleLocalizable
		}
		set {
			alternateTitle = NSLocalizedString(newValue, comment: "")
		}
	}
	
}
