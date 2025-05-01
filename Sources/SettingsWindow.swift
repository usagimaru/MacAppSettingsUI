//
//  SettingsWindow.swift
//
//  Created by usagimaru on 2024/03/11.
//

import Cocoa

open class SettingsWindow: NSWindow {
	
	/// The standard window title. It’s used for the title on the window menu. Localize if necessary.
	open var defaultWindowTitle: String = "Settings"
	
	/// If set to false, disables fitting animation
	open var fittingAnimationEnabled: Bool = true
	
	/// Get “Reduce Motion” accessibility setting
	open var reduceMotionIfNeeded: Bool {
		NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
	}
	
	/// Notify true when window is resizing
	open private(set) var isWindowResizing: Bool = false
	
	
	// MARK: -
	
	public required convenience init(with contentViewController: NSTabViewController) {
		self.init(contentViewController: contentViewController)
	}
	
	/// Set default window behavior (It does not include the resizable attribute)
	open func resetWindowBehavior() {
		styleMask.insert([.titled, .closable])
		styleMask.remove(.resizable)
	}
	
	/// Add resizable window behavior
	open func addResizableBehavior() {
		styleMask.insert(.resizable)
	}
	
	/// Enable the traditional zoom button (green and plus icon) instead of the full screen button
	open func setZoomButton() {
		collectionBehavior = .fullScreenAuxiliary
	}
	
	open override func makeKeyAndOrderFront(_ sender: Any?) {
		setZoomButton()
		super.makeKeyAndOrderFront(sender)
	}
	
	/// Set window title in the window menu and Dock tile title
	open func setWindowTitle(with tabViewItem: NSTabViewItem?) {
		title = tabViewItem?.label ?? defaultWindowTitle
		
		var windowTitle: String {
			if let tabTitle = tabViewItem?.label {
				"\(defaultWindowTitle) — \(tabTitle)"
			}
			else {
				defaultWindowTitle
			}
		}
		
		// Change the title of the window menu item on Window menu if it is visible
		if isVisible {
			NSApp.changeWindowsItem(self, title: windowTitle, filename: false)
		}
		else {
			NSApp.removeWindowsItem(self)
		}
		
		// Set Dock tile title.
		// It makes little sense because minimization is basically disabled.
		miniwindowTitle = windowTitle
	}
	
	/// Set fitting size to window
	/// - Parameters:
	///   - size: Window size
	///   - customEasingFunction: Set custom easing function if you want. Override `animationResizeTime(_:)` if you want to change the duration too.
	///   - animateIfPossible: true: Animate resizing if possible
	///   - completion: Completion callback
	open func setWindowSize(_  size: NSSize,
							customEasingFunction: CAMediaTimingFunction? = nil,
							animateIfPossible: Bool,
							completion: (() -> ())? = nil)
	{
		// Based on: https://gist.github.com/ThatsJustCheesy/8148106fa7269326162d473408d3f75a
		
		let contentFrame = frameRect(forContentRect: .init(origin: .zero, size: size))
		let heightDiff = frame.height - contentFrame.height
		let newOrigin = NSPoint(x: frame.origin.x, y: frame.origin.y + heightDiff)
		let newFrame = NSRect(origin: newOrigin, size: contentFrame.size)
		
		func postprocess() {
			isWindowResizing = false
			completion?()
		}
		
		if animateIfPossible && fittingAnimationEnabled && !reduceMotionIfNeeded {
			isWindowResizing = true
			
			NSAnimationContext.runAnimationGroup { ctx in
				ctx.allowsImplicitAnimation = true
				ctx.duration = animationResizeTime(newFrame)
				if let customEasingFunction {
					ctx.timingFunction = customEasingFunction
				}
				
				setFrame(newFrame, display: true)
			} completionHandler: {
				postprocess()
			}
		}
		else {
			setFrame(newFrame, display: true)
			postprocess()
		}
	}
	
	
	// MARK: -
	
	open override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		switch menuItem.action {
			case
				#selector(toggleToolbarShown(_:)),
				#selector(runToolbarCustomizationPalette(_:)):
				// Disable `toggleToolbarShown(_:)` menu item and toolbar customization
				return false
				
			case _:
				return true
		}
	}
	
}
