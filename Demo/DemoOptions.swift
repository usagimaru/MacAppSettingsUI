//
//  DemoOptions.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/01/20.
//

import Cocoa

/// The demo options, kept in UserDefaults so a rebuilt window controller can read them back
enum DemoOptions {

	private static let centersWindowAlwaysKey = "DemoOptions.centersWindowAlways"
	private static let animationEnabledKey = "DemoOptions.animationEnabled"

	static var centersWindowAlways: Bool {
		get { UserDefaults.standard.bool(forKey: centersWindowAlwaysKey) }
		set { UserDefaults.standard.set(newValue, forKey: centersWindowAlwaysKey) }
	}

	static var animationEnabled: Bool {
		// Defaults to on, matching the checkbox in the storyboard
		get { UserDefaults.standard.object(forKey: animationEnabledKey) as? Bool ?? true }
		set { UserDefaults.standard.set(newValue, forKey: animationEnabledKey) }
	}

}
