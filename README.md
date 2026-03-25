# Wren

A macOS native app for scratch text editing. No files to open or manage. Wren automatically creates a new note each session and saves everything as you go.

Notes are stored in `~/.wren.json`.

## History

Every note you've ever written is one keypress away. Wren keeps a chronological stack of notes and lets you navigate through them without leaving the keyboard.

| Shortcut | Action |
|---|---|
| `⌘[` | Go back one note |
| `⌘]` | Go forward one note |
| `⌘T` | Jump to current note |
| `⌘N` | New note |
| `⌘⌥[` | Jump back one month |
| `⌘⌥]` | Jump forward one month |
| `⌃⌥⌘[` | Jump back one year |
| `⌃⌥⌘]` | Jump forward one year |

The status bar at the bottom shows where you are. The current note is highlighted in orange. Past notes are dimmed.

## Other shortcuts

| Shortcut | Action |
|---|---|
| `⌘+` | Increase font size |
| `⌘-` | Decrease font size |
| `⌘0` | Reset font size |

## Installation

### Pre-built

Download or copy `Wren.app` into `/Applications`. On first launch, macOS Gatekeeper will block it because the app is unsigned. To allow it:

```
xattr -dr com.apple.quarantine /Applications/Wren.app
```

Then double-click to open normally from then on.

### Build from source

Requires Xcode command line tools (`xcode-select --install`).

```
make
```

This produces `build/Wren.app`. To build and launch in one step:

```
make run
```

The app requires Apple Silicon (arm64). It will not run on Intel Macs.
