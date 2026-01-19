//
//  SettingsPaneContainerView.swift
//
//  Created by usagimaru on 2026/01/19.
//

import Cocoa

open class SettingsPaneContainerView: NSView {
	
	public private(set) var labelLayoutGuide = NSLayoutGuide()
	public private(set) var labelLayoutWidthAnchor1: NSLayoutConstraint?
	public private(set) var labelLayoutWidthAnchor2: NSLayoutConstraint?
	public private(set) var maximumWidthAnchor: NSLayoutConstraint?
	
	private var debug_layer_labelGuideText = CATextLayer()
	private var debug_layer_entireViewText = CATextLayer()
	private var debug_layer_labelGuide = CALayer()
	private var debug_layer_entireView = CALayer()
	
	/// Set width of the label layout guide
	open func setLabelLayoutWidth(_ width: CGFloat) {
		labelLayoutWidthAnchor1?.constant = width
	}
	
	/// Set maximum width of the container
	open func setMaximumWidth(_ width: CGFloat) {
		if let maximumWidthAnchor {
			removeConstraint(maximumWidthAnchor)
		}
		
		translatesAutoresizingMaskIntoConstraints = false
		let w = widthAnchor.constraint(equalToConstant: width)
		w.priority = .defaultLow
		w.isActive = true
		maximumWidthAnchor = w
	}
	
	open override func viewDidMoveToSuperview() {
		wantsLayer = true
		
#if DEBUG
		debug_setup()
#endif
		
		if let superview {
			setView(to: superview)
		}
	}
	
	/// Set this view to specific parent view and prepare guides
	open func setView(to parentView: NSView) {
		translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.deactivate(constraintsAffectingLayout(for: .horizontal))
		NSLayoutConstraint.deactivate(constraintsAffectingLayout(for: .vertical))
		
		topAnchor.constraint(equalTo: parentView.topAnchor, constant: 0).isActive = true
		parentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
		
		let l = leadingAnchor.constraint(greaterThanOrEqualTo: parentView.leadingAnchor, constant: 0)
		l.priority = .defaultHigh
		l.isActive = true
		
		let t = parentView.trailingAnchor.constraint(greaterThanOrEqualTo: trailingAnchor, constant: 0)
		t.priority = .defaultHigh
		t.isActive = true
		
		centerXAnchor.constraint(equalTo: parentView.centerXAnchor).isActive = true
		
		if labelLayoutGuide.owningView == nil {
			addLayoutGuide(labelLayoutGuide)
			labelLayoutGuide.identifier = .init("MacAppSettingsUI.LabelLayoutGuide")
			labelLayoutGuide.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1).isActive = true
			bottomAnchor.constraint(equalToSystemSpacingBelow: labelLayoutGuide.bottomAnchor, multiplier: 1).isActive = true
			labelLayoutGuide.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1).isActive = true
		}
		if labelLayoutWidthAnchor1 == nil {
			let w1 = labelLayoutGuide.widthAnchor.constraint(equalToConstant: 200)
			w1.priority = .defaultLow
			w1.isActive = true
			labelLayoutWidthAnchor1 = w1
		}
		if labelLayoutWidthAnchor2 == nil {
			let c = labelLayoutGuide.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1).constant
			let w2 = labelLayoutGuide.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.5, constant: -c)
			w2.priority = .defaultLow
			w2.isActive = true
			labelLayoutWidthAnchor2 = w2
		}
	}
	
	open override func layout() {
		super.layout()
		debug_layoutLayers()
	}
	
	open override func viewDidChangeBackingProperties() {
		super.viewDidChangeBackingProperties()
		debug_updateScales()
	}
	
	open override func viewDidChangeEffectiveAppearance() {
		super.viewDidChangeEffectiveAppearance()
		debug_updateColors()
	}
	
}


// MARK: - Debug

public extension SettingsPaneContainerView {
	
	/// Toggle debug layers
	func debug_setWireframes(_ flag: Bool) {
		let layers = [
			debug_layer_labelGuideText,
			debug_layer_entireViewText,
			debug_layer_labelGuide,
			debug_layer_entireView,
		]
		
#if DEBUG
		layers.forEach { $0.isHidden = !flag }
#else
		layers.forEach { $0.isHidden = true }
#endif
	}
	
	private func debug_setup() {
		layer?.insertSublayer(debug_layer_labelGuide, at: 0)
		debug_layer_labelGuide.borderWidth = 1
		
		layer?.insertSublayer(debug_layer_entireView, at: 0)
		debug_layer_entireView.borderWidth = 1
		
		layer?.insertSublayer(debug_layer_labelGuideText, above: debug_layer_labelGuide)
		debug_layer_labelGuideText.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
		debug_layer_labelGuideText.fontSize = NSFont.systemFontSize
		debug_layer_labelGuideText.alignmentMode = .center
		debug_layer_labelGuideText.string = "Label layout guide"
		
		layer?.insertSublayer(debug_layer_entireViewText, above: debug_layer_entireView)
		debug_layer_entireViewText.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
		debug_layer_entireViewText.fontSize = NSFont.systemFontSize
		debug_layer_entireViewText.alignmentMode = .center
		debug_layer_entireViewText.string = "Container view"
		
		debug_updateScales()
		debug_updateColors()
	}
	
	private func debug_updateScales() {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		debug_layer_labelGuideText.contentsScale = window?.backingScaleFactor ?? 1.0
		debug_layer_entireViewText.contentsScale = window?.backingScaleFactor ?? 1.0
		debug_layer_labelGuide.contentsScale = window?.backingScaleFactor ?? 1.0
		debug_layer_entireView.contentsScale = window?.backingScaleFactor ?? 1.0
		
		CATransaction.commit()
	}
	
	private func debug_updateColors() {
		debug_layer_labelGuide.backgroundColor = NSColor.systemRed.withAlphaComponent(0.1).cgColor
		debug_layer_labelGuide.borderColor = NSColor.systemRed.withAlphaComponent(0.5).cgColor
		debug_layer_entireView.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.1).cgColor
		debug_layer_entireView.borderColor = NSColor.systemBlue.withAlphaComponent(0.5).cgColor
		debug_layer_labelGuideText.foregroundColor = NSColor.systemRed.withAlphaComponent(0.4).cgColor
		debug_layer_entireViewText.foregroundColor = NSColor.systemBlue.withAlphaComponent(0.4).cgColor
	}
	
	private func debug_layoutLayers() {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		debug_layer_labelGuide.frame = labelLayoutGuide.frame
		debug_layer_entireView.frame = bounds
		
		debug_layer_labelGuideText.frame.size = debug_layer_labelGuideText.preferredFrameSize()
		debug_layer_labelGuideText.frame.origin = .init(x: labelLayoutGuide.frame.minX + 3, y: labelLayoutGuide.frame.minY + 3)
		
		debug_layer_entireViewText.frame.size = debug_layer_entireViewText.preferredFrameSize()
		debug_layer_entireViewText.frame.origin = .init(x: bounds.maxX - debug_layer_entireViewText.frame.width - 8, y: 3)
		
		CATransaction.commit()
	}
	
}
