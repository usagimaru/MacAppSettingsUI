//
//  SettingsPaneLayoutGuide.swift
//
//  Created by usagimaru on 2026/01/20.
//

import Cocoa

/// This protocol conforms to NSView and NSViewController
public protocol SettingsPaneLayoutGuide: NSResponder {
	
	var contentContainerView: SettingsPaneContainerView? { get set }
	
}

public extension SettingsPaneLayoutGuide {
	
	/// Prepare container view if you want
	func setContentContainerView(maximumWidth: CGFloat?, labelLayoutGuideWidth: CGFloat? = nil) {
		if let contentContainerView {
			contentContainerView.removeFromSuperview()
		}
		
		let containerView = SettingsPaneContainerView()
		containerView.containerMaximumWidth = maximumWidth
		
		if let labelLayoutGuideWidth {
			containerView.labelLayoutGuideWidth = labelLayoutGuideWidth
		}
		
		if let vc = self as? NSViewController {
			vc.view.addSubview(containerView, positioned: .below, relativeTo: nil)
		}
		else if let view = self as? NSView {
			view.addSubview(containerView, positioned: .below, relativeTo: nil)
		}
		else {
			return
		}
		
		contentContainerView = containerView
	}
	
}
