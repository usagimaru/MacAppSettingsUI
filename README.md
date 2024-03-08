# MacAppSettingsUI

A package for make easier implementing a structure of settings / preferences UI for macOS AppKit-based apps.

<img src="./Guide/screenshot.jpg" width=562>

## Design

### Tab switching with animation

<img src="./Guide/anim.gif" width=275>

### Basically only close button, but zoom button optional

<img src="./Guide/close.jpg" width=189>

Basically only the close button works in a setting window, but depending on the pane, the zoom button can also be enabled. 


### We can also use the Escape key

I have provided an option to close the settings window with the Escape key.


### Set active tab name as a window title automatically

<img src="./Guide/title.jpg" width=354>


## Core Classes and Files

### `SettingsPaneViewController`
The base view controller for setting pane. You can use this class to customize your own.

### `SettingsWindowController`
WindowController for Settings window. You do not need to edit.

### `SettingsTabViewController`
WindowController’s contentViewController. You do not need to edit.

### `Settings.storyboard`
UI structure. You do not need to edit.


## Install
Use SwiftPM.


## Usage
To set panes of settings window, there are two ways of them.

### 1. Set panes as an array when initializing SettingsWindowController

```swift
var settingsWindowController: SettingsWindowController!

---

settingsWindowController = .windowController(with: [
	SettingsPaneViewController(tabName: "General",
							   tabImage: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil),
							   tabIdentifier: "general",
							   isResizableView: false),
	SettingsPaneViewController(tabName: "View",
							   tabImage: NSImage(systemSymbolName: "eyeglasses", accessibilityDescription: nil),
							   tabIdentifier: "view",
							   isResizableView: true),
	SettingsPaneViewController(tabName: "Extensions",
							   tabImage: NSImage(systemSymbolName: "puzzlepiece.extension", accessibilityDescription: nil),
							   tabIdentifier: "extensions",
							   isResizableView: false),
	SettingsPaneViewController(tabName: "Advanced",
							   tabImage: NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: nil),
							   tabIdentifier: "advanced",
							   isResizableView: false),
])
```

### 2. Set panes to a SettingsTabViewController instance

```swift
func set(panes: [SettingsPaneViewController])
func add(pane: SettingsPaneViewController)
func insert(pane: SettingsPaneViewController, at index: Int)
func insert(tabViewItem: NSTabViewItem, at index: Int)
```

To remove any pane, use NSTabViewController’s methods.

## Tab Appearance

There are properties of tab item in SettingsPaneViewController.

- `tabName`
	- Alias of `NSViewController.title`.
- `tabImage`
- `tabIdentifier`
	- Should set to a unique name.

## Control window resizing on a per-pane

There is a property in SettingsPaneViewController. Set true to allow window resizing only while the pane is active. The default value is false. Check the Demo implementation and `Main` Storyboard file.

- `isResizableView`


## License

See [LICENSE] for details.

