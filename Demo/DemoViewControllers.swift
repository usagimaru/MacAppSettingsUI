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
		DispatchQueue.main.async { [weak self] in
			guard let self else { return }
			AppDelegate.shared.settingsWindowController?.centersWindowPositionAlways = self.centerAlways.state == .on
			
			// "Loading…" label
			AppDelegate.shared.settingsWindowController?.tabViewController.loadingLabelText = String(localized: "Loading…")
			AppDelegate.shared.settingsWindowController?.tabViewController.showsLoadingLabel = true
		}
	}
	
	@IBAction func toggleCenterAlways(_ sender: NSButton) {
		AppDelegate.shared.settingsWindowController?.centersWindowPositionAlways = sender.state == .on
	}
	
	@IBAction func toggleAnimation(_ sender: NSButton) {
		AppDelegate.shared.settingsWindowController?.settingsWindow.fittingAnimationEnabled = sender.state == .on
	}
	
	@IBAction func removeAutosaveFrame(_ sender: Any) {
		AppDelegate.shared.settingsWindowController?.removeAutosavedWindowFrame()
	}

}


// MARK: - Panes

// Section-based layout
class GeneralSettingsPaneViewController: SettingsPaneViewController {

	/// The narrowest width this pane is laid out for
	private static let minimumPaneWidth: CGFloat = 500
	
	/// Keeps the item column from stretching across the whole pane
	private static let itemColumnMaximumWidth: CGFloat = 260
	
	private var layoutView: SettingsLayoutView?


	// MARK: -
	
	override func loadView() {
		// Setup the custom content view. This pane has no storyboard scene
		view = NSView()
		
		buildSections()
		sizePaneToFitContent(minimumWidth: Self.minimumPaneWidth)
	}
	
	private func buildSections() {
		// Layout with section stack
		
		let layoutView = SettingsLayoutView()
		layoutView.install(in: view)
		self.layoutView = layoutView
		
		// Section with a single item. The upper bound passed here governs the item column of every section
		let startup = layoutView.addColumnSection(label: String(localized: "Startup"),
												  itemColumnMaximumWidth: Self.itemColumnMaximumWidth,
												  identifier: .init("Startup"))
		startup.addCheckbox(title: String(localized: "Open at login"),
							target: self,
							action: nil)
		
		// Section with multiple items. Items added to the same section are stacked downward
		let behavior = layoutView.addColumnSection(label: String(localized: "Behavior"),
												   identifier: .init("Behavior"))
		behavior.addCheckbox(title: String(localized: "Confirm before quitting"),
							 isOn: true,
							 target: self,
							 action: nil)
		behavior.addCheckbox(title: String(localized: "Restore windows on launch"),
							 isOn: true,
							 target: self,
							 action: nil)
		behavior.addCheckbox(title: String(localized: "Send usage data"),
							 target: self,
							 action: nil)
		
		// Section with a pop-up button
		let downloads = layoutView.addColumnSection(label: String(localized: "Save Downloads To"),
													identifier: .init("Downloads"))
		let downloadLocation = downloads.addPopUpButton(target: self, action: nil)
		downloadLocation.addItems(withTitles: [String(localized: "Downloads Folder"),
											   String(localized: "Desktop"),
											   String(localized: "Ask Each Time")])
		downloads.addDescriptionLabel(String(localized: "GENERAL_DOWNLOADS_DESCRIPTION"))
		
		// Section with multiple items followed by a description label
		let notifications = layoutView.addColumnSection(label: String(localized: "Notifications"),
														identifier: .init("Notifications"))
		notifications.addCheckbox(title: String(localized: "Allow notifications"),
								  isOn: true,
								  target: self,
								  action: nil)
		notifications.addCheckbox(title: String(localized: "Play sound"),
								  target: self,
								  action: nil)
		notifications.addDescriptionLabel(String(localized: "GENERAL_NOTIFICATIONS_DESCRIPTION"))
		
		layoutView.addSeparatorSection()
		
		// Section with a push button
		let cache = layoutView.addColumnSection(label: String(localized: "Cache"),
												identifier: .init("Cache"))
		cache.addButton(title: String(localized: "Clear Cache…"),
						target: self,
						action: nil)
		cache.addDescriptionLabel(String(localized: "GENERAL_CACHE_DESCRIPTION"))
		
		layoutView.addSeparatorSection()
		
		// Section holding an arbitrary control. The switch reveals the debug wireframes of this pane
		let wireframes = layoutView.addColumnSection(label: String(localized: "Wireframes"),
													 identifier: .init("Wireframes"))
		let wireframeSwitch = DemoSwitch { [weak self] isOn in
			self?.layoutView?.debug_setWireframes(isOn)
		}
		wireframes.addCustomView(wireframeSwitch, verticalAlignment: .centerY)
	}

}

