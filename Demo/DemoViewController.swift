//
//  DemoViewController.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/01/20.
//

import Cocoa

class DemoViewController: NSViewController {

	@IBOutlet var openSettings: NSButton!
	@IBOutlet var centerAlways: NSButton!
	@IBOutlet var enablesAnimation: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		centerAlways.state = DemoOptions.centersWindowAlways ? .on : .off
		enablesAnimation.state = DemoOptions.animationEnabled ? .on : .off

		DispatchQueue.main.async {
			self.view.window?.isMovableByWindowBackground = true
			self.view.window?.makeFirstResponder(self.openSettings)
		}
	}

	@IBAction func toggleCenterAlways(_ sender: NSButton) {
		DemoOptions.centersWindowAlways = sender.state == .on
		AppDelegate.shared.settingsWindowController?.centersWindowPositionAlways = sender.state == .on
	}

	@IBAction func toggleAnimation(_ sender: NSButton) {
		DemoOptions.animationEnabled = sender.state == .on
		AppDelegate.shared.settingsWindowController?.applyAnimationOption()
	}
	
	@IBAction func removeAutosaveFrame(_ sender: Any) {
		// Works even while no window controller is alive
		SettingsWindowController.removeAutosavedWindowFrame()
	}
	
}

