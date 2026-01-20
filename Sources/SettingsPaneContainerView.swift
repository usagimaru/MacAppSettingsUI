//
//  SettingsPaneContainerView.swift
//
//  Created by usagimaru on 2026/01/19.
//

import Cocoa

open class SettingsPaneContainerView: NSView {
	
	public private(set) var labelLayoutGuide = NSLayoutGuide()
	public private(set) var labelLayoutGuideWidthConstraints = [NSLayoutConstraint]()
	public private(set) var secondaryAreaLayoutGuide = NSLayoutGuide()
	public private(set) var containerWidthConstraints = [NSLayoutConstraint]()
	
	public static var idscope: String {
		"MacAppSettingsUI"
	}
	
	/// Set maximum width of the container. Setting it to nil allows the container to behave flexibly.
	open var containerMaximumWidth: CGFloat? { didSet {
		updateConstraints()
	}}
	
	/// Set width of the label layout guide.
	open var labelLayoutGuideWidth: CGFloat = 200 { didSet {
		updateConstraints()
	}}
	
	open var spacingOfHorizontalAreas: CGFloat = 8
	
	private var debug_layer_labelGuideText = CATextLayer()
	private var debug_layer_secondaryAreaGuideText = CATextLayer()
	private var debug_layer_entireViewText = CATextLayer()
	private var debug_layer_labelGuide = CALayer()
	private var debug_layer_secondaryAreaGuide = CALayer()
	private var debug_layer_entireView = CALayer()
	
	
	// MARK: -
	
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
	open func setView(to superview: NSView) {
		translatesAutoresizingMaskIntoConstraints = false
		
		NSLayoutConstraint.deactivate(constraintsAffectingLayout(for: .horizontal))
		NSLayoutConstraint.deactivate(constraintsAffectingLayout(for: .vertical))
		
		topAnchor.constraint(equalTo: superview.topAnchor, constant: 0).isActive = true
		superview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
		
		centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
		
		let containerLeading1 = leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor, constant: 0)
		containerLeading1.identifier = "\(Self.idscope).ContainerView.leading.1"
		containerLeading1.priority = .defaultHigh
		containerLeading1.isActive = true
		
		let containerTrailing1 = superview.trailingAnchor.constraint(greaterThanOrEqualTo: trailingAnchor, constant: 0)
		containerTrailing1.identifier = "\(Self.idscope).ContainerView.trailing.1"
		containerTrailing1.priority = .defaultHigh
		containerTrailing1.isActive = true
		
		let containerLeading2 = leadingAnchor.constraint(equalTo: superview.leadingAnchor)
		containerLeading2.identifier = "\(Self.idscope).ContainerView.leading.2"
		containerLeading2.priority = .defaultLow
		containerLeading2.isActive = true
		
		let containerTrailing2 = superview.trailingAnchor.constraint(equalTo: trailingAnchor)
		containerTrailing2.identifier = "\(Self.idscope).ContainerView.trailing.2"
		containerTrailing2.priority = .defaultLow
		containerTrailing2.isActive = true
		
		containerWidthConstraints = [containerLeading2, containerTrailing2]
		
		if let containerMaximumWidth {
			containerWidthConstraints.forEach {
				$0.isActive = false
			}
			
			let containerWidth = widthAnchor.constraint(equalToConstant: containerMaximumWidth)
			containerWidth.identifier = "\(Self.idscope).ContainerView.width"
			containerWidth.priority = .defaultLow
			containerWidth.isActive = true
			containerWidthConstraints.append(containerWidth)
		}
		
