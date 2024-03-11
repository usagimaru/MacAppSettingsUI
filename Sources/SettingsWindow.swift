//
//  SettingsWindow.swift
//
//  Created by usagimaru on 2024/03/11.
//

import Cocoa

open class SettingsWindow: NSWindow {
	
	public required convenience init(with contentViewController: NSTabViewController) {
		self.init(contentViewController: contentViewController)
	}
	
	open override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		switch menuItem.action {
			case #selector(toggleToolbarShown(_:)):
				// Disable `toggleToolbarShown(_:)` menu item
				return false
				
			case #selector(runToolbarCustomizationPalette(_:)):
				// Disable toolbar customization
				return false
				
			case _:
				return true
		}
	}
	
}
