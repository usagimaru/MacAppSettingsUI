//
//  Accessibility.swift
//
//  Created by usagimaru on 2026/08/05.
//

import Cocoa


/// Reference to Accessibility settings
enum Accessibility {
	
	/// Reduce Motion
	static var isMotionReduced: Bool {
		NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
	}
	
	/// Reduce Transparency
	static var isTransparencyReduced: Bool {
		NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
	}
	
	/// Get combined flag
	static func allowsMotion(_ flag: Bool = true) -> Bool {
		flag && !isMotionReduced
	}
	
}
