//
//  ViewSettingsPaneViewController.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/01/20.
//

import Cocoa

// Section-based layout
class ViewSettingsPaneViewController: SettingsPaneViewController {

	/// The narrowest width this pane is laid out for
	private static let minimumPaneWidth: CGFloat = 530
	
	/// Keeps the item column from stretching across the whole pane
	private static let itemColumnMaximumWidth: CGFloat = 260
	
	private var layoutView: SettingsLayoutView?
	
	
	// MARK: -
	
	override func loadView() {
		view = NSView()
	}
	
	override func buildPaneContent() {
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
		let wireframeSwitch = DemoSwitch(sizingWindow: tabViewController?.view.window) { [weak self] isOn in
			self?.layoutView?.debug_setWireframes(isOn)
		}
		wireframes.addCustomView(wireframeSwitch, verticalAlignment: .centerY)

		let layoutNoteLabel = SettingsWrappingLabel(string: String(localized: "Section-based layout 2"))
		layoutNoteLabel.alignment = .center
		layoutView.addCustomSection(layoutNoteLabel, identifier: .init("Layout Note"))
	}

}
