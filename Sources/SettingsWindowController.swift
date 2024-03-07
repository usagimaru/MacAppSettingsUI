//
//  PreferencesWindowController.swift
//
//  Created by usagimaru on 2022/03/26.
//

import Cocoa

open class SettingsWindowController: NSWindowController {
	
	public static var storyboardName: String = "Settings"
	
	/// Set window position to center of the screen
	open var centersWindowPositionAlways: Bool = false
	/// Do not want to close window with Escape key, set this flag to false
	open var closesWindowWithEscapeKey: Bool = true
	
	private var isFirst: Bool = true
	
	public var tabViewController: SettingsTabViewController! { didSet {
		tabViewController.windowController = self
	}}
	
	open override func windowTitle(forDocumentDisplayName displayName: String) -> String {
		"Settings"
	}
	
	open override func synchronizeWindowTitleWithDocumentName() {
		
	}
	
	public class func windowController(with panes: [SettingsPaneViewController]? = nil) -> Self {
		let tabViewController = SettingsTabViewController()
		let wc = Self.init()
		let window = NSWindow.settingsWindow(contentViewController: tabViewController)
		wc.window = window
		wc.tabViewController = tabViewController
		
		panes?.forEach({
			tabViewController.add(pane: $0)
		})
		
		return wc
	}
	
	open override func windowDidLoad() {
		super.windowDidLoad()
		tabViewController?.windowController = self
		window?.collectionBehavior = .fullScreenAuxiliary
	}
	
	open override func showWindow(_ sender: Any?) {
		super.showWindow(sender)
		
		if isFirst || centersWindowPositionAlways {
			window?.center()
			isFirst = false
		}
	}
	
	/// Close window to press Escape key
	@objc open func cancel(_ sender: Any?) {
		if closesWindowWithEscapeKey {
			close()
		}
	}

}

public extension NSWindow {
	
	class func settingsWindow(contentViewController: NSTabViewController) -> Self {
		// Set Toolbar style to TabViewController
		contentViewController.tabStyle = .toolbar
		
		let window = Self(contentViewController: contentViewController)
		
		// The macOS settings/preferences window is generally styled to apply basically only with a close button. The minimize button should be disabled.
		// However, depending on a contents of a pane, resizing can be enabled as in Xcode.
		window.styleMask = [
			.titled,
			.closable,
		]
		
		window.titlebarSeparatorStyle = .automatic
		// Disable full-screen and enable traditional zoom button
		window.collectionBehavior = .fullScreenAuxiliary
		// Not need it
		//window.toolbarStyle = .preference
		
		return window
	}
	
}
