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
	
	public var tabViewController: SettingsTabViewController! { didSet {
		tabViewController.windowController = self
	}}
	
	public override var shouldCascadeWindows: Bool {
		get { false }
		set { super.shouldCascadeWindows = false }
	}
	
	private var observationForNSWorkspace: NSObjectProtocol?
	private var observationForNSApplication: NSObjectProtocol?
	
	
	// MARK: -
	
	/// Initializer
	required convenience public init(with panes: [SettingsPaneViewController]? = nil,
									 centersWindowPositionAlways: Bool = false,
									 closesWindowWithEscapeKey: Bool = true) {
		
		self.init()
		
		self.centersWindowPositionAlways = centersWindowPositionAlways
		self.closesWindowWithEscapeKey = closesWindowWithEscapeKey
		
		tabViewController = SettingsTabViewController()
		window = NSWindow.settingsWindow(contentViewController: tabViewController)
		initialSetup()
		
		panes?.forEach({
			tabViewController.add(pane: $0)
		})
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
		// When if use `windowFrameAutosaveName`, We have to disable `shouldCascadeWindows`
		// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/WinPanel/Tasks/SavingWindowPosition.html
		shouldCascadeWindows = false
		windowFrameAutosaveName = Keys.lastWindowFrame
		
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
		
		// If window restoration is enabled, `showWindow(_:)` are not called by the system.
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
	
	
	// MARK: -
	
	// `windowWillLoad()`, `windowDidLoad()` and `loadWindow()` are not called by the system because this class is not owned by any nib / storyboard file.
	
	open override func showWindow(_ sender: Any?) {
		super.showWindow(sender)
		
		// Try to restore the window frame with an autosave name. If that fails, set the window position to center.
		if centersWindowPositionAlways || window?.setFrameUsingName(windowFrameAutosaveName) == false {
			window?.center()
		}
		
		setupBehaviors()
	}
	
	/// Close window to press Escape key
	@objc open func cancel(_ sender: Any?) {
		if closesWindowWithEscapeKey {
			close()
		}
	}
	
	
	// MARK: -
	
	func removeAutosavedWindowFrame() {
		NSWindow.removeFrame(usingName: Keys.lastWindowFrame)
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
