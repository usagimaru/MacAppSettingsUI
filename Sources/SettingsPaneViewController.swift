//
//  SettingsPaneViewController.swift
//
//  Created by usagimaru on 2024/03/07.
//

import Cocoa

open class SettingsPaneViewController: NSViewController {
	
	open weak var tabViewController: SettingsTabViewController?
	
	/// The alias for view contrller’s `title`. Pass to NSTabViewItem.label. If when use `tabNameLocalizeKey`, this property can be nil
	@IBInspectable open var tabName: String? {
		get { title }
		set { title = newValue }
	}
	
	/// Localization key for Tab name. Pass to NSTabViewItem.label
	@IBInspectable open var localizeKeyForTabName: String?
	
	/// Pass to NSTabViewItem.image
	@IBInspectable open var tabImage: NSImage?
	
	/// Pass to NSTabViewItem.identifier
	@IBInspectable open var tabIdentifier: String?
	
	/// Make the window resizable when the view is activated
	@IBInspectable open var isResizableView: Bool = false

	/// Whether the pane content has been loaded via `loadPaneContent(completion:)`.
	/// This flag is managed by `SettingsTabViewController`.
	open var isPaneContentLoaded: Bool = false


	// MARK: -

	/// Override this method to perform asynchronous content loading before the pane is displayed.
	/// Call the completion handler when loading is finished.
	/// The `isPaneContentLoaded` flag is managed automatically by the caller; subclasses do not need to set it.
	/// The default implementation calls the completion immediately.
	open func loadPaneContent(completion: @escaping () -> Void) {
		completion()
	}

	/// Create View Controller Manually
	/// - Parameters:
	///   - tabViewController: Parent tab view controller if you will use it in the pane.
	///   - tabName: Default tab name
	///   - tabImage: Tab image
	///   - tabIdentifier: Unique tab identifier
	///   - isResizableView: Flag for resizable attribute (Default: false)
	public convenience init(tabViewController: SettingsTabViewController? = nil,
							tabName: String? = nil,
							tabImage: NSImage? = nil,
							tabIdentifier: String? = nil,
							isResizableView: Bool = false) {
		self.init()
		self.tabViewController = tabViewController
		self.tabName = tabName
		self.tabImage = tabImage
		self.tabIdentifier = tabIdentifier
		self.isResizableView = isResizableView
	}
	
}
