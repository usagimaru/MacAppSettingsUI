//
//  DemoViewControllers.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/01/20.
//

import Cocoa

class DemoViewController: NSViewController {
	
	@IBOutlet var centerAlways: NSButton!
	@IBOutlet var enablesAnimation: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		DispatchQueue.main.async {
			self.view.window?.isMovableByWindowBackground = true
		}
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		DispatchQueue.main.async {
			AppDelegate.shared.settingsWindowController.centersWindowPositionAlways = self.centerAlways.state == .on
		}
	}
	
	@IBAction func toggleCenterAlways(_ sender: NSButton) {
		AppDelegate.shared.settingsWindowController.centersWindowPositionAlways = sender.state == .on
	}
	
	@IBAction func toggleAnimation(_ sender: NSButton) {
		AppDelegate.shared.settingsWindowController.settingsWindow.fittingAnimationEnabled = sender.state == .on
	}
	
	@IBAction func removeAutosaveFrame(_ sender: Any) {
		AppDelegate.shared.settingsWindowController.removeAutosavedWindowFrame()
	}
	
}


// MARK: - Panes

extension SettingsPaneViewController {
	
	class func fromStoryboard(tabViewController: SettingsTabViewController? = nil,
							  tabName: String? = nil,
							  localizeKeyForTabName: String? = nil,
							  tabImage: NSImage? = nil,
							  tabIdentifier: String? = nil,
							  isResizableView: Bool? = nil) -> Self {
		let vc = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "\(Self.self)") as! Self
		vc.tabViewController = tabViewController
		
		if let tabName {
			vc.tabName = tabName
		}
		if let localizeKeyForTabName {
			vc.localizeKeyForTabName = localizeKeyForTabName
		}
		if let tabImage {
			vc.tabImage = tabImage
		}
		if let tabIdentifier {
			vc.tabIdentifier = tabIdentifier
		}
		if let isResizableView {
			vc.isResizableView = isResizableView
		}
		
		return vc
	}
	
}

class GeneralSettingsPaneViewController: SettingsPaneViewController {}

class ViewSettingsPaneViewController: SettingsPaneViewController {}

class ExtensionsSettingsPaneViewController: SettingsPaneViewController {}

class AdvancedSettingsPaneViewController: SettingsPaneViewController, SettingsPaneLayoutGuide {
	
	var contentContainerView: SettingsPaneContainerView?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// ----- Demo for setup the layout container -----
		
		// 1: First, prepare the container view with any maximum width value (or setting it to nil allows the container to behave flexibly).
		setContentContainerView(maximumWidth: 550)
		
		// 2: If necessory, set any width value to the label layout guide.
		contentContainerView?.labelLayoutGuideWidth = 160
		
		// 3: If necessary, enable wireframes for debugging. (Only effective in `DEBUG` build.)
		contentContainerView?.debug_setWireframes(true)
	}
	
}

class DeveloperSettingsPaneViewController: SettingsPaneViewController, SettingsPaneLayoutGuide {
	
	var contentContainerView: SettingsPaneContainerView?
	
	override func loadView() {
		// Setup the custom content view
		
		// View with default pane size
		view = NSView(frame: NSMakeRect(0, 0, 400, 280))
		
		// Set minimum / maximum size of this pane
		NSLayoutConstraint.activate([
			view.widthAnchor.constraint(greaterThanOrEqualToConstant: 300), // Minimum width
			view.heightAnchor.constraint(greaterThanOrEqualToConstant: 280), // Minimum height
			view.widthAnchor.constraint(lessThanOrEqualToConstant: 800), // Maximum width
			view.heightAnchor.constraint(lessThanOrEqualToConstant: 700), // Maximum height
		])
	}
	
	private func setDemoBlankText() {
		let label = NSTextField(labelWithString: "\(self.tabName ?? "")\n(Resizable)")
		label.alignment = .center
		label.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
		label.textColor = .tertiaryLabelColor
		label.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(label)
		
		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
		])
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// ----- Demo for setup the layout container -----
		
		// 1: First, prepare the container view with any maximum width value (or setting it to nil allows the container to behave flexibly)
		setContentContainerView(maximumWidth: nil)
		
		// 2: If necessary, enable wireframes for debugging. (Only effective in `DEBUG` build.)
		contentContainerView?.debug_setWireframes(true)
		
		
		// ----- Demo for adding contents -----
		
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
			let item = NSSwitch()
			item.state = state
			item.controlSize = .small
			item.target = self
			item.identifier = .init("Wireframe switch")
			item.action = #selector(switchAction(_:))
			
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
	
	@objc private func switchAction(_ sender: Any) {
		if let `switch` = sender as? NSSwitch, `switch`.identifier == .init("Wireframe switch") {
			contentContainerView?.debug_setWireframes(`switch`.state == .on)
		}
	}
	
}

class UpdateSettingsPaneViewController: SettingsPaneViewController {
	
	override func loadView() {
		// Setup the custom content view
		
		view = NSView(frame: NSMakeRect(0, 0, 400, 380))
		
		let label = NSTextField(labelWithString: self.tabName ?? "")
		label.alignment = .center
		label.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
		label.textColor = .tertiaryLabelColor
		label.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(label)
		
		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
		])
	}
	
}