// Section-based layout
class ViewSettingsPaneViewController: SettingsPaneViewController {

	/// The narrowest width this pane is laid out for
	private static let minimumPaneWidth: CGFloat = 500
	
	/// Keeps the item column from stretching across the whole pane
	private static let itemColumnMaximumWidth: CGFloat = 260
	
	private var layoutView: SettingsLayoutView?


	// MARK: -
	
	override func loadView() {
		// Setup the custom content view. This pane has no storyboard scene
		view = NSView()

		buildSections()
		sizePaneToFitContent(minimumWidth: Self.minimumPaneWidth)
	}
	
	private func buildSections() {
		let layoutView = SettingsLayoutView()
		layoutView.install(in: view)
		self.layoutView = layoutView
		
		// Section with a segmented control. The upper bound passed here governs the item column of every section
		let appearance = layoutView.addColumnSection(label: String(localized: "Appearance"),
													 itemColumnMaximumWidth: Self.itemColumnMaximumWidth,
													 identifier: .init("Appearance"))
		let appearanceSelector = NSSegmentedControl(labels: [String(localized: "Light"),
															 String(localized: "Dark"),
															 String(localized: "Auto")],
													trackingMode: .selectOne,
													target: self,
													action: nil)
		appearanceSelector.selectedSegment = 2
		appearanceSelector.controlSize = .small
		appearance.addCustomView(appearanceSelector)
		
		// Section whose item carries an accessory view on its trailing side
		let accentColor = layoutView.addColumnSection(label: String(localized: "Accent Color"), identifier: .init("Accent Color"))
		let colorWell = NSColorWell()
		colorWell.color = .controlAccentColor
		colorWell.widthAnchor.constraint(equalToConstant: 44).isActive = true
		accentColor.addCustomView(colorWell, verticalAlignment: .centerY)
		
		let resetButton = NSButton(title: String(localized: "Reset"),
								   target: self,
								   action: nil)
		resetButton.bezelStyle = .push
		resetButton.controlSize = .small
		accentColor.addAccessoryView(resetButton, to: colorWell)
		
		// Section with multiple items followed by a description label
		let sidebar = layoutView.addColumnSection(label: String(localized: "Sidebar"), identifier: .init("Sidebar"))
		sidebar.addCheckbox(title: String(localized: "Show sidebar"),
							isOn: true,
							target: self,
							action: nil)
		sidebar.addCheckbox(title: String(localized: "Show icons only"),
							target: self,
							action: nil)
		sidebar.addDescriptionLabel(String(localized: "VIEW_SIDEBAR_DESCRIPTION"))
		
		// Section with a slider. Sliders have no intrinsic width, so the width comes from a constraint
		let textSize = layoutView.addColumnSection(label: String(localized: "Text Size"), identifier: .init("Text Size"))
		let textSizeSlider = NSSlider(value: 13,
									  minValue: 10,
									  maxValue: 20,
									  target: self,
									  action: nil)
		textSizeSlider.numberOfTickMarks = 6
		textSizeSlider.allowsTickMarkValuesOnly = true
		textSizeSlider.widthAnchor.constraint(equalToConstant: 200).isActive = true
		textSize.addCustomView(textSizeSlider, verticalAlignment: .centerY)
		textSize.addDescriptionLabel(String(localized: "VIEW_TEXT_SIZE_DESCRIPTION"))
		
		layoutView.addSeparatorSection()
		
		// Content block section that places a checkbox and its description without the label column
		layoutView.addCheckboxSection(title: String(localized: "Align to block"),
									  isOn: true,
									  description: String(localized: "VIEW_ALIGN_BLOCK_DESCRIPTION"),
									  widthMode: .contentBlock,
									  identifier: .init("Align to block"),
									  target: self,
									  action: nil)
		
		layoutView.addSeparatorSection()
		
		// Full-width section that places a checkbox and its description without the label column
		layoutView.addCheckboxSection(title: String(localized: "Full-width"),
									  isOn: true,
									  description: String(localized: "VIEW_FULL_WIDTH_DESCRIPTION"),
									  widthMode: .fullWidth,
									  identifier: .init("Full-width"),
									  target: self,
									  action: nil)
		
		layoutView.addSeparatorSection()
		
		// Buttons laid out in the content block. Their area matches the two-column sections above, so the alignment stops at the block edges
		layoutView.addButtonSection(title: String(localized: "Centered in the block"),
									controlSize: .small,
									alignment: .center,
									widthMode: .contentBlock,
									identifier: .init("Block Center Button"),
									target: self,
									action: nil)
		
		layoutView.addButtonSection(title: String(localized: "Leading in the block"),
									controlSize: .small,
									alignment: .leading,
									widthMode: .contentBlock,
									identifier: .init("Block Leading Button"),
									target: self,
									action: nil)
		
		layoutView.addButtonSection(title: String(localized: "Trailing in the block"),
									controlSize: .small,
									alignment: .trailing,
									widthMode: .contentBlock,
									identifier: .init("Block Trailing Button"),
									target: self,
									action: nil)
		
		layoutView.addSeparatorSection()
		
		// The same three buttons in full-width mode. Their area is the whole container, so the alignment reaches the pane edges
		layoutView.addButtonSection(title: String(localized: "Centered in the container"),
									controlSize: .small,
									alignment: .center,
									identifier: .init("Container Center Button"),
									target: self,
									action: nil)
		
		layoutView.addButtonSection(title: String(localized: "Leading in the container"),
									controlSize: .small,
									alignment: .leading,
									identifier: .init("Container Leading Button"),
									target: self,
									action: nil)
		
		layoutView.addButtonSection(title: String(localized: "Trailing in the container"),
									controlSize: .small,
									alignment: .trailing,
									identifier: .init("Container Trailing Button"),
									target: self,
									action: nil)
		
		layoutView.addSeparatorSection()
		
		// Section holding an arbitrary control. The switch reveals the debug wireframes of this pane
		let wireframes = layoutView.addColumnSection(label: String(localized: "Wireframes"), identifier: .init("Wireframes"))
		let wireframeSwitch = DemoSwitch { [weak self] isOn in
			self?.layoutView?.debug_setWireframes(isOn)
		}
		wireframes.addCustomView(wireframeSwitch, verticalAlignment: .centerY)
	}

}

