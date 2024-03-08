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
	private var observationForNSWorkspace: NSObjectProtocol?
	private var observationForNSApplication: NSObjectProtocol?
	
	public var tabViewController: SettingsTabViewController! { didSet {
		tabViewController.windowController = self
	}}
	
	public class func windowController(with panes: [SettingsPaneViewController]? = nil) -> Self {
		let tabViewController = SettingsTabViewController()
		let wc = Self.init()
		wc.window = NSWindow.settingsWindow(contentViewController: tabViewController)
		wc.tabViewController = tabViewController
		wc.initialSetup()
		
		panes?.forEach({
			tabViewController.add(pane: $0)
		})
		
		return wc
	}
	
	private func initialSetup() {
		tabViewController?.windowController = self
		
		if let observationForNSWorkspace {
			NSWorkspace.shared.notificationCenter.removeObserver(observationForNSWorkspace)
		}
		if let observationForNSApplication {
			NotificationCenter.default.removeObserver(observationForNSApplication)
		}
		
		// This is called when the "Display" accessibility settings are changed.
		observationForNSWorkspace = NSWorkspace.shared.notificationCenter
			.addObserver(forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
						 object: nil,
						 queue: .main) { notif in
				self.setupBehaviors()
			}
		
		// If window restoration is enabled, `windowDidLoad()` and `showWindow(_:)` are not called by the system.
		// This is done to grab the first displaying of windows under the window restoration process.
		observationForNSApplication = NotificationCenter.default
			.addObserver(forName: NSApplication.didFinishRestoringWindowsNotification,
						 object: NSApp,
						 queue: .main,
						 using: { notif in
				self.setupBehaviors()
			})
	}
	
	private func setupBehaviors() {
		// Disable the full screen zoom button.
		window?.collectionBehavior = .fullScreenAuxiliary
		// Reflects “Reduce Motion” of System Settings
		tabViewController?.disablesAnimationOfTabSwitching = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
	}
	
	open override func windowDidLoad() {
		super.windowDidLoad()
		initialSetup()
	}
	
	open override func showWindow(_ sender: Any?) {
		super.showWindow(sender)
		
		if isFirst || centersWindowPositionAlways {
			window?.center()
			isFirst = false
		}
		
		setupBehaviors()
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
