//
//  Supports.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2024/03/09.
//

import Cocoa

extension NSButton {
	
	@IBInspectable var titleLocalizable: String {
		get {
			self.titleLocalizable
		}
		set {
			title = NSLocalizedString(newValue, comment: "")
		}
	}
	
	@IBInspectable var altTitleLocalizable: String {
		get {
			self.altTitleLocalizable
		}
		set {
			alternateTitle = NSLocalizedString(newValue, comment: "")
		}
	}
	
}
