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
	
	open weak var settingsWindowController: SettingsWindowController?

	open var settingsWindow: SettingsWindow? {
		(view.window as? SettingsWindow)
	}

	/// If set to true, the tab name comes from the pane itself rather than from its localization key
	open var disablesLocalizationWithTabNameLocalizeKey: Bool = false { didSet {
		updateTabNames()
	}}
	
	/// The safe version of `selectedTabViewItemIndex`
	open var selectedTabIndex: Int? {
		get {
			// `selectedTabViewItemIndex` returns -1 while there is no tab view item. Undocumented behavior
			if !tabViewItems.isEmpty && 0..<tabViewItems.count ~= selectedTabViewItemIndex {
				return selectedTabViewItemIndex
			}
			return nil
		}
		set {
			selectedTabViewItemIndex = newValue ?? 0
			if let selectedTabViewItem {
				selectTab(with: selectedTabViewItem, animateIfPossible: false)
			}
		}
	}
	
	open var selectedTabViewItem: NSTabViewItem? {
		if let selectedTabIndex {
			return tabViewItems[selectedTabIndex]
		}
		return nil
	}
	
	/// The identifier of the selected tab, carried over from the pane’s `tabIdentifier`
	open var selectedTabIdentifier: String? {
		selectedTabViewItem?.identifier as? String
	}
	
	open var panes: [SettingsPaneViewController] {
		tabViewItems.compactMap {
			$0.settingsPaneViewController
		}
	}
	
	private static let defaultLoadingLabelText = "Loading…"
	private static let defaultLabelIdentifier = NSUserInterfaceItemIdentifier("LoadingLabel")

	/// Loading view displayed during tab transitions
	open var loadingView: NSView = {
		let view = NSView()
		view.autoresizingMask = [.width, .height]
		
		let label = NSTextField(labelWithString: defaultLoadingLabelText)
		label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
		label.textColor = .tertiaryLabelColor
		label.translatesAutoresizingMaskIntoConstraints = false
		label.identifier = defaultLabelIdentifier
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
			(loadingView.subviews.first { $0.identifier == Self.defaultLabelIdentifier } as? NSTextField)?.stringValue = loadingLabelText
		}
	}
	
	/// Show or hide the loading label in the loading view
	open var showsLoadingLabel: Bool = false {
		didSet {
			updateLoadingLabelVisibility()
		}
	}
	
	/// Show the loading label while the loading view stands in
	open var showsLoadingLabelWhileLoading: Bool = true

	/// Fallback size for a pane that declares none
	open var defaultPaneSize = NSSize(width: 500, height: 400)

	/// If set to false, disables the dissolve that reveals a pane
	open var paneDissolveAnimationEnabled: Bool = true

	/// Duration of the dissolve that reveals a pane
	open var paneDissolveDuration: CFTimeInterval = 0.08

	/// Custom timing function for the dissolve. nil uses the default
	open var animationTimingFunctionForPaneDissolve: CAMediaTimingFunction?

	/// Clamp all pane widths to the minimum content width the toolbar imposes, avoiding flicker on narrower panes
	open var clampsToToolbarMinimumWidth: Bool = true
	
	public private(set) var tabViewSizes: [NSTabViewItem: NSSize] = [:]
	
	/// Sizes the user left each resizable pane at. Kept only while the app runs
	public private(set) var userResizedSizes: [NSTabViewItem: NSSize] = [:]
	
	/// The width the toolbar refuses to go below, learned when the system clamps a resize
	private var minimumContentWidth: CGFloat = 0
	
	private var windowDidResizeObserver: NSObjectProtocol?
	
	/// Waiters per pane. A key present means the load is in flight
	private var pendingLoadCompletions = [SettingsPaneViewController: [() -> Void]]()

	/// The load in flight per pane
	private var loadTasks = [SettingsPaneViewController: Task<Void, Never>]()
	
	/// The tab a presentation is running for. Selecting it again is turned away
	private var presentingTabViewItem: NSTabViewItem?
	
	/// False until the first appearance
	private var hasViewAppeared = false

	
	// MARK: -
	
	open override func viewDidLoad() {
		super.viewDidLoad()
		
		// Refreshed by hand later, so the window title does not change ahead of the pane
		canPropagateSelectedChildViewControllerTitle = false
		
		tabStyle = .toolbar
	}
	
	deinit {
		if let windowDidResizeObserver {
			NotificationCenter.default.removeObserver(windowDidResizeObserver)
		}

		// A load in flight would otherwise outlive this controller
		loadTasks.values.forEach { $0.cancel() }
	}
	
	/// Eagerly load every tab view. Call it to pre-load all panes at once
	open func loadAllTabs() {
		tabView.tabViewItems.forEach {
			if #available(macOS 14.0, *) {
				$0.viewController?.loadViewIfNeeded()
			}
			else {
				_ = $0.viewController?.view
			}
		}
	}
	
	open override func viewWillAppear() {
		super.viewWillAppear()
		
		if let selectedTabViewItem {
			selectTab(with: selectedTabViewItem, animateIfPossible: false)
		}
		
		// Just in case nothing ended up selected
		if !tabViewItems.isEmpty && selectedTabViewItem == nil {
			selectedTabViewItemIndex = 0
		}
	}
	
	open override func viewDidAppear() {
		super.viewDidAppear()
		hasViewAppeared = true
		startObservingWindowResize()
	}
	
	
	// MARK: - Pane size memory
	
	private func startObservingWindowResize() {
		guard windowDidResizeObserver == nil, let settingsWindow else { return }
		
		windowDidResizeObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification,
																		 object: settingsWindow,
																		 queue: .main)
		{ [weak self] _ in
			self?.recordUserResizedSize()
		}
	}
	
	/// Keep the size the user dragged the window to. Sizes applied on tab switching are skipped
	private func recordUserResizedSize() {
		// The notification arrives a turn late, so an uncached pane still shows another pane’s frame
		guard let settingsWindow, !settingsWindow.isWindowResizing,
			  let tabViewItem = selectedTabViewItem,
			  tabViewItem.settingsPaneViewController?.isResizableView == true,
			  let contentSize = settingsWindow.contentView?.frame.size,
			  let cachedSize = tabViewSizes[tabViewItem],
			  contentSize != cachedSize
		else { return }
		
		userResizedSizes[tabViewItem] = contentSize
		tabViewSizes[tabViewItem] = contentSize
	}
	
	/// Keep the size a pane settled on, and store the frame so the next run opens at it
	private func recordSettledWindowSize(for tabViewItem: NSTabViewItem) {
		if let contentSize = settingsWindow?.contentView?.frame.size,
		   contentSize.width > 0, contentSize.height > 0 {
			tabViewSizes[tabViewItem] = contentSize
		}

		settingsWindowController?.storeWindowFrame()
	}

	/// The size the user last left this pane at
	open func userResizedSize(for pane: SettingsPaneViewController) -> NSSize? {
		guard let tabViewItem = tabViewItems.first(where: { $0.viewController === pane }) else { return nil }
		return userResizedSizes[tabViewItem]
	}
	
	/// Restore a size recorded earlier. Pass nil to forget it
	open func setUserResizedSize(_ size: NSSize?, for pane: SettingsPaneViewController) {
		guard let tabViewItem = tabViewItems.first(where: { $0.viewController === pane }) else { return }
		
		userResizedSizes[tabViewItem] = size
		cacheTabViewSize(for: tabViewItem)
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

	open override func removeTabViewItem(_ tabViewItem: NSTabViewItem) {
		// Cleared here, or the caches would keep the item and its pane alive
		tabViewSizes[tabViewItem] = nil
		userResizedSizes[tabViewItem] = nil

		var orphanedWaiters = [() -> Void]()
		if let pane = tabViewItem.settingsPaneViewController {
			orphanedWaiters = pendingLoadCompletions.removeValue(forKey: pane) ?? []
			loadTasks.removeValue(forKey: pane)?.cancel()
		}

		super.removeTabViewItem(tabViewItem)
		updateLoadingLabelVisibility()
		orphanedWaiters.forEach { $0() }
	}
	
	private func makeTabViewItem(from pane: SettingsPaneViewController) -> NSTabViewItem {
		let item = NSTabViewItem(viewController: pane)
		updateTabName(of: item)
		item.image = pane.tabImage
		item.identifier = pane.tabIdentifier
		
		return item
	}
	
	
	// MARK: - Pane content loading
	
	/// Load the pane content once and let every caller wait on it
	open func loadContentIfNeeded(for pane: SettingsPaneViewController, completion: @escaping () -> Void) {
		if pane.isPaneContentLoaded {
			completion()
			return
		}

		// A load in flight is waited on even once cancelled, or the content would be built twice
		if loadTasks[pane] != nil {
			pendingLoadCompletions[pane, default: []].append(completion)
			return
		}

		pendingLoadCompletions[pane, default: []].append(completion)
		updateLoadingLabelVisibility()

		loadTasks[pane] = Task { [weak self, weak pane] in
			guard let pane else { return }

			do {
				try await pane.loadPaneContent()

				// Recorded even for a cancelled load, since returning means the content is built
				pane.isPaneContentLoaded = true
				pane.paneContentDidLoad()
				self?.finishLoad(of: pane, retriesWaiters: false)
			}
			catch {
				// Cancellation is not a failure, and whoever asked meanwhile is owed another attempt
				if !Task.isCancelled {
					pane.paneContentDidFailToLoad(error)
				}
				self?.finishLoad(of: pane, retriesWaiters: Task.isCancelled)
			}
		}
	}
	
	/// Tell every pane the user has left that its load is no longer wanted
	private func cancelPendingLoads(except pane: SettingsPaneViewController?) {
		let abandoned = pendingLoadCompletions.keys.filter { $0 !== pane }
		guard !abandoned.isEmpty else { return }

		abandoned.forEach {
			let waiters = pendingLoadCompletions.removeValue(forKey: $0) ?? []
			// Left in the table until it winds down, so a return visit cannot start a second one
			loadTasks[$0]?.cancel()
			// Handed back, or a caller that passed a completion would wait forever
			waiters.forEach { $0() }
		}
		updateLoadingLabelVisibility()
	}

	/// Clear the finished load and settle whoever was waiting on it
	private func finishLoad(of pane: SettingsPaneViewController, retriesWaiters: Bool) {
		loadTasks.removeValue(forKey: pane)

		let waiters = pendingLoadCompletions.removeValue(forKey: pane) ?? []
		updateLoadingLabelVisibility()

		guard retriesWaiters, !waiters.isEmpty else {
			waiters.forEach { $0() }
			return
		}

		waiters.forEach { loadContentIfNeeded(for: pane, completion: $0) }
	}

	private func updateLoadingLabelVisibility() {
		let isStandingIn = loadingView.superview != nil
		let visible = showsLoadingLabel || (showsLoadingLabelWhileLoading && isStandingIn)
		loadingView.subviews.first { $0.identifier == Self.defaultLabelIdentifier }?.isHidden = !visible
	}
	
	/// Put the loading view in the pane’s place, wherever `NSTabViewController` placed that pane
	private func presentLoadingView(insteadOf pane: SettingsPaneViewController) {
		guard pane.isViewLoaded, let paneContainer = pane.view.superview else { return }

		standInLoadingView(in: paneContainer, replacing: pane.view)
	}

	private func standInLoadingView(in paneContainer: NSView, replacing outgoingView: NSView) {
		// Taken out rather than covered, or the container would feed back into the pane’s own measurement
		dismissLoadingView()
		loadingView.frame = paneContainer.bounds
		paneContainer.replaceSubview(outgoingView, with: loadingView)
		settleLoadingViewLayout()
		updateLoadingLabelVisibility()
	}

	private func dismissLoadingView() {
		loadingView.removeFromSuperview()
		updateLoadingLabelVisibility()
	}

	/// Center the label before the shared layout pass runs against a changing frame
	private func settleLoadingViewLayout() {
		loadingView.layoutSubtreeIfNeeded()
	}

	private func addPaneDissolveTransition(to view: NSView) {
		guard paneDissolveAnimationEnabled, Accessibility.allowsMotion() else { return }
		
		let transition = CATransition()
		transition.type = .fade
		transition.duration = paneDissolveDuration
		transition.timingFunction = animationTimingFunctionForPaneDissolve ?? CAMediaTimingFunction(name: .easeOut)
		view.wantsLayer = true
		view.layer?.add(transition, forKey: "paneDissolve")
	}

	
	// MARK: - Tab View and Transition
	
	open override func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
		// Repeat clicks would rerun the load and the animations of the tab already on its way
		if let tabViewItem, presentingTabViewItem === tabViewItem {
			return false
		}
		
		// Block toolbar interactions during transitions
		if settingsWindow?.isWindowResizing == true {
			return false
		}
		return super.tabView(tabView, shouldSelect: tabViewItem)
	}
	
	open override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, didSelect: tabViewItem)
		guard let tabViewItem else { return }

		// Driven from here, since the system skips the transition when the outgoing pane view was never placed
		selectTab(with: tabViewItem, animateIfPossible: hasViewAppeared)
	}

	open override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, willSelect: tabViewItem)
		// Dropped before the incoming pane decides it again
		settingsWindow?.resetWindowBehavior()
	}

	open override func transition(from fromViewController: NSViewController, to toViewController: NSViewController, options: NSViewController.TransitionOptions = [], completionHandler completion: (() -> Void)? = nil) {
		// A blank view stands between A and B, or the implicit window frame and toolbar animations come out wrong
		if let paneContainer = fromViewController.view.superview {
			standInLoadingView(in: paneContainer, replacing: fromViewController.view)
		}

		// The incoming pane is placed once its content is ready behind the loading view
		completion?()
	}
	
	
	// MARK: - Pane presentation
	
	/// Load the pane content behind the loading view, follow with the window, then reveal it
	private func presentPane(for tabViewItem: NSTabViewItem,
							 in paneContainer: NSView?,
							 animateIfPossible: Bool,
							 completion: (() -> Void)?)
	{
		// Tells a load left to a later turn apart from content built on the spot
		var loadWasDeferred = false
		
		let present = { [weak self] in
			guard let self else {
				completion?()
				return
			}
			
			// The user may have moved on during the load, so a stale request only hands back its completion
			guard self.selectedTabViewItem === tabViewItem else {
				completion?()
				return
			}
			
			self.cacheTabViewSize(for: tabViewItem)
			
			// The pane the window opens on has nothing to dissolve from, unless the load kept it waiting
			let dissolves = self.hasViewAppeared || loadWasDeferred
			let animates = animateIfPossible || dissolves

			// The window settles first, so the dissolve never runs against a moving frame
			self.fitWindowSize(to: tabViewItem, animateIfPossible: animates) {
				self.captureMinimumContentWidth(requestedFor: tabViewItem)
				
				if let paneContainer, self.loadingView.superview === paneContainer {
					if dissolves {
						self.addPaneDissolveTransition(to: paneContainer)
					}
					self.revealPane(of: tabViewItem, in: paneContainer)
				}
				
				self.updateWindowTitleWithSelectedTab()
				self.setWindowBehavior(with: tabViewItem)
				// Stored here, so a programmatic selection is remembered even when no delegate callback runs
				self.settingsWindowController?.storeSelectedTabIdentifier()
				self.recordSettledWindowSize(for: tabViewItem)
				completion?()
			}
		}
		
		let pane = tabViewItem.settingsPaneViewController
		cancelPendingLoads(except: pane)

		if let pane {
			loadContentIfNeeded(for: pane, completion: present)
			loadWasDeferred = true
		}
		else {
			present()
		}
	}

	private func revealPane(of tabViewItem: NSTabViewItem, in paneContainer: NSView) {
		guard let paneView = tabViewItem.viewController?.view else {
			dismissLoadingView()
			return
		}
		
		// Placed and settled in one transaction, so no intermediate size is drawn
		CATransaction.begin()
		CATransaction.setDisableActions(true)

		// A pane already in the container was only covered, so removing the loading view is enough
		if paneView.superview === paneContainer {
			dismissLoadingView()
		}
		else {
			paneView.frame = loadingView.frame
			paneContainer.replaceSubview(loadingView, with: paneView)
		}
		
		// Settled from this controller’s own view down, so the container is reconciled with the window
		view.layoutSubtreeIfNeeded()
		
		CATransaction.commit()
	}
	
	/// The size a pane is shown at until it declares or measures one of its own
	open func provisionalPaneSize() -> NSSize {
		// Carrying over the size on screen means switching to such a pane resizes nothing
		if let contentSize = settingsWindow?.contentView?.frame.size,
		   contentSize.width > 0, contentSize.height > 0 {
			return contentSize
		}

		return defaultPaneSize
	}

	/// Cache the size the window is fitted to for this pane, preferring a user-left size, then `preferredPaneSize`
	open func cacheTabViewSize(for tabViewItem: NSTabViewItem) {
		var size: NSSize?
		
		// The size the user left behind wins, so returning to a pane brings it back
		if let userSize = userResizedSizes[tabViewItem] {
			size = userSize
		}
		
		if size == nil,
		   let pane = tabViewItem.settingsPaneViewController,
		   let preferredSize = pane.preferredPaneSize,
		   preferredSize.width > 0 && preferredSize.height > 0 {
			size = preferredSize
		}
		
		// Fallback to the laid-out frame, then to the fitting size
		if size == nil,
		   tabViewItem.viewController?.isViewLoaded == true,
		   let view = tabViewItem.view {
			let frameSize = view.frame.size
			if frameSize.width > 0 && frameSize.height > 0 {
				size = frameSize
			}
			else {
				let fittingSize = view.fittingSize
				if fittingSize.width > 0 && fittingSize.height > 0 {
					size = fittingSize
				}
			}
		}
		
		// A pane that declares nothing and measures nothing still has to be shown at some size
		if size == nil {
			size = provisionalPaneSize()
		}
		
		if var s = size {
			if clampsToToolbarMinimumWidth && minimumContentWidth > 0 {
				s.width = max(s.width, minimumContentWidth)
			}
			
			if let pane = tabViewItem.settingsPaneViewController {
				if let minimumSize = pane.minimumPaneSize {
					s.width = max(s.width, minimumSize.width)
					s.height = max(s.height, minimumSize.height)
				}
				if let maximumSize = pane.maximumPaneSize {
					s.width = min(s.width, maximumSize.width)
					s.height = min(s.height, maximumSize.height)
				}
			}
			
			tabViewSizes[tabViewItem] = s
		}
	}
	
	/// Discard the size cached for a pane and measure it again. The window follows only while that pane is on screen
	open func invalidateCachedSize(for pane: SettingsPaneViewController) {
		guard let tabViewItem = tabViewItems.first(where: { $0.viewController === pane }) else { return }
		
		tabViewSizes[tabViewItem] = nil
		// The user record survives, and `cacheTabViewSize` lifts it to the new lower bound
		cacheTabViewSize(for: tabViewItem)
		
		if tabViewItem == selectedTabViewItem {
			fitWindowSize(to: tabViewItem, animateIfPossible: false)
		}
	}
	
	/// Learn the floor the toolbar imposes, by noticing that the window came out wider than it was asked for
	private func captureMinimumContentWidth(requestedFor tabViewItem: NSTabViewItem) {
		guard clampsToToolbarMinimumWidth,
			  let requestedWidth = tabViewSizes[tabViewItem]?.width,
			  let contentWidth = settingsWindow?.contentView?.frame.size.width,
			  contentWidth > requestedWidth, contentWidth > minimumContentWidth
		else { return }

		// Only a width the system refused to go below counts, or a user-dragged frame would be mistaken for it
		minimumContentWidth = contentWidth
	}

	/// Fit window size to specific tab view item
	open func fitWindowSize(to tabViewItem: NSTabViewItem, animateIfPossible: Bool, completion: (() -> ())? = nil) {
		guard let size = tabViewSizes[tabViewItem], let settingsWindow else {
			completion?()
			return
		}
		
		// Applied first, or the bounds left by the previous pane would clamp this resize
		applyContentSizeLimits(of: tabViewItem.settingsPaneViewController)
		settingsWindow.setWindowSize(size, animateIfPossible: animateIfPossible, completion: completion)
	}
	
	/// Keep the window from being dragged past the bounds the pane declared
	private func applyContentSizeLimits(of pane: SettingsPaneViewController?) {
		guard let settingsWindow else { return }
		
		let unbounded = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
		
		guard let pane, pane.isResizableView else {
			settingsWindow.contentMinSize = .zero
			settingsWindow.contentMaxSize = unbounded
			return
		}
		
		var minimumSize = pane.minimumPaneSize ?? .zero
		if clampsToToolbarMinimumWidth && minimumContentWidth > 0 {
			minimumSize.width = max(minimumSize.width, minimumContentWidth)
		}
		
		settingsWindow.contentMinSize = minimumSize
		settingsWindow.contentMaxSize = pane.maximumPaneSize ?? unbounded
	}
	
	
	// MARK: -
	
	/// Select tab, fit window size and update window title
	open func selectTab(with tabViewItem: NSTabViewItem, animateIfPossible: Bool, completion: (() -> Void)? = nil) {
		guard presentingTabViewItem !== tabViewItem else {
			completion?()
			return
		}
		
		presentingTabViewItem = tabViewItem
		
		// A pane the transition never took out has to be taken out here, or it is on screen before the dissolve
		if let pane = tabViewItem.settingsPaneViewController {
			presentLoadingView(insteadOf: pane)
		}
		
		presentPane(for: tabViewItem,
					in: loadingView.superview,
					animateIfPossible: animateIfPossible)
		{ [weak self] in
			self?.endPresentation(of: tabViewItem)
			completion?()
		}
	}
	
	private func endPresentation(of tabViewItem: NSTabViewItem) {
		// A presentation dropped for another tab has nothing left to release
		guard presentingTabViewItem === tabViewItem else { return }
		
		presentingTabViewItem = nil
	}
	
	/// Find the tab carrying the given identifier
	open func tabViewItem(withIdentifier identifier: String) -> NSTabViewItem? {
		tabViewItems.first { ($0.identifier as? String) == identifier }
	}
	
	/// Select the tab carrying the identifier and return true, or fall back to the first tab and return false
	@discardableResult
	open func selectTab(withIdentifier identifier: String?) -> Bool {
		guard !tabViewItems.isEmpty else { return false }

		// Only the index is moved. Loading and sizing are left to the transition or the first `viewWillAppear`
		if let identifier, let index = tabViewItems.firstIndex(where: { ($0.identifier as? String) == identifier }) {
			selectedTabViewItemIndex = index
			return true
		}

		selectedTabViewItemIndex = 0
		return false
	}

	/// Update window title on title bar, window menu item on the menu bar and Dock tile title
	open func updateWindowTitleWithSelectedTab() {
		settingsWindow?.setWindowTitle(with: selectedTabViewItem)
	}
	
	/// Reflect the resizable attribute of the selected tab item to the window
	private func setWindowBehavior(with tabViewItem: NSTabViewItem) {
		if tabViewItem.settingsPaneViewController?.isResizableView == true {
			settingsWindow?.addResizableBehavior()
		}
		else {
			settingsWindow?.resetWindowBehavior()
		}
	}
	
	private func updateTabName(of item: NSTabViewItem) {
		if let pane = item.settingsPaneViewController {
			if let localizeKey = pane.localizeKeyForTabName, !localizeKey.isEmpty && !disablesLocalizationWithTabNameLocalizeKey {
				item.label = String(localized: String.LocalizationValue(localizeKey))
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
