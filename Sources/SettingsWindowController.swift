//
//  PreferencesWindowController.swift
//
//  Created by usagimaru on 2022/03/26.
//

import Cocoa

open class SettingsWindowController: NSWindowController {
	
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
	
	public var tabViewController: SettingsTabViewController! { didSet {
		tabViewController.windowController = self
	}}
	
	public override var shouldCascadeWindows: Bool {
		// When if use `windowFrameAutosaveName`, We have to disable `shouldCascadeWindows`
		// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/WinPanel/Tasks/SavingWindowPosition.html
		get { false }
		set { super.shouldCascadeWindows = false }
	}
	
	private var observationForNSWorkspace: NSObjectProtocol?
	private var observationForNSApplication: NSObjectProtocol?
	
	
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
		initialSetup()
		
		panes.forEach({
			tabViewController.add(pane: $0)
		})
	}
	
	deinit {
		if let observationForNSWorkspace {
			NSWorkspace.shared.notificationCenter.removeObserver(observationForNSWorkspace)
		}
		if let observationForNSApplication {
			NotificationCenter.default.removeObserver(observationForNSApplication)
		}
	}
	
	/// Insert `General` pane to the first position
	@discardableResult public func addGeneralPane(tabName: String? = "General",
												  localizeKeyForTabName: String?,
												  tabIdentifier: String = "General",
												  isResizableView: Bool) -> SettingsPaneViewController {
		
		let pane = SettingsPaneViewController(tabName: tabName,
											  localizeKeyForTabName: localizeKeyForTabName,
											  tabImage: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil),
											  tabIdentifier: tabIdentifier,
											  isResizableView: isResizableView)
		tabViewController.insert(pane: pane, at: 0)
		tabViewController.selectedTabViewItemIndex = 0
		
		return pane
	}
	
	/// Insert `Advanced` pane to the last position
	@discardableResult public func addAdvancedPane(tabName: String? = "Advanced",
												   localizeKeyForTabName: String?,
												   tabIdentifier: String = "Advanced",
												   isResizableView: Bool) -> SettingsPaneViewController {
		
		let pane = SettingsPaneViewController(tabName: tabName,
											  localizeKeyForTabName: localizeKeyForTabName,
											  tabImage: NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: nil),
											  tabIdentifier: tabIdentifier,
											  isResizableView: isResizableView)
		tabViewController.add(pane: pane)
		
		return pane
	}
	
	
	// MARK: -
	
	private func initialSetup() {
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
				self.resetBehaviors()
			}
		
		// If window restoration is enabled, `showWindow(_:)` is not called by the system.
		// This is done to grab the first displaying of windows under the window restoration process.
		observationForNSApplication = NotificationCenter.default
			.addObserver(forName: NSApplication.didFinishRestoringWindowsNotification,
						 object: NSApp,
						 queue: .main,
						 using: { notif in
				self.resetBehaviors()
			})
	}
	
	private func resetBehaviors() {
		// Enable the traditional zoom button (green and plus icon) instead of the full screen button
		window?.collectionBehavior = .fullScreenAuxiliary
		// Reflects “Reduce Motion” setting on System Settings
		tabViewController?.disablesAnimationOfTabSwitching = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
		
		if window?.isVisible == true {
			// Update window title (also window menu item title, Dock tile title)
			tabViewController.updateWindowTitleWithCurrentTab()
		}
	}
	
	
	// MARK: -
	
	// This implementation does not use nib,
	// so `windowWillLoad()`, `windowDidLoad()` and `loadWindow()` are not called by the system
	
	open override func windowDidLoad() {
		super.windowDidLoad()
	}
	
	open override func showWindow(_ sender: Any?) {
		super.showWindow(sender)
		
		// Try to restore the window frame with an autosave name. If that fails, set the window position to center.
		if centersWindowPositionAlways || window?.setFrameUsingName(windowFrameAutosaveName) == false {
			window?.center()
		}
		
		resetBehaviors()
	}
	
	/// Close window to press Escape key
	@objc open func cancel(_ sender: Any?) {
		// We can use the hidden method `cancel(_:)` to close the window with Escape key or Cmd-PERIOD pressing
		// Ref: https://web.archive.org/web/20120114031052/http://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSResponder_Class/Reference/Reference.html#//apple_ref/occ/instm/NSResponder/cancelOperation:
		if closesWindowWithEscapeKey {
			close()
		}
	}
	
	
	// MARK: -
	
	public func removeAutosavedWindowFrame() {
		NSWindow.removeFrame(usingName: Keys.lastWindowFrame)
	}
	
}
