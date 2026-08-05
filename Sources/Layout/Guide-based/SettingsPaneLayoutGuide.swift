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
		let targetView: NSView?
		if let vc = self as? NSViewController {
			targetView = vc.view
		}
		else if let view = self as? NSView {
			targetView = view
		}
		else {
			targetView = nil
		}

		guard let targetView else { return }
		setContentContainerView(to: targetView, maximumWidth: maximumWidth, labelLayoutGuideWidth: labelLayoutGuideWidth)
	}

	/// Prepare container view to a specific subview
	func setContentContainerView(to targetView: NSView, maximumWidth: CGFloat?, labelLayoutGuideWidth: CGFloat? = nil) {
		if let contentContainerView {
			contentContainerView.removeFromSuperview()
		}

		let containerView = SettingsPaneContainerView()
		containerView.containerMaximumWidth = maximumWidth

		if let labelLayoutGuideWidth {
			containerView.labelLayoutGuideWidth = labelLayoutGuideWidth
		}

		targetView.addSubview(containerView, positioned: .below, relativeTo: nil)
		contentContainerView = containerView
	}
	
}
