//
//  Supports.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2024/03/09.
//

import Cocoa
import SwiftUI

/// The switch body of `DemoSwitch`. State lives here so SwiftUI can redraw, and changes are reported outward
struct DemoSwitchView: View {

	let controlSize: ControlSize
	let onChange: (Bool) -> Void
	
	@State private var isOn: Bool
	
	init(isOn: Bool, controlSize: ControlSize, onChange: @escaping (Bool) -> Void) {
		_isOn = State(initialValue: isOn)
		self.controlSize = controlSize
		self.onChange = onChange
	}
	
	var body: some View {
		Toggle("", isOn: $isOn)
			.toggleStyle(.switch)
			.labelsHidden()
			.controlSize(controlSize)
			.onChange(of: isOn) { _, newValue in
				onChange(newValue)
			}
	}

}

/// A switch that honors `controlSize`. NSSwitch carries no NSCell, so it ignores that property and stays 54x24
final class DemoSwitch: NSHostingView<DemoSwitchView> {

	convenience init(isOn: Bool = false,
					 controlSize: ControlSize = .mini,
					 sizingWindow: NSWindow?,
					 onChange: @escaping (Bool) -> Void)
	{
		self.init(rootView: DemoSwitchView(isOn: isOn, controlSize: controlSize, onChange: onChange))
		settleIntrinsicContentSize(in: sizingWindow)
	}

	/// SwiftUI resolves the content size only inside a window, and panes are measured before reaching one
	private func settleIntrinsicContentSize(in window: NSWindow?) {
		guard let contentView = window?.contentView else { return }

		contentView.addSubview(self)
		layoutSubtreeIfNeeded()
		removeFromSuperview()
	}

}

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
