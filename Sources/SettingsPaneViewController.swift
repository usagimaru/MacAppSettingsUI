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
	
	/// The preferred size for this pane, captured from the initial view frame set by Storyboard or `loadView()`.
	/// `SettingsTabViewController` uses this to determine the window size for each tab.
	/// Subclasses can override this if the pane size should differ from the initial frame.
	open var preferredPaneSize: NSSize?

	/// The smallest size this pane can be laid out at
	open var minimumPaneSize: NSSize?

	/// The largest size this pane allows. nil leaves the pane unbounded
	open var maximumPaneSize: NSSize?

	/// Lower bound kept so the pane can be measured again
	public private(set) var minimumPaneWidth: CGFloat = 0

	/// Guard against a layout that never converges
	private static let paneSizeMeasurementPassLimit = 4
	
	private var minimumPaneWidthConstraint: NSLayoutConstraint?
	
	
	// MARK: -
	
	open override func viewDidLoad() {
		super.viewDidLoad()
		// Resolve Auto Layout constraints and capture the resulting size as the preferred pane size.
		// For storyboard-based views, constraints determine the final layout size.
		// For code-based views, the frame set in loadView() is used as-is if no constraints override it.
		if preferredPaneSize == nil {
			capturePreferredPaneSize()
		}
	}
	
	/// Record the laid-out frame size as `preferredPaneSize`. Call at the end of `loadView()` or `viewDidLoad()`
	open func capturePreferredPaneSize() {
		view.layoutSubtreeIfNeeded()
		preferredPaneSize = view.frame.size
	}
	
	/// Override this method to build heavy pane content (table views, SwiftUI hosting views, data loading) and keep `loadView` light.
	/// Data may be prepared on any queue, but build views and call the completion on the main thread.
	/// `isPaneContentLoaded` is managed by the caller. The default implementation calls the completion immediately.
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
	
	public class func fromStoryboard(_ storyboardName: String? = nil,
									 viewControllerIdentifier: NSStoryboard.SceneIdentifier? = nil,
									 tabViewController: SettingsTabViewController? = nil,
									 tabName: String? = nil,
									 localizeKeyForTabName: String? = nil,
									 tabImage: NSImage? = nil,
									 tabIdentifier: String? = nil,
									 isResizableView: Bool? = nil) -> Self {
		let vc = NSStoryboard(name: storyboardName ?? "Main", bundle: nil).instantiateController(withIdentifier: viewControllerIdentifier ?? "\(Self.self)") as! Self
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
	
	/// Give the pane a lower bound and shrink-wrap it to its sections. Call at the end of `loadView()` or `viewDidLoad()`
	open func sizePaneToFitContent(minimumWidth: CGFloat) {
		minimumPaneWidth = minimumWidth
		
		// Reusing one constraint keeps repeated calls from stacking lower bounds
		if let minimumPaneWidthConstraint {
			minimumPaneWidthConstraint.constant = minimumWidth
		}
		else {
			let constraint = view.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumWidth)
			constraint.isActive = true
			minimumPaneWidthConstraint = constraint
		}
		
		// The width has to settle before the height, since it decides how many lines the descriptions take
		view.setFrameSize(NSSize(width: minimumWidth, height: 0))
		view.layoutSubtreeIfNeeded()
		
		// Wrapping widths only settle during layout, so measure until the size stops moving
		var previousFittingSize = NSSize.zero
		for _ in 0 ..< Self.paneSizeMeasurementPassLimit {
			let fittingSize = view.fittingSize
			view.setFrameSize(fittingSize)
			view.layoutSubtreeIfNeeded()
			
			if fittingSize == previousFittingSize {
				break
			}
			previousFittingSize = fittingSize
		}

		capturePreferredPaneSize()

		// Measured at the width that settled, or a narrower one would wrap the labels and report a taller pane
		minimumPaneSize = measureMinimumPaneSize(width: preferredPaneSize?.width ?? minimumWidth)
	}

	/// Measure the pane with its stretching sections pulled down to their lower bounds
	private func measureMinimumPaneSize(width: CGFloat) -> NSSize {
		guard let layoutView = sectionLayoutView else {
			return NSSize(width: width, height: view.fittingSize.height)
		}

		let sizeToRestore = view.frame.size
		layoutView.setPreferredSectionHeightsActive(false)
		view.setFrameSize(NSSize(width: width, height: 0))
		view.layoutSubtreeIfNeeded()
		let minimumSize = NSSize(width: width, height: view.fittingSize.height)

		layoutView.setPreferredSectionHeightsActive(true)
		view.setFrameSize(sizeToRestore)
		view.layoutSubtreeIfNeeded()

		return minimumSize
	}

	/// The section layout view laid into this pane
	private var sectionLayoutView: SettingsLayoutView? {
		view.subviews.compactMap { $0 as? SettingsLayoutView }.first
	}
	
	/// Measure the pane again and refresh the cached window size. Call after the content, font size or locale changed
	open func invalidatePaneSize() {
		guard isViewLoaded else { return }
		
		if minimumPaneWidthConstraint != nil {
			sizePaneToFitContent(minimumWidth: minimumPaneWidth)
		}
		else {
			capturePreferredPaneSize()
		}
		
		tabViewController?.invalidateCachedSize(for: self)
	}
	
}
