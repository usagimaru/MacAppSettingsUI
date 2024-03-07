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
	
	public var tabViewController: SettingsTabViewController? {
		contentViewController as? SettingsTabViewController
	}
	
	public class func windowController(with panes: [SettingsPaneViewController]? = nil) -> Self {
		let wc = NSStoryboard(name: Self.storyboardName, bundle: Bundle(identifier: "MacAppSettingsUI")).instantiateController(withIdentifier: "\(Self.self)") as! Self
		
		panes?.forEach({
			wc.tabViewController?.add(pane: $0)
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
