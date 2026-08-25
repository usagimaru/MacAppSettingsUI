//
//  DemoViewController.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/01/20.
//

import Cocoa

class DemoViewController: NSViewController {

	@IBOutlet var centerAlways: NSButton!
	@IBOutlet var enablesAnimation: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		centerAlways.state = DemoOptions.centersWindowAlways ? .on : .off
		enablesAnimation.state = DemoOptions.animationEnabled ? .on : .off

		DispatchQueue.main.async {
			self.view.window?.isMovableByWindowBackground = true
		}
	}

	@IBAction func toggleCenterAlways(_ sender: NSButton) {
		DemoOptions.centersWindowAlways = sender.state == .on
		AppDelegate.shared.settingsWindowController?.centersWindowPositionAlways = sender.state == .on
	}

	@IBAction func toggleAnimation(_ sender: NSButton) {
		DemoOptions.animationEnabled = sender.state == .on
		AppDelegate.shared.settingsWindowController?.settingsWindow.fittingAnimationEnabled = sender.state == .on
	}
	
	@IBAction func removeAutosaveFrame(_ sender: Any) {
		// The type method works even while no window controller is alive
		SettingsWindowController.removeAutosavedWindowFrame()
	}
	
}

