//
//  SettingsTabViewController.swift
//
//  Created by usagimaru on 2022/03/27.

import Cocoa

public extension NSTabViewItem {
	
	var settingsPaneViewController: SettingsPaneViewController? {
		viewController as? SettingsPaneViewController
	}
	
}

open class SettingsTabViewController: NSTabViewController {
	
	open weak var windowController: SettingsWindowController?
	
	/// This is the standard window title when none of the tabs exist. Localize if necessary.
	/// You should not realistically care about this property, as there can be no situation where there are zero tabs in the settings window.
	open var defaultWindowTitle: String = "Settings"
	
	/// If set to true, disables animation
	open var disablesAnimationOfTabSwitching: Bool = false
	
	/// If set to true, use pane’s `tabName` to set tab name
	open var disablesLocalizationWithTabNameLocalizeKey: Bool = false { didSet {
		updateTabNames()
	}}
	
	/// The safe version of `selectedTabViewItemIndex`. (Only getter)
	public var selectedTabIndex: Int? {
		// When there is no TabViewItem in NSTabViewController, `selectedTabViewItemIndex` returns -1. This spec does not appear to be documented.
		if !tabViewItems.isEmpty && 0..<tabViewItems.count ~= selectedTabViewItemIndex {
			return selectedTabViewItemIndex
		}
		return nil
	}
	
	/// Get the selected tab if it exist. (Only getter)
	public var selectedTabViewItem: NSTabViewItem? {
		if let selectedTabIndex {
			return tabViewItems[selectedTabIndex]
		}
		return nil
	}
	
	private var tabViewSizes: [NSTabViewItem: NSSize] = [:]
	
	
	// MARK: -
	
	open override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do not automatically set the active pane’s title to window title
		// To delay window title refresh time and to manually control
		canPropagateSelectedChildViewControllerTitle = false
		
		// Set tab style as `toolbar`
		tabStyle = .toolbar
	}
	
	open override func viewWillAppear() {
		super.viewWillAppear()
		
		// If a TabViewItem exists but is not selected, select #0. (Just in case)
		if selectedTabViewItem == nil && !tabViewItems.isEmpty {
			selectedTabViewItemIndex = 0
		}
		
		fitWindowSizeToSelectedTabViewItem()
		setWindowTitle(with: selectedTabViewItem)
	}
	
	
	// MARK: -
	
	open func set(panes: [SettingsPaneViewController]) {
		panes.forEach {
			add(pane: $0)
		}
	}
	
	open func add(pane: SettingsPaneViewController) {
		pane.tabViewController = self
		let item = makeTabViewItem(from: pane)
		addTabViewItem(item)
	}
	
	open func insert(pane: SettingsPaneViewController, at index: Int) {
		pane.tabViewController = self
		let item = makeTabViewItem(from: pane)
		insertTabViewItem(item, at: index)
	}
	
	private func makeTabViewItem(from pane: SettingsPaneViewController) -> NSTabViewItem {
		let item = NSTabViewItem(viewController: pane)
		updateTabName(of: item)
		item.image = pane.tabImage
		item.identifier = pane.tabIdentifier
		
		return item
	}
	
	open func insert(tabViewItem: NSTabViewItem, at index: Int) {
		if let vc = tabViewItem.viewController as? SettingsPaneViewController {
			vc.tabViewController = self
		}
		insertTabViewItem(tabViewItem, at: index)
	}
	
	
	// MARK: -
	
	open override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, willSelect: tabViewItem)
		
		if let tabViewItem, let view = tabViewItem.view {
			view.layoutSubtreeIfNeeded()
			let size = view.frame.size
			tabViewSizes[tabViewItem] = size
		}
		// Remove the resizable attribute from the window once
		setDefaultWindowBehavior()
	}
	
	open override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, didSelect: tabViewItem)
		
		if let tabViewItem {
			fitWindowSize(to: tabViewItem, animated: true)
		}
	}
	
	// 参考：https://gist.github.com/ThatsJustCheesy/8148106fa7269326162d473408d3f75a
	
	public func fitWindowSize(to tabViewItem: NSTabViewItem, animated: Bool) {
		guard let size = tabViewSizes[tabViewItem], let window = view.window else {
			return
		}
		
		let contentRect = NSRect(origin: .zero, size: size)
		let contentFrame = window.frameRect(forContentRect: contentRect)
		let toolbarHeight = window.frame.size.height - contentFrame.size.height
		let newOrigin = NSPoint(x: window.frame.origin.x, y: window.frame.origin.y + toolbarHeight)
		let newFrame = NSRect(origin: newOrigin, size: contentFrame.size)
		
		func postprocess() {
			// The design intent is to refresh the window title after the pane is switched.
			setWindowTitle(with: tabViewItem)
			
			// Reflect the resizable attribute
			if let pane = tabViewItem.settingsPaneViewController {
				setWindowBehavior(with: pane)
			}
		}
		
		if animated && !disablesAnimationOfTabSwitching {
			// It looks uncool when tab switching, so it is temporarily hidden until the animation is finished.
			// Since the use of the `isHidden` attribute would affect the view frame, I adopted a policy of controlling the `alphaValue`.
			self.view.alphaValue = 0
			
			NSAnimationContext.runAnimationGroup { context in
				context.duration = CATransaction.animationDuration()
				window.animator().setFrame(newFrame, display: false)
				
			} completionHandler: {
				self.view.alphaValue = 1
				postprocess()
			}
		}
		else {
			window.setFrame(newFrame, display: false)
			postprocess()
		}
	}
	
	/// Update window size to fit to the selected tab view item’s view frame
	public func fitWindowSizeToSelectedTabViewItem() {
		if let selectedTabViewItem {
			fitWindowSize(to: selectedTabViewItem, animated: false)
		}
	}
	
	/// Reflect `NSTabViewItem.label` or `defaultWindowTitle` to the window
	private func setWindowTitle(with tabViewItem: NSTabViewItem?) {
		view.window?.title = tabViewItem?.label ?? defaultWindowTitle
	}
	
	/// Reflect the resizable attribute of the selected pane to the window
	private func setWindowBehavior(with pane: SettingsPaneViewController) {
		if pane.isResizableView {
			view.window?.styleMask.insert(.resizable)
		}
		else {
			setDefaultWindowBehavior()
		}
	}
	
	/// Set default window behavior (It does not include the resizable attribute)
	private func setDefaultWindowBehavior() {
		view.window?.styleMask.remove(.resizable)
	}
	
	private func updateTabName(of item: NSTabViewItem) {
		if let pane = item.settingsPaneViewController {
			if let localizeKey = pane.localizeKeyForTabName, !localizeKey.isEmpty && !disablesLocalizationWithTabNameLocalizeKey {
				item.label = NSLocalizedString(localizeKey, comment: "")
			}
			else {
				item.label = pane.tabName ?? ""
			}
		}
	}
	
	private func updateTabNames() {
		tabViewItems.forEach { item in
			updateTabName(of: item)
		}
	}
	
}
