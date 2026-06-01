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
	
	private static let defaultLoadingLabelText = "Loading…"
	
	/// Loading view displayed during tab transitions
	open var loadingView: NSView = {
		let view = NSView()
		view.autoresizingMask = [.width, .height]

		let label = NSTextField(labelWithString: defaultLoadingLabelText)
		label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
		label.textColor = .tertiaryLabelColor
		label.translatesAutoresizingMaskIntoConstraints = false
		label.identifier = .init("LoadingLabel")
		label.isHidden = true

		view.addSubview(label)
		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
		])

		return view
	}()

	/// Text displayed in the loading label
	open var loadingLabelText: String = defaultLoadingLabelText {
		didSet {
			(loadingView.subviews.first { $0.identifier == .init("LoadingLabel") } as? NSTextField)?.stringValue = loadingLabelText
		}
	}

	/// Show or hide the loading label in the loading view
	open var showsLoadingLabel: Bool = false {
		didSet {
			loadingView.subviews.first { $0.identifier == .init("LoadingLabel") }?.isHidden = !showsLoadingLabel
		}
	}

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

	/// Eagerly load all tab views. Call this explicitly if you want to pre-load all panes at once.
	open func loadAllTabs() {
		tabView.tabViewItems.forEach {
			if #available(macOS 14.0, *) {
				$0.viewController?.loadViewIfNeeded()
			}
			else {
				// Load views by accessing the view property
				_ = $0.viewController?.view
			}
		}
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
	
	open func insert(tabViewItem: NSTabViewItem, at index: Int) {
		if let vc = tabViewItem.viewController as? SettingsPaneViewController {
			vc.tabViewController = self
		}
		insertTabViewItem(tabViewItem, at: index)
	}
	
	private func makeTabViewItem(from pane: SettingsPaneViewController) -> NSTabViewItem {
		let item = NSTabViewItem(viewController: pane)
		updateTabName(of: item)
		item.image = pane.tabImage
		item.identifier = pane.tabIdentifier
		
		return item
	}
	
	
	// MARK: - Tab View and Transition
	
	open override func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
		// Block toolbar interactions during transitions
		if window?.isWindowResizing == true {
			return false
		}
		return super.tabView(tabView, shouldSelect: tabViewItem)
	}
	
	open override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, willSelect: tabViewItem)
		// Remove the resizable attribute from the window once
		window?.resetWindowBehavior()
	}
	
	/// Control transition of this tab view controller
	open override func transition(from fromViewController: NSViewController, to toViewController: NSViewController, options: NSViewController.TransitionOptions = [], completionHandler completion: (() -> Void)? = nil) {
		guard let superview = fromViewController.view.superview, let selectedTabViewItem
		else {
			completion?()
			return
		}

		// [Transition views A -> B with a blank view]
		// We need to insert a blank view during view transitions in order to correctly display implicit animations of an window frame and a toolbar.
		// Apparently mysterious artifacts on animations are related to the Auto Layout system.

		// 1. Set the loading view instead of current view (A)
		loadingView.frame = fromViewController.view.frame
		superview.replaceSubview(fromViewController.view, with: loadingView)

		let pane = toViewController as? SettingsPaneViewController

		let performTransition = { [weak self] in
			guard let self else {
				completion?()
				return
			}

			let animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

			// 2. Layout the destination view and capture its size
			self.cacheTabViewSize(for: selectedTabViewItem)

			// 3. Do window resizing process and animate
			self.fitWindowSize(to: selectedTabViewItem, animateIfPossible: animates) {
				// 4. The resize animation completed then, re-replace the blank view with the view (B) with a dissolve
				if animates {
					let transition = CATransition()
					transition.type = .fade
					transition.duration = 0.07
					transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
					superview.wantsLayer = true
					superview.layer?.add(transition, forKey: "paneDissolve")
				}

				superview.replaceSubview(self.loadingView, with: toViewController.view)
				
				// 5. Reset window title and behavior
				self.window?.setWindowTitle(with: selectedTabViewItem)
				self.setWindowBehavior(with: selectedTabViewItem)

				completion?()
			}
		}

		// Load pane content lazily if not yet loaded
		if let pane, !pane.isPaneContentLoaded {
			pane.loadPaneContent { [weak pane] in
				pane?.isPaneContentLoaded = true
				// Defer to next frame to separate layout calculation from animation
				DispatchQueue.main.async {
					performTransition()
				}
			}
		}
		else {
			performTransition()
		}
	}
	
	/// Layout the tab view item's view and cache its size
	open func cacheTabViewSize(for tabViewItem: NSTabViewItem) {
		guard let view = tabViewItem.view else { return }
		view.layoutSubtreeIfNeeded()
		let frameSize = view.frame.size
		if frameSize.width > 0 && frameSize.height > 0 {
			tabViewSizes[tabViewItem] = frameSize
		}
		else {
			let fittingSize = view.fittingSize
			if fittingSize.width > 0 && fittingSize.height > 0 {
				tabViewSizes[tabViewItem] = fittingSize
			}
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
	open func selectTab(with tabViewItem: NSTabViewItem, animateIfPossible: Bool, completion: (() -> Void)? = nil) {
		let pane = tabViewItem.settingsPaneViewController

		let doSelect = { [weak self] in
			guard let self else {
				completion?()
				return
			}
			self.cacheTabViewSize(for: tabViewItem)
			self.fitWindowSize(to: tabViewItem, animateIfPossible: animateIfPossible)
			self.updateWindowTitleWithSelectedTab()
			completion?()
		}

		if let pane, !pane.isPaneContentLoaded {
			pane.loadPaneContent { [weak pane] in
				pane?.isPaneContentLoaded = true
				doSelect()
			}
		}
		else {
			doSelect()
		}
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
				if #available(macOS 12, *) {
					item.label = String(localized: String.LocalizationValue(localizeKey))
				} else {
					item.label = NSLocalizedString(localizeKey, comment: "")
				}
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
