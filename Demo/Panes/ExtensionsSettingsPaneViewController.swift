//
//  ExtensionsSettingsPaneViewController.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/01/20.
//

import Cocoa

// Section-based layout that declares no width for the item column
class ExtensionsSettingsPaneViewController: SettingsPaneViewController {

	/// The narrowest width this pane is laid out for
	private static let minimumPaneWidth: CGFloat = 530
	private static let extensionNameColumnIdentifier = NSUserInterfaceItemIdentifier("Name")

	private var layoutView: SettingsLayoutView?

	private let installedExtensionNames = [String(localized: "Markdown Preview"),
										   String(localized: "Image Optimizer"),
										   String(localized: "Color Picker"),
										   String(localized: "Snippet Manager"),
										   String(localized: "Terminal Helper"),
										   String(localized: "Clipboard History")]


	// MARK: -
	
	// [Reference for deferred pane loading]
	//   1. Keep loadView to the bare view, so switching to this tab costs nothing
	//   2. Override loadPaneContent() when the content has to be awaited, or buildPaneContent() when it does not
	//   3. Leaving the pane mid-load cancels the task, so the awaited call throws and the pane stays unloaded
	// The library covers the rest: the placeholder, measuring the pane and resizing the window

	override func loadView() {
		view = NSView()
	}

	// Simulates fetching the extension list, so the loading wait is visible in this demo
	override func loadPaneContent() async throws {
		// Raised for this pane alone, or panes with no wait would flash the label
		tabViewController?.showsLoadingLabel = true
		defer { tabViewController?.showsLoadingLabel = false }

		try await Task.sleep(for: .seconds(1))

		buildSections()
		sizePaneToFitContent(minimumWidth: Self.minimumPaneWidth)

		// Only the height is draggable here, so both bounds share the width that settled
		let fixedWidth = preferredPaneSize?.width ?? Self.minimumPaneWidth
		minimumPaneSize = NSSize(width: fixedWidth, height: minimumPaneSize?.height ?? 0)
		maximumPaneSize = NSSize(width: fixedWidth, height: .greatestFiniteMagnitude)
	}

	private func buildSections() {
		// Guards against a rebuild after a cancelled load
		self.layoutView?.removeFromSuperview()

		let layoutView = SettingsLayoutView()
		layoutView.install(in: view)
		self.layoutView = layoutView

		// The labels here are far shorter than the items, so the block would sit off-center without a floor
		layoutView.labelColumnMinimumWidth = 100
		
		// No section declares a width here, so the item column hugs the widest item across the pane
		let installed = layoutView.addColumnSection(label: "A",
													identifier: .init("Installed"))
		installed.addCheckbox(title: String(localized: "Quick Look"),
							  isOn: true,
							  target: self,
							  action: nil)
		installed.addCheckbox(title: String(localized: "Share Menu"),
							  isOn: true,
							  target: self,
							  action: nil)
		installed.addCheckbox(title: String(localized: "Finder Sync"),
							  target: self,
							  action: nil)
		
		let updateChannel = layoutView.addColumnSection(label: "B",
														identifier: .init("Update Channel"))
		let channelSelector = updateChannel.addPopUpButton(target: self, action: nil)
		channelSelector.addItems(withTitles: [String(localized: "Stable"),
											  String(localized: "Beta")])
		updateChannel.addDescriptionLabel(String(localized: "EXTENSIONS_UPDATE_CHANNEL_DESCRIPTION"))
		
		layoutView.addSeparatorSection()
		
		let thirdParty = layoutView.addColumnSection(label: "C",
													 identifier: .init("Third-Party"))
		thirdParty.addCheckbox(title: String(localized: "Allow unsigned extensions"),
							   target: self,
							   action: nil)
		
		// Section that takes in the surplus height of the pane, so the list grows as the window is dragged taller
		let installedList = layoutView.addColumnSection(label: "D",
														heightMode: .flexible(minimumHeight: 60, preferredHeight: 120),
														identifier: .init("Installed List"))
		installedList.addStretchingCustomView(makeExtensionListView())

		layoutView.addSeparatorSection()

		// Section holding an arbitrary control. The switch reveals the debug wireframes of this pane
		let wireframes = layoutView.addColumnSection(label: "E", identifier: .init("Wireframes"))
		let wireframeSwitch = DemoSwitch(sizingWindow: tabViewController?.view.window) { [weak self] isOn in
			self?.layoutView?.debug_setWireframes(isOn)
		}
		wireframes.addCustomView(wireframeSwitch, verticalAlignment: .centerY)

		let layoutNoteLabel = SettingsWrappingLabel(string: String(localized: "Resizable height, 100 pt label column, 1000 ms deferred load"))
		layoutNoteLabel.alignment = .center
		layoutView.addCustomSection(layoutNoteLabel, identifier: .init("Layout Note"))
	}

	private func makeExtensionListView() -> NSScrollView {
		let tableView = NSTableView()
		tableView.headerView = nil
		tableView.style = .plain
		tableView.rowHeight = 20
		tableView.usesAlternatingRowBackgroundColors = true
		tableView.dataSource = self
		tableView.delegate = self
		tableView.addTableColumn(NSTableColumn(identifier: Self.extensionNameColumnIdentifier))

		let scrollView = NSScrollView()
		scrollView.documentView = tableView
		scrollView.borderType = .bezelBorder
		scrollView.hasVerticalScroller = true
		scrollView.autohidesScrollers = true

		return scrollView
	}

}

extension ExtensionsSettingsPaneViewController: NSTableViewDataSource, NSTableViewDelegate {

	func numberOfRows(in tableView: NSTableView) -> Int {
		installedExtensionNames.count
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let label = NSTextField(labelWithString: installedExtensionNames[row])
		label.lineBreakMode = .byTruncatingTail
		label.translatesAutoresizingMaskIntoConstraints = false

		// A bare label draws its text at the top of the row, so it is centered inside a cell view
		let cellView = NSTableCellView()
		cellView.addSubview(label)
		cellView.textField = label

		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: cellView.leadingAnchor),
			label.trailingAnchor.constraint(lessThanOrEqualTo: cellView.trailingAnchor),
			label.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
		])

		return cellView
	}

}
