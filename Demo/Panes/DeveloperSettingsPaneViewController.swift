//
//  DeveloperSettingsPaneViewController.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/01/20.
//

import Cocoa

// Guide-based layout
class DeveloperSettingsPaneViewController: SettingsPaneViewController, SettingsPaneLayoutGuide {

	/// The size this pane opens at
	private static let defaultPaneSize = NSSize(width: 530, height: 280)

	var contentContainerView: SettingsPaneContainerView?

	override func loadView() {
		// Setup the custom content view

		// View with default pane size
		view = NSView(frame: NSRect(origin: .zero, size: Self.defaultPaneSize))
		
		// Set minimum / maximum size of this pane
		NSLayoutConstraint.activate([
			view.widthAnchor.constraint(greaterThanOrEqualToConstant: 300), // Minimum width
			view.heightAnchor.constraint(greaterThanOrEqualToConstant: 280), // Minimum height
			view.widthAnchor.constraint(lessThanOrEqualToConstant: 800), // Maximum width
			view.heightAnchor.constraint(lessThanOrEqualToConstant: 700), // Maximum height
		])
	}
	
	override func buildPaneContent() {
		// ----- Demo for setup the layout container -----
		
		// 1: First, prepare the container view with any maximum width value (or setting it to nil allows the container to behave flexibly)
		setContentContainerView(maximumWidth: nil)
		
		// 2: If necessary, enable wireframes for debugging. (Only effective in `DEBUG` build.)
		contentContainerView?.debug_setWireframes(true)
		
		buildUI()
		
		// 3: Update preferred pane size
		// Switching tabs hands this pane the frame of the previous one, so the size is declared again before it is captured
		view.setFrameSize(Self.defaultPaneSize)
		capturePreferredPaneSize()
	}
	
	private func buildUI() {
		// Insert labels and items
		let label1 = setDemoLabel(topView: nil, label: "Setting item 1:")
		setDemoItem(leadingView: label1, title: "This is a checkbox")
		
		let label2 = setDemoLabel(topView: label1, label: "Setting item 2:")
		setDemoItem(leadingView: label2, title: "This is a checkbox with a long long text")
		
		let label3 = setDemoLabel(topView: label2, label: "Pineapple pen + Apple pen:")
		setDemoItem(leadingView: label3, title: "Pen-pineapple-apple-pen")
		
		// Add separator
		let separator = setDemoSeparator(topView: label3)
		
		// Add toggle switch
		let label4 = setDemoLabel(topView: separator, label: "Wireframes:")
		setDemoSwitch(leadingView: label4, state: .on)

		setDemoNoteLabel()
	}

	/// Names the layout this pane is built with
	private func setDemoNoteLabel() {
		// Matches the notes the section-based panes carry
		let label = NSTextField(labelWithString: String(localized: "Guide-based layout"))
		label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
		label.textColor = .secondaryLabelColor
		label.alignment = .center

		view.addSubview(label)
		label.translatesAutoresizingMaskIntoConstraints = false
		label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		view.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 40).isActive = true
	}
	
	private func setDemoLabel(topView: NSView?, label: String) -> NSTextField {
		let label = NSTextField(string: label)
		label.alignment = .right
		label.lineBreakMode = .byTruncatingMiddle
		label.font = .systemFont(ofSize: NSFont.systemFontSize)
		label.textColor = .labelColor
		label.isSelectable = false
		label.isEditable = false
		label.isBordered = false
		label.backgroundColor = .clear
		
		if let contentContainerView {
			contentContainerView.addSubview(label)
			label.translatesAutoresizingMaskIntoConstraints = false
			label.trailingAnchor.constraint(equalTo: contentContainerView.labelLayoutGuide.trailingAnchor).isActive = true
			label.leadingAnchor.constraint(greaterThanOrEqualTo: contentContainerView.labelLayoutGuide.leadingAnchor).isActive = true
			
			if let topView {
				label.topAnchor.constraint(equalToSystemSpacingBelow: topView.bottomAnchor, multiplier: 1).isActive = true
			}
			else {
				label.topAnchor.constraint(equalTo: contentContainerView.labelLayoutGuide.topAnchor).isActive = true
			}
			
			// Set the weak priority for the horizontal resistance
			let p = NSLayoutConstraint.Priority(NSLayoutConstraint.Priority.defaultLow.rawValue - 10)
			label.setContentCompressionResistancePriority(p, for: .horizontal)
		}
		
		return label
	}
	
	private func setDemoItem(leadingView: NSView, title: String) {
		if let contentContainerView {
			let item = NSButton(checkboxWithTitle: title, target: nil, action: nil)
			item.state = .on
			
			contentContainerView.addSubview(item)
			item.translatesAutoresizingMaskIntoConstraints = false
			item.firstBaselineAnchor.constraint(equalTo: leadingView.firstBaselineAnchor).isActive = true
			item.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingView.trailingAnchor, multiplier: 1).isActive = true
			contentContainerView.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: item.trailingAnchor, multiplier: 1).isActive = true
			
			// Set the weak priority for the horizontal resistance
			let p = NSLayoutConstraint.Priority(NSLayoutConstraint.Priority.defaultLow.rawValue - 10)
			item.setContentCompressionResistancePriority(p, for: .horizontal)
		}
	}
	
	private func setDemoSwitch(leadingView: NSView, state: NSControl.StateValue) {
		if let contentContainerView {
			let item = DemoSwitch(isOn: state == .on,
								  sizingWindow: tabViewController?.settingsWindow) { [weak self] isOn in
				self?.contentContainerView?.debug_setWireframes(isOn)
			}
			item.identifier = .init("Wireframe switch")
			
			contentContainerView.addSubview(item)
			item.translatesAutoresizingMaskIntoConstraints = false
			item.centerYAnchor.constraint(equalTo: leadingView.centerYAnchor).isActive = true
			item.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingView.trailingAnchor, multiplier: 1).isActive = true
			contentContainerView.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: item.trailingAnchor, multiplier: 1).isActive = true
			
			// Set the weak priority for the horizontal resistance
			let p = NSLayoutConstraint.Priority(NSLayoutConstraint.Priority.defaultLow.rawValue - 10)
			item.setContentCompressionResistancePriority(p, for: .horizontal)
		}
	}
	
	private func setDemoSeparator(topView: NSView) -> NSBox {
		let separator = NSBox()
		separator.boxType = .separator
		view.addSubview(separator)
		separator.translatesAutoresizingMaskIntoConstraints = false
		separator.topAnchor.constraint(equalToSystemSpacingBelow: topView.bottomAnchor, multiplier: 1).isActive = true
		separator.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1).isActive = true
		view.trailingAnchor.constraint(equalToSystemSpacingAfter: separator.trailingAnchor, multiplier: 1).isActive = true
		
		return separator
	}

}
