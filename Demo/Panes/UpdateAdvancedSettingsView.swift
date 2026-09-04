//
//  UpdateAdvancedSettingsView.swift
//  MacAppSettingsUI-Demo
//
//  Created by usagimaru on 2026/08/24.
//

import SwiftUI

/// The SwiftUI side of the “Updates” pane, hosted by `SettingsHostingView`. Pane sizing is tested against this view
struct UpdateAdvancedSettingsView: View {
	
	/// Release channel offered in this demo
	enum Channel: String, CaseIterable, Identifiable {
		case stable
		case beta
		
		var id: String { rawValue }
		
		var localizedName: String {
			switch self {
				case .stable:
					String(localized: "Stable")
				case .beta:
					String(localized: "Beta")
			}
		}
	}
	
	/// Keeps the wrapping description from stretching along with a resized window
	private static let contentMaximumWidth: CGFloat = 320
	
	var isDownloadAnimating: Bool = false
	
	@State private var channel: Channel = .stable
	@State private var allowsPrerelease = false
	@State private var keepsInstallers = true
	
	private let downloadProgress = 0.62
	
	
	// MARK: -
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			availabilityHeader
			channelBox
			versionRows
			descriptionText
		}
		.frame(maxWidth: Self.contentMaximumWidth, alignment: .leading)
	}
	
	private var availabilityHeader: some View {
		HStack(alignment: .top, spacing: 10) {
			UpdateDownloadIcon(isAnimating: isDownloadAnimating)
				.id(isDownloadAnimating)
			
			VStack(alignment: .leading, spacing: 2) {
				Text(String(localized: "UPDATE_AVAILABLE_TITLE"))
					.font(.headline)
				Text(String(localized: "UPDATE_AVAILABLE_DETAIL"))
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
		}
	}
	

	private var channelBox: some View {
		GroupBox(String(localized: "Update Channel")) {
			VStack(alignment: .leading, spacing: 8) {
				Picker(String(localized: "Update Channel"), selection: $channel) {
					ForEach(Channel.allCases) { channel in
						Text(channel.localizedName).tag(channel)
					}
				}
				.pickerStyle(.segmented)
				.labelsHidden()
				
				Toggle(String(localized: "Allow prerelease builds"), isOn: $allowsPrerelease)
				Toggle(String(localized: "Keep downloaded installers"), isOn: $keepsInstallers)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(4)
		}
	}
	
	private var versionRows: some View {
		VStack(alignment: .leading, spacing: 6) {
			LabeledContent(String(localized: "Installed Version")) {
				Text(verbatim: "3.2.1 (4821)")
			}
			LabeledContent(String(localized: "Available Version")) {
				Text(verbatim: "3.3.0 (4900)")
			}
			
			ProgressView(value: downloadProgress) {
				Text(String(localized: "Downloading"))
			}
			.progressViewStyle(.linear)
		}
		.font(.callout)
	}
	
	private var descriptionText: some View {
		// Wrapping text ties the height to the width, which is the case the pane measurement has to cope with
		Text(String(localized: "Secondary tab view, built with SwiftUI"))
			.font(.subheadline)
			.foregroundStyle(.secondary)
			.fixedSize(horizontal: false, vertical: true)
			.frame(maxWidth: .infinity, alignment: .center)
	}
	
}
/// Kept apart so that switching tabs discards the effect in flight along with the view
private struct UpdateDownloadIcon: View {
	
	let isAnimating: Bool
	
	@State private var isCleared = true
	
	var body: some View {
		let icon = Image(systemName: "arrow.down.circle.fill")
			.font(.system(size: 26))
			.symbolRenderingMode(.hierarchical)
			.foregroundStyle(.tint)
		
		if #available(macOS 26, *), isAnimating {
			icon.symbolEffect(.drawOn.individually, isActive: isCleared)
				.task {
					await Task.yield()
					
					while !Task.isCancelled {
						isCleared.toggle()
						try? await Task.sleep(for: .seconds(1))
					}
				}
		}
		else {
			icon
		}
	}
	
}

