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
	
	/// Reference to SettingsWindowController
	open weak var windowController: SettingsWindowController?
	
	/// Reference to SettingsWindow (getter)
	open var window: SettingsWindow? {
		(view.window as? SettingsWindow)
	}
	
	/// If set to true, use pane’s `tabName` to set tab name
	open var disablesLocalizationWithTabNameLocalizeKey: Bool = false { didSet {
		updateTabNames()
	}}
	
	/// The safe version of `selectedTabViewItemIndex`
	open var selectedTabIndex: Int? {
		get {
			// When there is no TabViewItem in NSTabViewController, `selectedTabViewItemIndex` returns -1. This spec does not appear to be documented.
			if !tabViewItems.isEmpty && 0..<tabViewItems.count ~= selectedTabViewItemIndex {
				return selectedTabViewItemIndex
			}
			return nil
		}
		set {
			super.selectedTabViewItemIndex = newValue ?? 0
			if let selectedTabViewItem {
				selectTab(with: selectedTabViewItem, animateIfPossible: false)
			}
		}
	}
	
	/// Get the selected tab if it exist. (Only getter)
	open var selectedTabViewItem: NSTabViewItem? {
		if let selectedTabIndex {
			return tabViewItems[selectedTabIndex]
		}
		return nil
	}
	
	/// Get all panes
	open var panes: [SettingsPaneViewController] {
		tabViewItems.compactMap {
			$0.settingsPaneViewController
		}
	}
	
	/// Blank view for transition
	open var blankView = NSView()
	
	public private(set) var tabViewSizes: [NSTabViewItem: NSSize] = [:]
	
	
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
		
		if let selectedTabViewItem {
			selectTab(with: selectedTabViewItem, animateIfPossible: false)
		}
		
		// If a TabViewItem exists but is not selected, select #0. (Just in case)
		if !tabViewItems.isEmpty && selectedTabViewItem == nil {
			selectedTabViewItemIndex = 0
		}
	}
	
	
	// MARK: -
	
	open func set(panes: [SettingsPaneViewController]) {
		add(panes: panes)
		selectedTabIndex = 0
	}
	
	open func add(panes: [SettingsPaneViewController]) {
		panes.forEach {
			$0.tabViewController = self
			let item = makeTabViewItem(from: $0)
			addTabViewItem(item)
		}
	}
	
	open func insert(panes: [SettingsPaneViewController], at index: Int) {
		panes.reversed().forEach {
			$0.tabViewController = self
			let item = makeTabViewItem(from: $0)
			insertTabViewItem(item, at: index)
		}
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
	
	
	// MARK: - Tab View and Transition
	
	open override func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
		if window?.isWindowResizing == true {
			return false
		}
		return super.tabView(tabView, shouldSelect: tabViewItem)
	}
	
	open override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, willSelect: tabViewItem)
		
		if let tabViewItem, let view = tabViewItem.view {
			view.layoutSubtreeIfNeeded()
			let size = view.frame.size
			tabViewSizes[tabViewItem] = size
		}
		// Remove the resizable attribute from the window once
		window?.resetWindowBehavior()
	}
	
	/// Control transition of this tab view controller
	open override func transition(from fromViewController: NSViewController, to toViewController: NSViewController, options: NSViewController.TransitionOptions = [], completionHandler completion: (() -> Void)? = nil) {
		guard let superview = fromViewController.view.superview,  let selectedTabViewItem
		else {
			completion?()
			return
		}
		
		// Transition views A -> B
		
		// 1. First, replace current view (A) with blank view
		superview.replaceSubview(fromViewController.view, with: blankView)
		
		// 2. Do window resizing process
		fitWindowSize(to: selectedTabViewItem, animateIfPossible: true) {
			// 3. The resize animation completed then, replace blank view with the view (B)
			superview.replaceSubview(self.blankView, with: toViewController.view)
			
			// 4. Reset window title and behavior
			self.window?.setWindowTitle(with: selectedTabViewItem)
			self.setWindowBehavior(with: selectedTabViewItem)
			
			completion?()
		}
	}
	
	/// Fit window size to specific tab view item
	open func fitWindowSize(to tabViewItem: NSTabViewItem, animateIfPossible: Bool, completion: (() -> ())? = nil) {
		guard let size = tabViewSizes[tabViewItem], let window else {
			completion?()
			return
		}
		
		window.setWindowSize(size, animateIfPossible: animateIfPossible, completion: completion)
	}
	
	
	// MARK: -
	
	/// Select tab, fit window size and update window title
	open func selectTab(with tabViewItem: NSTabViewItem, animateIfPossible: Bool) {
		fitWindowSize(to: tabViewItem, animateIfPossible: animateIfPossible)
		updateWindowTitleWithSelectedTab()
	}
	
	/// Update window title on title bar, window menu item on the menu bar and Dock tile title
	open func updateWindowTitleWithSelectedTab() {
		window?.setWindowTitle(with: selectedTabViewItem)
	}
	
	/// Reflect the resizable attribute of the selected tab item to the window
	private func setWindowBehavior(with tabViewItem: NSTabViewItem) {
		if tabViewItem.settingsPaneViewController?.isResizableView == true {
			window?.addResizableBehavior()
		}
		else {
			window?.resetWindowBehavior()
		}
	}
	
	/// Update tab name with NSTabViewItem
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
	
	/// Update tab names
	private func updateTabNames() {
		tabViewItems.forEach { item in
			updateTabName(of: item)
		}
	}
	
}
