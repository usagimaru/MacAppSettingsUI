//
//  UpdateSettingsPaneViewController.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/01/20.
//

import Cocoa
import SwiftUI

// Nested NSTabView layout, mixing an AppKit tab with a SwiftUI tab
class UpdateSettingsPaneViewController: SettingsPaneViewController {

	/// Tighter than the system margin on purpose, so the tabs sit close under the toolbar
	private static let tabViewTopMargin: CGFloat = 12
	
	/// Outlines both tabs, so the margins of the AppKit and the SwiftUI side can be read off against each other
	private var layoutDebugWireframes: LayoutDebugWireframes?
	
	private var generalTabLayoutView: SettingsLayoutView?
	private var advancedTabHostingView: SettingsHostingView<UpdateAdvancedSettingsView>?
	
	
	// MARK: -
	
	override func loadView() {
		// A nested NSTabView reports no size upward, so this pane declares its own
		view = NSView(frame: NSMakeRect(0, 0, 480, 420))
	}
	
	override func buildPaneContent() {
		buildTabView()
	}
	
	private func buildTabView() {
		let tabView = NSTabView()
		tabView.controlSize = .small
		// `controlSize` alone leaves the labels at the default size, so the font is set as well
		tabView.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
		tabView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(tabView)
		
		NSLayoutConstraint.activate([
			tabView.topAnchor.constraint(equalTo: view.topAnchor, constant: Self.tabViewTopMargin),
			tabView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
			view.trailingAnchor.constraint(equalToSystemSpacingAfter: tabView.trailingAnchor, multiplier: 1),
			view.bottomAnchor.constraint(equalToSystemSpacingBelow: tabView.bottomAnchor, multiplier: 1),
		])
		
		// Resolved before the tabs go in, or a still collapsed tab view would hand an item view the height of the tab strip alone
		view.layoutSubtreeIfNeeded()
		
		tabView.addTabViewItem(makeGeneralTabViewItem())
		tabView.addTabViewItem(makeAdvancedTabViewItem())
		
		setUpWireframes(of: tabView)
	}
	
	override func viewDidLayout() {
		super.viewDidLayout()
		// Walked again on every pass, or the views SwiftUI builds later would stay unoutlined
		layoutDebugWireframes?.refresh()
	}
	
	
	// MARK: - Tab 1: AppKit with the section layout
	
	private func makeGeneralTabViewItem() -> NSTabViewItem {
		let item = NSTabViewItem(identifier: "General")
		item.label = String(localized: "General")
		item.view = makeGeneralTabContentView()
		
		return item
	}
	
	private func makeGeneralTabContentView() -> NSView {
		let tabContentView = NSView()
		
		// The section layout takes the system margins from the tab content area itself
		let layoutView = SettingsLayoutView()
		layoutView.install(in: tabContentView)
		generalTabLayoutView = layoutView
		
		let schedule = layoutView.addColumnSection(label: String(localized: "Schedule"),
												   identifier: .init("Schedule"))
		schedule.addCheckbox(title: String(localized: "Check automatically"),
							 isOn: true,
							 target: self,
							 action: nil)
		let frequency = schedule.addPopUpButton(indentationLevel: 1, target: self, action: nil)
		frequency.addItems(withTitles: [String(localized: "Daily"),
										String(localized: "Weekly"),
										String(localized: "Monthly")])
		
		let download = layoutView.addColumnSection(label: String(localized: "Download"),
												   identifier: .init("Download"))
		download.addCheckbox(title: String(localized: "Download in the background"),
							 target: self,
							 action: nil)
		download.addCheckbox(title: String(localized: "Notify when ready"),
							 isOn: true,
							 indentationLevel: 1,
							 target: self,
							 action: nil)
		
		layoutView.addSeparatorSection()
		
		let status = layoutView.addColumnSection(label: String(localized: "Status"),
												 identifier: .init("Status"))
		status.addButton(title: String(localized: "Check Now"),
						 target: self,
						 action: nil)
		status.addDescriptionLabel(String(localized: "UPDATE_LAST_CHECKED"))
		
		return tabContentView
	}
	
	
	// MARK: - Tab 2: SwiftUI
	
	private func makeAdvancedTabViewItem() -> NSTabViewItem {
		let item = NSTabViewItem(identifier: "Advanced")
		item.label = String(localized: "Advanced")
		item.view = makeAdvancedTabContentView()
		
		return item
	}
	
	private func makeAdvancedTabContentView() -> NSView {
		// Measured against the width it is given, so the SwiftUI side needs no fixed width. A plain NSHostingView works here too
		let hostingView = SettingsHostingView(rootView: UpdateAdvancedSettingsView())
		hostingView.translatesAutoresizingMaskIntoConstraints = false
		advancedTabHostingView = hostingView
		
		// NSTabView sizes an item view by frame, so the hosting view is inset from a plain wrapper
		let tabContentView = NSView()
		tabContentView.addSubview(hostingView)
		
		NSLayoutConstraint.activate([
			hostingView.topAnchor.constraint(equalToSystemSpacingBelow: tabContentView.topAnchor, multiplier: 1),
			hostingView.centerXAnchor.constraint(equalTo: tabContentView.centerXAnchor),
			hostingView.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: tabContentView.leadingAnchor, multiplier: 1),
			tabContentView.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: hostingView.trailingAnchor, multiplier: 1),
			tabContentView.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: hostingView.bottomAnchor, multiplier: 1),
		])
		
		return tabContentView
	}
	
	
	// MARK: - Debug wireframes
	
	/// Only view outlines are registered, so Auto Layout keeps them in place without a layout hook
	private func setUpWireframes(of tabView: NSTabView) {
		let wireframes = LayoutDebugWireframes(host: view)
		layoutDebugWireframes = wireframes
		
		wireframes.add(view: view, color: LayoutDebugWireframeColor.container)
		wireframes.add(view: tabView, color: LayoutDebugWireframeColor.container)
		
		// The content area each tab is handed. Both tabs get the same rect, so the margins can be compared
		tabView.tabViewItems.compactMap { $0.view }.forEach {
			wireframes.add(view: $0, color: LayoutDebugWireframeColor.section)
		}
		
		if let generalTabLayoutView {
			wireframes.add(view: generalTabLayoutView, color: LayoutDebugWireframeColor.labelColumn)
			generalTabLayoutView.debug_setWireframes(true)
		}
		
		// Outlined down to the leaves, since a gap inside the hosting view would not show on its own border
		if let advancedTabHostingView {
			wireframes.add(view: advancedTabHostingView,
						   color: LayoutDebugWireframeColor.labelColumn,
						   descendantColor: LayoutDebugWireframeColor.control)
		}
		
		// Assigning true has no effect outside a DEBUG build
		wireframes.isEnabled = true
	}

}
