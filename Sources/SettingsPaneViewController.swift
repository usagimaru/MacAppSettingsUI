//
//  SettingsPaneViewController.swift
//
//  Created by usagimaru on 2024/03/07.
//

import Cocoa

open class SettingsPaneViewController: NSViewController {
	
	open weak var tabViewController: SettingsTabViewController?
	
	/// Tab name passed to NSTabViewItem.label. Can be nil when a localization key is given instead
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

	/// Whether the content has been loaded. Managed by `SettingsTabViewController`
	open var isPaneContentLoaded: Bool = false

	/// The size this pane wants, captured from the frame set by Storyboard or `loadView()`
	open var preferredPaneSize: NSSize?

	/// The smallest size this pane can be laid out at
	open var minimumPaneSize: NSSize?

	/// The largest size this pane allows. nil leaves the pane unbounded
	open var maximumPaneSize: NSSize?

	/// Lower bound of the pane width. nil lets the width follow the content
	public private(set) var minimumPaneWidth: CGFloat?
	
	/// Lower bound of the pane height. nil lets the height follow the content
	public private(set) var minimumPaneHeight: CGFloat?

	/// Guard against a layout that never converges
	private static let paneSizeMeasurementPassLimit = 4
	
	/// Whether the pane was shrink-wrapped, so it can be measured again the same way
	private var fitsPaneToContent = false
	
	private var minimumPaneWidthConstraint: NSLayoutConstraint?
	
	
	// MARK: -
	
	open override func viewDidLoad() {
		super.viewDidLoad()
		// A pane that declares no size falls back to what its constraints or its initial frame settle on
		if preferredPaneSize == nil {
			capturePreferredPaneSize()
		}
	}
	
	/// Record the laid-out frame size as `preferredPaneSize`. Call at the end of `loadView()` or `viewDidLoad()`
	open func capturePreferredPaneSize() {
		view.layoutSubtreeIfNeeded()
		preferredPaneSize = view.frame.size
	}
	
	/// Build the pane content here, keeping `loadView` to the bare view
	open func buildPaneContent() {}
	
	/// Called once the content is in place, on the main thread
	open func paneContentDidLoad() {}
	
	/// Called when the content failed to load. Cancellation is not a failure, so it is not reported here
	open func paneContentDidFailToLoad(_ error: Error) {}
	
	/// Override when the content needs awaiting. Returning means the content is built, throwing means none of it is
	open func loadPaneContent() async throws {
		buildPaneContent()
	}
	
	/// Create a pane manually
	/// - Parameters:
	///   - tabViewController: Parent tab view controller, if the pane needs it
	///   - tabName: Default tab name
	///   - tabImage: Tab image
	///   - tabIdentifier: Unique tab identifier
	///   - isResizableView: Whether the window becomes resizable on this pane
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
	
	/// Give the pane its lower bounds and shrink-wrap it to its sections. Call at the end of `loadView()` or `viewDidLoad()`
	/// - Parameters:
	///   - minimumWidth: Lower bound of the pane width. Leaving it out lets the pane follow its content
	///   - minimumHeight: Lower bound of the pane height. Leaving it out lets the pane follow its content
	open func sizePaneToFitContent(minimumWidth: CGFloat? = nil, minimumHeight: CGFloat? = nil) {
		minimumPaneWidth = minimumWidth
		minimumPaneHeight = minimumHeight
		fitsPaneToContent = true
		
		updateMinimumPaneWidthConstraint()
		
		// The width settles first, since it decides how many lines the descriptions take
		view.setFrameSize(NSSize(width: minimumWidth ?? view.frame.width, height: 0))
		view.layoutSubtreeIfNeeded()

		// Wrapping widths only settle during layout, so measured until the size stops moving
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

		// Sparse content would leave the pane tiny, so the floor is applied first
		if let minimumPaneHeight, view.frame.height < minimumPaneHeight {
			view.setFrameSize(NSSize(width: view.frame.width, height: minimumPaneHeight))
			view.layoutSubtreeIfNeeded()
		}
		
		capturePreferredPaneSize()

		// Measured at the settled width, or a narrower one would wrap the labels and report a taller pane
		minimumPaneSize = measureMinimumPaneSize(width: preferredPaneSize?.width ?? view.frame.width)
	}
	
	private func updateMinimumPaneWidthConstraint() {
		guard let minimumPaneWidth else {
			minimumPaneWidthConstraint?.isActive = false
			return
		}
		
		// Reusing one constraint keeps repeated calls from stacking lower bounds
		if let minimumPaneWidthConstraint {
			minimumPaneWidthConstraint.constant = minimumPaneWidth
			minimumPaneWidthConstraint.isActive = true
		}
		else {
			let constraint = view.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumPaneWidth)
			constraint.isActive = true
			minimumPaneWidthConstraint = constraint
		}
	}

	/// Measure the pane with its stretching sections pulled down to their lower bounds
	private func measureMinimumPaneSize(width: CGFloat) -> NSSize {
		let heightFloor = minimumPaneHeight ?? 0
		
		guard let layoutView = sectionLayoutView else {
			return NSSize(width: width, height: max(view.fittingSize.height, heightFloor))
		}

		let sizeToRestore = view.frame.size
		layoutView.setPreferredSectionHeightsActive(false)
		view.setFrameSize(NSSize(width: width, height: 0))
		view.layoutSubtreeIfNeeded()
		let minimumSize = NSSize(width: width, height: max(view.fittingSize.height, heightFloor))

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
		
		if fitsPaneToContent {
			sizePaneToFitContent(minimumWidth: minimumPaneWidth, minimumHeight: minimumPaneHeight)
		}
		else {
			capturePreferredPaneSize()
		}
		
		tabViewController?.invalidateCachedSize(for: self)
	}
	
}
