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
	
	private lazy var tabViewSizes: [NSTabViewItem: NSSize] = [:]
	
	
	// MARK: -
	
	open override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	open override func viewWillAppear() {
		super.viewWillAppear()
		
		resizeWindowToFit()
	}
	
	
	// MARK: -
	
	open func set(panes: [SettingsPaneViewController]) {
		panes.forEach {
			add(pane: $0)
		}
	}
	
	open func add(pane: SettingsPaneViewController) {
		pane.tabViewController = self
		let item = NSTabViewItem(viewController: pane)
		item.label = pane.tabName ?? ""
		item.image = pane.tabImage
		item.identifier = pane.tabIdentifier
		addTabViewItem(item)
	}
	
	open func insert(pane: SettingsPaneViewController, at index: Int) {
		pane.tabViewController = self
		let item = NSTabViewItem(viewController: pane)
		item.label = pane.tabName ?? ""
		item.image = pane.tabImage
		item.identifier = pane.tabIdentifier
		insertTabViewItem(item, at: index)
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
			
			// The NSViewController’s title is set as window title automatically so not need update window title manually
			//view.window?.title = tabViewItem.label
		}
	}
	
	open override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
		super.tabView(tabView, didSelect: tabViewItem)
		
		if let tabViewItem {
			resizeWindowToFit(tabViewItem: tabViewItem, animated: true)
			
			if let pane = tabViewItem.settingsPaneViewController, pane.isResizableView {
				view.window?.styleMask.insert(.resizable)
			}
			else {
				view.window?.styleMask.remove(.resizable)
			}
		}
	}
	
	//  参考：https://gist.github.com/ThatsJustCheesy/8148106fa7269326162d473408d3f75a
	
	public func resizeWindowToFit(tabViewItem: NSTabViewItem, animated: Bool) {
		guard let size = tabViewSizes[tabViewItem], let window = view.window else {
			return
		}
		
		let contentRect = NSRect(origin: .zero, size: size)
		let contentFrame = window.frameRect(forContentRect: contentRect)
		let toolbarHeight = window.frame.size.height - contentFrame.size.height
		let newOrigin = NSPoint(x: window.frame.origin.x, y: window.frame.origin.y + toolbarHeight)
		let newFrame = NSRect(origin: newOrigin, size: contentFrame.size)
		
		if animated {
			self.view.alphaValue = 0
			
			NSAnimationContext.runAnimationGroup { context in
				context.duration = CATransaction.animationDuration()
				window.animator().setFrame(newFrame, display: false)
			} completionHandler: {
				self.view.alphaValue = 1
			}
		}
		else {
			window.setFrame(newFrame, display: false)
		}
	}
	
	public func resizeWindowToFit() {
		resizeWindowToFit(tabViewItem: tabView.tabViewItem(at: 0), animated: false)
	}
	
}