// Storyboard-based layout
class ExtensionsSettingsPaneViewController: SettingsPaneViewController {}

// Guide-based layout
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
		
		// 4: Update preferred pane size
		capturePreferredPaneSize()
	}

}

// Guide-based layout
class DeveloperSettingsPaneViewController: SettingsPaneViewController, SettingsPaneLayoutGuide {

	var contentContainerView: SettingsPaneContainerView?
	
	override func loadView() {
		// Setup the custom content view
		
		// View with default pane size
		view = NSView(frame: NSMakeRect(0, 0, 500, 280))
		
		// Set minimum / maximum size of this pane
		NSLayoutConstraint.activate([
			view.widthAnchor.constraint(greaterThanOrEqualToConstant: 300), // Minimum width
			view.heightAnchor.constraint(greaterThanOrEqualToConstant: 280), // Minimum height
			view.widthAnchor.constraint(lessThanOrEqualToConstant: 800), // Maximum width
			view.heightAnchor.constraint(lessThanOrEqualToConstant: 700), // Maximum height
		])
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// ----- Demo for setup the layout container -----
		
		// 1: First, prepare the container view with any maximum width value (or setting it to nil allows the container to behave flexibly)
		setContentContainerView(maximumWidth: nil)
		
		// 2: If necessary, enable wireframes for debugging. (Only effective in `DEBUG` build.)
		contentContainerView?.debug_setWireframes(true)
		
		buildUI()
		
		// 3: Update preferred pane size
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
			let item = DemoSwitch(isOn: state == .on) { [weak self] isOn in
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
