//
//  PreferencesWindowController.swift
//
//  Created by usagimaru on 2022/03/26.
//

import Cocoa

public class SettingsWindowController: NSWindowController {
	
	public struct Keys {
		/// UserDefaults key for `savesLastWindowFrame`
		static let lastWindowFrame = "\(SettingsWindowController.self).lastFrame"
	}
	
	/// Set window position to center of the screen
	open var centersWindowPositionAlways: Bool!
	/// Do not want to close window with Escape key, set this flag to false
	open var closesWindowWithEscapeKey: Bool!
	
	/// Get the window menu item for this window
	open var windowMenuItem: NSMenuItem? {
		NSApp.windowsMenu?.items.filter {
			window != nil
			&& ($0.target as? NSWindow) == window
			&& $0.action == #selector(NSWindow.makeKeyAndOrderFront(_:))
		}.first
		
		// Note: This NSMenuItem is `NSWindowRepresentingMenuItem` under private.
	}
	
	open var tabViewController: SettingsTabViewController! { didSet {
		tabViewController.windowController = self
	}}
	
	open var settingsWindow: SettingsWindow {
		window as! SettingsWindow
	}
	
	open override var shouldCascadeWindows: Bool {
		// When if use `windowFrameAutosaveName`, We have to disable `shouldCascadeWindows`
		// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/WinPanel/Tasks/SavingWindowPosition.html
		get { false }
		set { super.shouldCascadeWindows = false }
	}
	
	
	// MARK: -
	
	/// Initializer
	required convenience public init(with panes: [SettingsPaneViewController],
									 centersWindowPositionAlways: Bool = false,
									 closesWindowWithEscapeKey: Bool = true) {
		
		self.init()
		
		self.centersWindowPositionAlways = centersWindowPositionAlways
		self.closesWindowWithEscapeKey = closesWindowWithEscapeKey
		
		tabViewController = SettingsTabViewController()
		window = SettingsWindow(contentViewController: tabViewController)
		initialWindowSetup()
		
		tabViewController.set(panes: panes)
	}
	
	private var obs_NSApplication: NSObjectProtocol?
	deinit {
		if let obs_NSApplication {
			NotificationCenter.default.removeObserver(obs_NSApplication)
		}
	}
	
	
	// MARK: -
	
	private func initialWindowSetup() {
		shouldCascadeWindows = false
		windowFrameAutosaveName = Keys.lastWindowFrame
		
		// The macOS settings/preferences window is generally styled to apply basically only with a close button. The minimize button should be disabled in the design.
		// However, depending on a contents of a pane, resizing can be enabled as in Xcode.
		window?.styleMask = [
			.titled,
			.closable,
		]
		
		window?.titlebarSeparatorStyle = .automatic
		window?.toolbarStyle = .preference
		
		if let obs_NSApplication {
			NotificationCenter.default.removeObserver(obs_NSApplication)
		}
		
		// If window restoration is enabled, `showWindow(_:)` is not called by the system.
		// This is done to grab the first displaying of windows under the window restoration process.
		obs_NSApplication = NotificationCenter.default
			.addObserver(forName: NSApplication.didFinishRestoringWindowsNotification,
						 object: NSApp,
						 queue: .main,
						 using: { notif in
				self.resetBehaviors()
			})
	}
	
	private func resetBehaviors() {
		if window?.isVisible == true {
			// Update window title (also window menu item title, Dock tile title)
			tabViewController.updateWindowTitleWithSelectedTab()
			settingsWindow.setZoomButton()
		}
	}
	
	
	// MARK: -
	
	// This implementation does not use nib,
	// so `windowWillLoad()`, `windowDidLoad()` and `loadWindow()` are not called by the system
	
	open override func showWindow(_ sender: Any?) {
		super.showWindow(sender)
		
		// Try to restore the window frame with an autosave name. If that fails, set the window position to center.
		if centersWindowPositionAlways || window?.setFrameUsingName(windowFrameAutosaveName) == false {
			window?.center()
		}
		
		resetBehaviors()
	}
	
	/// Close window to press Escape key
	@objc public func cancel(_ sender: Any?) {
		// We can use the hidden method `cancel(_:)` to close the window with Escape key or Cmd-PERIOD pressing
		// Ref: https://web.archive.org/web/20120114031052/http://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSResponder_Class/Reference/Reference.html#//apple_ref/occ/instm/NSResponder/cancelOperation:
		if closesWindowWithEscapeKey {
			close()
		}
	}
	
	
	// MARK: -
	
	open func removeAutosavedWindowFrame() {
		NSWindow.removeFrame(usingName: Keys.lastWindowFrame)
	}
	
}
