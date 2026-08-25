//
//  AdvancedSettingsPaneViewController.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/01/20.
//

import Cocoa

// Guide-based layout
class AdvancedSettingsPaneViewController: SettingsPaneViewController, SettingsPaneLayoutGuide {

	var contentContainerView: SettingsPaneContainerView?
	
	override func buildPaneContent() {
		// ----- Demo for setup the layout container -----
		
		// 1: First, prepare the container view with any maximum width value (or setting it to nil allows the container to behave flexibly).
		setContentContainerView(maximumWidth: 550)
		
		// 2: If necessory, set any width value to the label layout guide.
		contentContainerView?.labelLayoutGuideWidth = 160
		
		// 3: If necessary, enable wireframes for debugging. (Only effective in `DEBUG` build.)
		contentContainerView?.debug_setWireframes(true)
		
		// 4: Update preferred pane size
		capturePreferredPaneSize()
	}

}
