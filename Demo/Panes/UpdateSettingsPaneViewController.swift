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

	/// The narrowest width this pane is laid out for
	private static let minimumPaneWidth: CGFloat = 480
	
	/// Outlines both tabs, so the margins of the AppKit and the SwiftUI side can be read off against each other
	private var layoutDebugWireframes: LayoutDebugWireframes?
	
	private var tabLayoutView: SettingsTabLayoutView?
	private var generalTabLayoutView: SettingsLayoutView?
	private var advancedTabHostingView: SettingsHostingView<UpdateAdvancedSettingsView>?
	
	
	// MARK: -
	
	override func loadView() {
		view = NSView()
	}
	
	override func buildPaneContent() {
		buildTabView()
		sizePaneToFitContent(minimumWidth: Self.minimumPaneWidth)
	}
	
	private func buildTabView() {
		let tabLayoutView = SettingsTabLayoutView()
		tabLayoutView.install(in: view)
		self.tabLayoutView = tabLayoutView
		
		buildGeneralTab(in: tabLayoutView)
		buildAdvancedTab(in: tabLayoutView)
		
		setUpWireframes(of: tabLayoutView)
	}
	
	override func viewDidLayout() {
		super.viewDidLayout()
		// Walked again on every pass, or the views SwiftUI builds later would stay unoutlined
		layoutDebugWireframes?.refresh()
	}
	
	
	// MARK: - Tab 1: AppKit with the section layout
	
	private func buildGeneralTab(in tabLayoutView: SettingsTabLayoutView) {
		let layoutView = tabLayoutView.addSectionTab(label: String(localized: "General"),
													 identifier: "General")
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
	}
	
	
	// MARK: - Tab 2: SwiftUI
	
	private func buildAdvancedTab(in tabLayoutView: SettingsTabLayoutView) {
		// Measured against the width it is given, so the SwiftUI side needs no fixed width
		advancedTabHostingView = tabLayoutView.addHostingTab(label: String(localized: "Advanced"),
															 rootView: UpdateAdvancedSettingsView(),
															 identifier: "Advanced")
	}
	
	
	// MARK: - Debug wireframes
	
	/// Only view outlines are registered, so Auto Layout keeps them in place without a layout hook
	private func setUpWireframes(of tabLayoutView: SettingsTabLayoutView) {
		let wireframes = LayoutDebugWireframes(host: view)
		layoutDebugWireframes = wireframes
		
		wireframes.add(view: view, color: LayoutDebugWireframeColor.container)
		wireframes.add(view: tabLayoutView.tabView, color: LayoutDebugWireframeColor.container)
		
		// The content area each tab is handed. Both tabs get the same rect, so the margins can be compared
		tabLayoutView.tabView.tabViewItems.compactMap { $0.view }.forEach {
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
