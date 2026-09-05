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
		
		/// UserDefaults key for the tab identifier stored by `restoresLastSelectedTab`
		static let lastSelectedTabIdentifier = "\(SettingsWindowController.self).lastSelectedTabIdentifier"
	}
	
	/// Set window position to center of the screen
	open var centersWindowPositionAlways: Bool!
	
	/// Do not want to close window with Escape key, set this flag to false
	open var closesWindowWithEscapeKey: Bool!
	
	/// Opt in to restoring the tab that was selected last. Matched by identifier, not by index
	open var restoresLastSelectedTab: Bool = false

	/// Called once the window has closed. Releasing this controller here is safe, and the panes are rebuilt on the next open
	open var windowCloseHandler: (() -> Void)?
	
	/// The identifier of the tab that was selected last
	open var lastSelectedTabIdentifier: String? {
		get {
			UserDefaults.standard.string(forKey: Keys.lastSelectedTabIdentifier)
		}
		set {
			if let newValue {
				UserDefaults.standard.set(newValue, forKey: Keys.lastSelectedTabIdentifier)
			}
			else {
				UserDefaults.standard.removeObject(forKey: Keys.lastSelectedTabIdentifier)
			}
		}
	}
	
	/// Guard against the selections made while the panes are still being assembled
	private var canStoreSelectedTabIdentifier = false
	
	/// Get the window menu item for this window
	open var windowMenuItem: NSMenuItem? {
		NSApp.windowsMenu?.items.filter {
			window != nil
			&& ($0.target as? NSWindow) == window
			&& $0.action == #selector(NSWindow.makeKeyAndOrderFront(_:))
		}.first
	}
	
	open var tabViewController: SettingsTabViewController! { didSet {
		tabViewController.settingsWindowController = self
	}}
	
	open var settingsWindow: SettingsWindow {
		window as! SettingsWindow
	}
	
	open override var shouldCascadeWindows: Bool {
		// Cascading has to stay off while the window frame is autosaved
		// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/WinPanel/Tasks/SavingWindowPosition.html
		get { false }
		set { super.shouldCascadeWindows = false }
	}
	
	
	// MARK: -
	
	required convenience public init(with panes: [SettingsPaneViewController],
									 centersWindowPositionAlways: Bool = false,
									 closesWindowWithEscapeKey: Bool = true) {
		
		self.init()
		
		self.centersWindowPositionAlways = centersWindowPositionAlways
		self.closesWindowWithEscapeKey = closesWindowWithEscapeKey
		
		tabViewController = SettingsTabViewController()
		// Linked by hand, because an observer does not fire for an assignment made inside an initializer
		tabViewController.settingsWindowController = self
		
		window = SettingsWindow(contentViewController: tabViewController)
		initialWindowSetup()
		
		tabViewController.set(panes: panes)
	}
	
	private var obs_NSApplication: NSObjectProtocol?
	private var windowWillCloseObserver: NSObjectProtocol?
	deinit {
		if let obs_NSApplication {
			NotificationCenter.default.removeObserver(obs_NSApplication)
		}
		if let windowWillCloseObserver {
			NotificationCenter.default.removeObserver(windowWillCloseObserver)
		}
	}
	
	
	// MARK: -
	
	private func initialWindowSetup() {
		shouldCascadeWindows = false
		windowFrameAutosaveName = Keys.lastWindowFrame
		
		// A settings window carries only a close button by design. Resizing is opted in per pane, as in Xcode
		window?.styleMask = [
			.titled,
			.closable,
		]
		
		window?.titlebarSeparatorStyle = .automatic
		window?.toolbarStyle = .preference
		
		if let obs_NSApplication {
			NotificationCenter.default.removeObserver(obs_NSApplication)
		}
		
		// Window restoration shows the window without asking this controller, so the first display is caught here
		obs_NSApplication = NotificationCenter.default
			.addObserver(forName: NSApplication.didFinishRestoringWindowsNotification,
						 object: NSApp,
						 queue: .main,
						 using: { [weak self] notif in
				self?.restoreLastSelectedTabIfNeeded()
				self?.resetBehaviors()
			})

		if let windowWillCloseObserver {
			NotificationCenter.default.removeObserver(windowWillCloseObserver)
		}

		guard let window else { return }

		windowWillCloseObserver = NotificationCenter.default
			.addObserver(forName: NSWindow.willCloseNotification,
						 object: window,
						 queue: .main,
						 using: { [weak self] _ in
				// Deferred past the close itself, or the handler could release the window mid-close
				DispatchQueue.main.async {
					// Held locally, so it survives releasing this controller
					guard let handler = self?.windowCloseHandler else { return }
					handler()
				}
			})
	}
	
	private func resetBehaviors() {
		if window?.isVisible == true {
			tabViewController.updateWindowTitleWithSelectedTab()
			settingsWindow.setZoomButton()
		}
	}
	
	
	// MARK: -
	
	// No nib is used here, so the nib loading callbacks are never called by the system

	open override func showWindow(_ sender: Any?) {
		// Restored ahead of the first appearance, so the stored tab is the one that shows up
		restoreLastSelectedTabIfNeeded()

		super.showWindow(sender)

		// Centered when the autosaved position cannot be restored
		if centersWindowPositionAlways || !restoreWindowPosition() {
			window?.center()
		}

		resetBehaviors()
	}

	/// Move the window back to where it was left, keeping the size the pane decided
	private func restoreWindowPosition() -> Bool {
		guard let window else { return false }

		let contentSize = window.contentRect(forFrameRect: window.frame).size
		guard window.setFrameUsingName(windowFrameAutosaveName) else { return false }

		// The autosaved frame carries the old size with it, but the size belongs to the pane
		settingsWindow.setWindowSize(contentSize, animateIfPossible: false)

		return true
	}

	/// Store the window frame where it stands
	open func storeWindowFrame() {
		guard let window, !windowFrameAutosaveName.isEmpty else { return }

		window.saveFrame(usingName: windowFrameAutosaveName)
	}

	/// Close the window on the Escape key or Cmd-Period, through a hidden responder action
	/// Ref: https://web.archive.org/web/20140603045053/http://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSResponder_Class/Reference/Reference.html#//apple_ref/occ/instm/NSResponder/cancelOperation:
	@objc open func cancel(_ sender: Any?) {
		if closesWindowWithEscapeKey {
			close()
		}
	}
	
	
	// MARK: - Selected tab restoration
	
	/// Select the stored tab. The first tab stands in when the identifier is missing or no longer matches any tab
	open func restoreLastSelectedTab() {
		tabViewController?.selectTab(withIdentifier: lastSelectedTabIdentifier)
	}
	
	/// Store the current selection. Called by `SettingsTabViewController` whenever the selected tab changes
	open func storeSelectedTabIdentifier() {
		// Nothing is written for an app that did not opt in, so its defaults stay untouched
		guard restoresLastSelectedTab, canStoreSelectedTabIdentifier,
			  let identifier = tabViewController?.selectedTabIdentifier
		else { return }
		
		lastSelectedTabIdentifier = identifier
	}
	
	private func restoreLastSelectedTabIfNeeded() {
		guard !canStoreSelectedTabIdentifier else { return }
		
		if restoresLastSelectedTab {
			restoreLastSelectedTab()
		}
		
		// Selections from here on belong to the user, so they are the ones worth storing
		canStoreSelectedTabIdentifier = true
	}
	
	
	// MARK: -
	
	open func removeAutosavedWindowFrame() {
		Self.removeAutosavedWindowFrame()
	}
	
	open func removeStoredSelectedTabIdentifier() {
		Self.removeStoredSelectedTabIdentifier()
	}
	
	open class func removeAutosavedWindowFrame() {
		NSWindow.removeFrame(usingName: Keys.lastWindowFrame)
	}
	
	/// Usable without an instance, so a released window controller does not block the cleanup
	open class func removeStoredSelectedTabIdentifier() {
		UserDefaults.standard.removeObject(forKey: Keys.lastSelectedTabIdentifier)
	}
	
}
