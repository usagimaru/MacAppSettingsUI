//
//  SettingsTabLayoutView.swift
//
//  Created by usagimaru on 2026/08/26.
//

import Cocoa
import SwiftUI

/// A container that lays a nested tab view into a settings pane. It owns the tab geometry and reports the size the largest tab needs
open class SettingsTabLayoutView: NSView {
	
	/// Tighter than the system margin, so the tabs sit close under the toolbar
	public static let defaultTopMargin: CGFloat = 12
	
	/// The tab view this container owns
	public let tabView = NSTabView()
	
	
	// MARK: -
	
	public override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setUpTabView()
	}
	
	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		setUpTabView()
	}
	
	private func setUpTabView() {
		tabView.controlSize = .small
		// `controlSize` alone leaves the labels at the default size, so the font is set as well
		tabView.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
		tabView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(tabView)
		
		NSLayoutConstraint.activate([
			tabView.topAnchor.constraint(equalTo: topAnchor),
			tabView.leadingAnchor.constraint(equalTo: leadingAnchor),
			tabView.trailingAnchor.constraint(equalTo: trailingAnchor),
			tabView.bottomAnchor.constraint(equalTo: bottomAnchor),
		])
	}
	
	/// Lay this container into the pane view. The top edge is tighter than the system margin unless you pass your own insets
	open func install(in parentView: NSView, margins: SettingsLayoutMargins = .systemSpacing) {
		translatesAutoresizingMaskIntoConstraints = false
		parentView.addSubview(self, positioned: .below, relativeTo: nil)
		
		switch margins {
			case .systemSpacing:
				NSLayoutConstraint.activate([
					topAnchor.constraint(equalTo: parentView.topAnchor, constant: Self.defaultTopMargin),
					leadingAnchor.constraint(equalToSystemSpacingAfter: parentView.leadingAnchor, multiplier: 1),
					parentView.trailingAnchor.constraint(equalToSystemSpacingAfter: trailingAnchor, multiplier: 1),
					parentView.bottomAnchor.constraint(equalToSystemSpacingBelow: bottomAnchor, multiplier: 1),
				])
				
			case .insets(let insets):
				NSLayoutConstraint.activate([
					topAnchor.constraint(equalTo: parentView.topAnchor, constant: insets.top),
					leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: insets.leading),
					parentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: insets.trailing),
					parentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: insets.bottom),
				])
		}
	}
	
	
	// MARK: - Adding tabs
	
	/// Add a tab laid out with the section layout, and get that layout view back
	@discardableResult
	open func addSectionTab(label: String,
							identifier: String? = nil,
							margins: SettingsLayoutMargins = .systemSpacing) -> SettingsLayoutView
	{
		let layoutView = SettingsLayoutView()
		let contentView = NSView()
		layoutView.install(in: contentView, margins: margins)
		addTab(label: label, contentView: contentView, identifier: identifier)
		
		return layoutView
	}
	
	/// Add a tab hosting a SwiftUI view, and get that hosting view back
	@discardableResult
	open func addHostingTab<Content: View>(label: String,
										   rootView: Content,
										   identifier: String? = nil) -> SettingsHostingView<Content>
	{
		let hostingView = SettingsHostingView(rootView: rootView)
		hostingView.translatesAutoresizingMaskIntoConstraints = false
		
		// The hosting view measures itself against the width it is given, so it is centered rather than pinned
		let contentView = NSView()
		contentView.addSubview(hostingView)
		
		NSLayoutConstraint.activate([
			hostingView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.topAnchor, multiplier: 1),
			hostingView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
			hostingView.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 1),
			contentView.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: hostingView.trailingAnchor, multiplier: 1),
			contentView.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: hostingView.bottomAnchor, multiplier: 1),
		])
		
		addTab(label: label, contentView: contentView, identifier: identifier)
		
		return hostingView
	}
	
	/// Add a tab that takes any view
	@discardableResult
	open func addTab(label: String, contentView: NSView, identifier: String? = nil) -> NSTabViewItem {
		let item = identifier.map { NSTabViewItem(identifier: $0) } ?? NSTabViewItem()
		item.label = label
		item.view = contentView
		
		// Settled before the item goes in, or a still collapsed tab view would hand it the height of the tab strip alone
		layoutSubtreeIfNeeded()
		tabView.addTabViewItem(item)
		invalidateIntrinsicContentSize()
		
		return item
	}
	
	
	// MARK: - Sizing
	
	// A nested NSTabView reports no size upward, so this container measures the tabs and reports it in their place
	
	open override var intrinsicContentSize: NSSize {
		let contentSize = largestTabContentSize()
		guard contentSize.width > 0 || contentSize.height > 0 else {
			return super.intrinsicContentSize
		}
		
		let chromeSize = tabViewChromeSize()
		let insets = tabView.alignmentRectInsets
		
		// The tab strip can ask for more width than the content, and a tab is not to be cut off
		let minimumStripWidth = tabView.minimumSize.width - (insets.left + insets.right)
		
		return NSSize(width: max(contentSize.width + chromeSize.width, minimumStripWidth),
					  height: contentSize.height + chromeSize.height)
	}
	
	/// Measure the tabs again after their content changed
	open func invalidateMeasuredSize() {
		invalidateIntrinsicContentSize()
	}
	
	/// The size the widest and the tallest tab content need
	private func largestTabContentSize() -> NSSize {
		tabView.tabViewItems.compactMap { $0.view }.reduce(into: NSSize.zero) { largestSize, contentView in
			let fittingSize = contentView.fittingSize
			largestSize.width = max(largestSize.width, fittingSize.width)
			largestSize.height = max(largestSize.height, fittingSize.height)
		}
	}
	
	/// The frame the tab view draws around its content area, in the terms Auto Layout solves for
	private func tabViewChromeSize() -> NSSize {
		// Both rects carry their edges as insets, so the difference holds before the tab view has been laid out
		let alignmentRect = tabView.alignmentRect(forFrame: tabView.frame)
		let contentRect = tabView.contentRect
		
		return NSSize(width: alignmentRect.width - contentRect.width,
					  height: alignmentRect.height - contentRect.height)
	}
	
}
