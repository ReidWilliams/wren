import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var textView: NSTextView!

    let bufferURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".wren")

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        buildWindow()
        loadBuffer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveBuffer()
    }

    private func loadBuffer() {
        guard let text = try? String(contentsOf: bufferURL, encoding: .utf8) else { return }
        textView.string = text
    }

    private func saveBuffer() {
        try? textView.string.write(to: bufferURL, atomically: true, encoding: .utf8)
    }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Wren"
        window.center()

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]

        let contentSize = scrollView.contentSize
        textView = NSTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)

        textView.font = NSFont.systemFont(ofSize: 16)
        textView.backgroundColor = NSColor(white: 0.10, alpha: 1)
        textView.textColor = NSColor(white: 0.88, alpha: 1)
        textView.insertionPointColor = NSColor(white: 0.88, alpha: 1)
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.allowsUndo = true

        scrollView.backgroundColor = NSColor(white: 0.10, alpha: 1)
        scrollView.documentView = textView
        window.contentView = scrollView

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildMenu() {
        let bar = NSMenu()
        NSApp.mainMenu = bar

        // App menu
        let appItem = NSMenuItem()
        bar.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(
            NSMenuItem(title: "Quit Wren", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        )

        // Edit menu
        let editItem = NSMenuItem()
        bar.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        editMenu.addItem(NSMenuItem(title: "Cut",        action: #selector(NSText.cut(_:)),        keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy",       action: #selector(NSText.copy(_:)),       keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste",      action: #selector(NSTextView.pasteAsPlainText(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)),  keyEquivalent: "a"))
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