		if labelLayoutGuide.owningView == nil {
			addLayoutGuide(labelLayoutGuide)
			labelLayoutGuide.identifier = .init("\(Self.idscope).LabelLayoutGuide")
			labelLayoutGuide.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1).isActive = true
			bottomAnchor.constraint(equalToSystemSpacingBelow: labelLayoutGuide.bottomAnchor, multiplier: 1).isActive = true
			labelLayoutGuide.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1).isActive = true
			
			let w1 = labelLayoutGuide.widthAnchor.constraint(equalToConstant: labelLayoutGuideWidth)
			w1.identifier = .init("\(Self.idscope).LabelLayoutGuide.width.1")
			w1.priority = .defaultLow
			w1.isActive = true
			
			let c = labelLayoutGuide.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1).constant
			let w2 = labelLayoutGuide.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.5, constant: -c)
			w2.identifier = .init("\(Self.idscope).LabelLayoutGuide.width.2")
			w2.priority = .defaultLow
			w2.isActive = true
			
			labelLayoutGuideWidthConstraints = [w1, w2]
		}
		if secondaryAreaLayoutGuide.owningView == nil {
			addLayoutGuide(secondaryAreaLayoutGuide)
			secondaryAreaLayoutGuide.identifier = .init("\(Self.idscope).SecondaryAreaLayoutGuide")
			secondaryAreaLayoutGuide.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1).isActive = true
			bottomAnchor.constraint(equalToSystemSpacingBelow: secondaryAreaLayoutGuide.bottomAnchor, multiplier: 1).isActive = true
			//secondaryAreaLayoutGuide.leadingAnchor.constraint(equalToSystemSpacingAfter: labelLayoutGuide.trailingAnchor, multiplier: 1).isActive = true // crash
			secondaryAreaLayoutGuide.leadingAnchor.constraint(equalTo: labelLayoutGuide.trailingAnchor, constant: spacingOfHorizontalAreas).isActive = true
			trailingAnchor.constraint(equalToSystemSpacingAfter: secondaryAreaLayoutGuide.trailingAnchor, multiplier: 1).isActive = true
		}
		else {
			//secondaryAreaLayoutGuide.leadingAnchor.constraint(equalToSystemSpacingAfter: labelLayoutGuide.trailingAnchor, multiplier: 1).isActive = true // crash
			secondaryAreaLayoutGuide.leadingAnchor.constraint(equalTo: labelLayoutGuide.trailingAnchor, constant: spacingOfHorizontalAreas).isActive = true
		}
	}
	
	open override func updateConstraints() {
		super.updateConstraints()
		
		labelLayoutGuideWidthConstraints.filter { $0.identifier == "\(Self.idscope).LabelLayoutGuide.width.1" }.first?
			.constant = labelLayoutGuideWidth
		
		if let containerMaximumWidth {
			containerWidthConstraints.forEach {
				if $0.identifier == "\(Self.idscope).ContainerView.width" {
					$0.constant = containerMaximumWidth
					$0.isActive = true
				}
				else {
					$0.isActive = false
				}
			}
		}
		else {
			containerWidthConstraints.forEach {
				if $0.identifier == "\(Self.idscope).ContainerView.width" {
					$0.constant = 0
					$0.isActive = false
				}
				else {
					$0.isActive = true
				}
			}
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
	
	private func debug_allLayers() -> [CALayer] {
		[
			debug_layer_labelGuideText,
			debug_layer_secondaryAreaGuideText,
			debug_layer_entireViewText,
			debug_layer_labelGuide,
			debug_layer_secondaryAreaGuide,
			debug_layer_entireView,
		]
	}
	
	/// Toggle debug layers
	func debug_setWireframes(_ flag: Bool) {
#if DEBUG
		debug_allLayers().forEach { $0.isHidden = !flag }
#else
		debug_allLayers().forEach { $0.isHidden = true }
#endif
	}
	
	private func debug_setup() {
		func setupTextLayer(_ textLayer: CATextLayer, string: String, addTo: CALayer) {
			addTo.insertSublayer(textLayer, above: nil)
			textLayer.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
			textLayer.fontSize = NSFont.smallSystemFontSize
			textLayer.alignmentMode = .center
			textLayer.string = string
		}
		
		layer?.insertSublayer(debug_layer_labelGuide, at: 0)
		debug_layer_labelGuide.borderWidth = 1
		
		layer?.insertSublayer(debug_layer_secondaryAreaGuide, at: 0)
		debug_layer_secondaryAreaGuide.borderWidth = 1
		
		layer?.insertSublayer(debug_layer_entireView, at: 0)
		debug_layer_entireView.borderWidth = 1
		
		setupTextLayer(debug_layer_labelGuideText, string: "Label area", addTo: debug_layer_labelGuide)
		setupTextLayer(debug_layer_secondaryAreaGuideText, string: "Secondary area", addTo: debug_layer_secondaryAreaGuide)
		setupTextLayer(debug_layer_entireViewText, string: "Container view", addTo: debug_layer_entireView)
		
		layerUsesCoreImageFilters = true
		debug_layer_labelGuideText.compositingFilter = CIFilter(name: "CIColorBurnBlendMode")
		debug_layer_secondaryAreaGuideText.compositingFilter = CIFilter(name: "CIColorBurnBlendMode")
		debug_layer_entireViewText.compositingFilter = CIFilter(name: "CIColorBurnBlendMode")
		
		debug_updateScales()
		debug_updateColors()
		
		debug_setWireframes(false)
	}
	
	private func debug_updateScales() {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		debug_allLayers().forEach {
			$0.contentsScale = window?.backingScaleFactor ?? 1.0
			$0.rasterizationScale = window?.backingScaleFactor ?? 1.0
		}
		
		CATransaction.commit()
	}
	
	private func debug_updateColors() {
		debug_layer_labelGuide.backgroundColor = NSColor.systemRed.withAlphaComponent(0.1).cgColor
		debug_layer_labelGuide.borderColor = NSColor.systemRed.withAlphaComponent(0.5).cgColor
		debug_layer_labelGuideText.foregroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
		
		debug_layer_secondaryAreaGuide.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.2).cgColor
		debug_layer_secondaryAreaGuide.borderColor = NSColor.systemGreen.withAlphaComponent(0.6).cgColor
		debug_layer_secondaryAreaGuideText.foregroundColor = NSColor.black.withAlphaComponent(0.4).cgColor
		
		debug_layer_entireView.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.1).cgColor
		debug_layer_entireView.borderColor = NSColor.systemBlue.withAlphaComponent(0.5).cgColor
		debug_layer_entireViewText.foregroundColor = NSColor.black.withAlphaComponent(0.35).cgColor
	}
	
	private func debug_layoutLayers() {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		debug_layer_labelGuide.frame = labelLayoutGuide.frame
		debug_layer_secondaryAreaGuide.frame = secondaryAreaLayoutGuide.frame
		debug_layer_entireView.frame = bounds
		
		debug_layer_labelGuideText.frame.size = debug_layer_labelGuideText.preferredFrameSize()
		debug_layer_labelGuideText.frame.origin = .init(x: debug_layer_labelGuide.bounds.maxX - debug_layer_labelGuideText.bounds.width - 3, y: 3)
		
		debug_layer_secondaryAreaGuideText.frame.size = debug_layer_secondaryAreaGuideText.preferredFrameSize()
		debug_layer_secondaryAreaGuideText.frame.origin = .init(x: 3, y: 3)
		
		debug_layer_entireViewText.frame.size = debug_layer_entireViewText.preferredFrameSize()
		debug_layer_entireViewText.frame.origin = .init(x: 12, y: 3)
		
		CATransaction.commit()
	}
	
}
