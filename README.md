# MacAppSettingsUI

A package for make easier implementing a structure of settings / preferences UI for macOS AppKit-based apps.

<img src="./Guide/screenshot.jpg" width=562>

## Design and Features

### Preferences-Style Toolbar with Animation

The window has preferences-style toolbar and native switching animation. It also supports “Reduce Motion” feature of accessibility.

<img src="./Guide/anim.gif" width=275>


### Window Title

Set active pane name as a window title automatically when panes are switched.

<img src="./Guide/title.jpg" width=350>


### Window Title with Active Pane Name on Window Menu

Display window title with pane name on the Window menu automatically.

<img src="./Guide/windowmenu.jpg" width= 350>


### Only Close Button

Basically, the window only has a close button, but a zoom button is optional for per-pane.

<img src="./Guide/close.jpg" width=190>


### Press Escape Key to Close

We can use the Escape key `⎋` or `⌘.` action to close the window.

<img src="./Guide/escapekey.png" width=190>


### Restorable Window Frame

The settings Window supports autosave frame via UserDefaults. The last window position can be restored automatically.


### Supported for Renamed “Settings”

On before macOS Ventura, “Settings” was “Preferences”. This module can also support renamed “Settings” after Ventura.

More details of this design (Japanese): [macOS Venturaからの新しい“Settings”表記と、旧“Preferences”表記からの移行](https://zenn.dev/usagimaru/articles/de5012155f4916)


### Layout Guide (experimental)

I have prepared a simple layout guide and a wireframing feature to help you build the standard setting layout. Please check the “Developer” tab on the demo app, `DeveloperSettingsPaneViewController` and `SettingsPaneContainerView`.

<img src="./Guide/layoutguide.jpg" width=762>

## Core Files

### `SettingsWindow`
Window for Settings window.

### `SettingsWindowController`
WindowController for Settings window.

### `SettingsTabViewController`
WindowController’s contentViewController.

### `SettingsPaneViewController`
The base view controller for setting pane. You can use this class to customize your own.

### `SettingsPaneContainerView`
This is a convenient container view for layouts. It is disabled by default; if you wish to use it, first enable it using the `setContentContainerView(maximumWidth:)` method of the `SettingsPaneViewController`. Then add any contents to this container view.

Please check the “Developer” tab on the demo app, `DeveloperSettingsPaneViewController` and `SettingsPaneContainerView`.


## Install
Use SwiftPM.


## Usage
To set panes of settings window, there are two ways of them.

### A. Initialize SettingsWindowController with the panes as an array

```swift
// First, initialize the SettingsWindowController instance
let settingsWindowController = SettingsWindowController(with: [/*panes*/])

// …like this:
let settingsWindowController = SettingsWindowController(with: [
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

// That’s all. Then you can show the settings window.
settingsWindowController.showWindow(nil)

```

### B. Set panes to a SettingsTabViewController instance

```swift
func set(panes: [SettingsPaneViewController])
func add(panes: [SettingsPaneViewController])
func insert(panes: [SettingsPaneViewController], at index: Int)
func insert(tabViewItem: NSTabViewItem, at index: Int)
```

To remove any pane, use NSTabViewController’s methods.


## Appearance of Tabs

There are properties of tab item in `SettingsPaneViewController`.

### `tabName`
Default tab name, alias of `NSViewController.title`.

### `tabImage`
Icon for a tab.

### `tabIdentifier`
Should set to a unique name.

### `localizeKeyForTabName`
This key is used for localizing tab name process automatically.

If you use this, SettingsTabViewController replaces `tabName` with the localized tab name. You can disable this feature with using a property `disablesLocalizationWithTabNameLocalizeKey` on SettingsTabViewController.


## Controling window resizing behavior on a per-pane

SettingsPaneViewController has the property `isResizableView`; setting true to allow window resizing only while the pane is active. The default value is false. Check the Demo implementation and `Main` Storyboard file.


## License

See [LICENSE](./LICENSE) for details.
