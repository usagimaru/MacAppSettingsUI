//
//  DemoViewController.swift
//  MacAppSettingsUI
//
//  Created by usagimaru on 2024/03/08.
//

import Cocoa

class DemoViewController: NSViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		DispatchQueue.main.async {
			self.view.window?.isMovableByWindowBackground = true
		}
	}
	
}
