//
//  SettingsHostingView.swift
//
//  Created by usagimaru on 2026/08/24.
//

import Cocoa
import SwiftUI

/// Hosts a SwiftUI view and measures its height against the width it is given
open class SettingsHostingView<Content: View>: NSView {
	
	// A hosting view sizes itself from an unspecified proposal, so content whose height follows its width comes out short
	
	/// Stands in for an unbounded proposal. Computed, since a generic type takes no static stored property
	private static var unboundedLength: CGFloat { 10_000 }
	
	private let hostingController: NSHostingController<Content>
	private var lastMeasuredWidth: CGFloat = .nan
	
	
	// MARK: -
	
	public init(rootView: Content) {
		hostingController = NSHostingController(rootView: rootView)
		super.init(frame: .zero)
		
		// This view reports the size, so the hosting side adds no constraints
		hostingController.sizingOptions = []
		
		let hostedView = hostingController.view
		hostedView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(hostedView)
		
		NSLayoutConstraint.activate([
			hostedView.topAnchor.constraint(equalTo: topAnchor),
			hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
			hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
			hostedView.bottomAnchor.constraint(equalTo: bottomAnchor),
		])
	}
	
	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	// MARK: -
	
	open var rootView: Content {
		get {
			hostingController.rootView
		}
		set {
			hostingController.rootView = newValue
			invalidateMeasuredSize()
		}
	}
	
	/// Measure again after the content changed from outside the SwiftUI state
	open func invalidateMeasuredSize() {
		lastMeasuredWidth = .nan
		invalidateIntrinsicContentSize()
	}
	
	open override var intrinsicContentSize: NSSize {
		// The first pass has no width yet, so the ideal width stands in
		let width = bounds.width > 0 ? bounds.width : Self.unboundedLength
		return hostingController.sizeThatFits(in: NSSize(width: width, height: Self.unboundedLength))
	}
	
	open override func layout() {
		super.layout()
		
		// A new width can mean a new height, so the engine is told to ask again
		if bounds.width != lastMeasuredWidth {
			lastMeasuredWidth = bounds.width
			invalidateIntrinsicContentSize()
		}
	}
	
}
