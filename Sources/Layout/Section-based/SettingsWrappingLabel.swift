//
//  SettingsWrappingLabel.swift
//
//  Created by usagimaru on 2026/08/04.
//

import Cocoa

/// A description label that shrinks to its text and wraps at a width handed down from the outside
open class SettingsWrappingLabel: NSTextField {

	/// Width the text wraps at. Deriving it from its own bounds instead would make the width chase itself
	open var availableWidth: CGFloat = 0 {
		didSet {
			guard availableWidth != oldValue else { return }

			preferredMaxLayoutWidth = availableWidth
			invalidateIntrinsicContentSize()
		}
	}

	public init(string: String) {
		super.init(frame: .zero)

		stringValue = string
		isEditable = false
		isBezeled = false
		isBordered = false
		// Turning drawsBackground off adds 2pt of alignmentRectInsets on both sides and shifts the label off the column
		backgroundColor = .clear
		isSelectable = false
		usesSingleLineMode = false
		lineBreakMode = .byWordWrapping
		maximumNumberOfLines = 0
		cell?.wraps = true
		cell?.isScrollable = false
		font = .systemFont(ofSize: NSFont.smallSystemFontSize)
		textColor = .secondaryLabelColor
		alignment = .natural

		// Take no part in deciding the column width, but do shrink the box down to the text
		setContentCompressionResistancePriority(SettingsLayoutPriority.nonContributing, for: .horizontal)
		setContentHuggingPriority(.defaultLow, for: .horizontal)
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	/// Width the text takes on a single line. The column asks for this much before settling on a narrower, wrapping box
	open var naturalTextWidth: CGFloat {
		let unbounded = NSRect(x: 0, y: 0, width: CGFloat(10000), height: CGFloat(10000))
		return cell?.cellSize(forBounds: unbounded).width ?? 0
	}

}
