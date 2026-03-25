import AppKit

let showStatusDot = false
let showEntryTime = false

class AppDelegate: NSObject, NSApplicationDelegate, NSTextViewDelegate, NSMenuItemValidation {
    var window: NSWindow!
    var textView: NSTextView!
    let defaultFontSize: CGFloat = 16
    var fontSize: CGFloat = UserDefaults.standard.object(forKey: "fontSize") as? CGFloat ?? 16

    // Control bar
    var dotView: NSView!
    var dateLabel: NSTextField!
    var positionLabel: NSTextField!

    // Data
    let storeURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".wren.json")
    var store = EntryStore()
    var currentIndex = 0
    var isDirty = false
    var saveTimer: Timer?

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        buildWindow()
        prepareOnLaunch()
        startAutoSave()
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveCurrentEntry()
        store.save(to: storeURL)
        UserDefaults.standard.set(fontSize, forKey: "fontSize")
    }

    // MARK: - Launch Logic

    private func prepareOnLaunch() {
        store = EntryStore.load(from: storeURL)
        if store.entries.isEmpty {
            store.entries.append(Entry(content: EntryStore.makeInitialContent(), createdAt: EntryStore.nowISO()))
        } else {
            let lastIdx = store.entries.count - 1
            if EntryStore.isEffectivelyEmpty(store.entries[lastIdx].content) {
                // Repurpose the empty last entry for today
                store.entries[lastIdx].content = EntryStore.makeInitialContent()
                store.entries[lastIdx].createdAt = EntryStore.nowISO()
            } else {
                store.entries.append(Entry(content: EntryStore.makeInitialContent(), createdAt: EntryStore.nowISO()))
            }
        }
        currentIndex = store.entries.count - 1
        store.save(to: storeURL)
        loadCurrentEntry()
    }

    // MARK: - Entry Management

    private func loadCurrentEntry() {
        let entry = store.entries[currentIndex]
        textView.string = entry.content
        if currentIndex == store.entries.count - 1 {
            let loc = (textView.string as NSString).length
            textView.setSelectedRange(NSRange(location: loc, length: 0))
            textView.scrollToEndOfDocument(nil)
        } else {
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            textView.scrollToBeginningOfDocument(nil)
        }
        isDirty = false
        updateControlBar()
    }

    private func saveCurrentEntry() {
        store.entries[currentIndex].content = textView.string
    }

    @objc func newEntry() {
        guard !EntryStore.isEffectivelyEmpty(textView.string) else { return }
        saveCurrentEntry()
        store.entries.append(Entry(content: EntryStore.makeInitialContent(), createdAt: EntryStore.nowISO()))
        currentIndex = store.entries.count - 1
        store.save(to: storeURL)
        loadCurrentEntry()
    }

    @objc func goBack() {
        guard currentIndex > 0 else { return }
        saveCurrentEntry()
        currentIndex -= 1
        loadCurrentEntry()
    }

    @objc func goForward() {
        guard currentIndex < store.entries.count - 1 else { return }
        saveCurrentEntry()
        currentIndex += 1
        loadCurrentEntry()
    }

    @objc func goToCurrentNote() {
        guard currentIndex < store.entries.count - 1 else { return }
        saveCurrentEntry()
        currentIndex = store.entries.count - 1
        loadCurrentEntry()
    }

    @objc func goBackYear() {
        let currentYear = String(EntryStore.localDate(from: store.entries[currentIndex].createdAt).prefix(4))
        guard let targetYear = store.entries[0..<currentIndex]
            .map({ String(EntryStore.localDate(from: $0.createdAt).prefix(4)) })
            .filter({ $0 < currentYear })
            .last else { return }
        guard let targetIndex = store.entries.firstIndex(where: { String(EntryStore.localDate(from: $0.createdAt).prefix(4)) == targetYear }) else { return }
        saveCurrentEntry()
        currentIndex = targetIndex
        loadCurrentEntry()
    }

    @objc func goForwardYear() {
        guard currentIndex < store.entries.count - 1 else { return }
        let currentYear = String(EntryStore.localDate(from: store.entries[currentIndex].createdAt).prefix(4))
        if let targetYear = store.entries[(currentIndex + 1)...]
            .map({ String(EntryStore.localDate(from: $0.createdAt).prefix(4)) })
            .filter({ $0 > currentYear })
            .first,
           let targetIndex = store.entries.firstIndex(where: { String(EntryStore.localDate(from: $0.createdAt).prefix(4)) == targetYear }) {
            saveCurrentEntry()
            currentIndex = targetIndex
        } else {
            saveCurrentEntry()
            currentIndex = store.entries.count - 1
        }
        loadCurrentEntry()
    }

    @objc func goBackMonth() {
        let currentYearMonth = String(EntryStore.localDate(from: store.entries[currentIndex].createdAt).prefix(7))
        // Find the most recent earlier month that has entries, then jump to its first entry
        guard let targetMonth = store.entries[0..<currentIndex]
            .map({ String(EntryStore.localDate(from: $0.createdAt).prefix(7)) })
            .filter({ $0 < currentYearMonth })
            .last else { return }
        guard let targetIndex = store.entries.firstIndex(where: { String(EntryStore.localDate(from: $0.createdAt).prefix(7)) == targetMonth }) else { return }
        saveCurrentEntry()
        currentIndex = targetIndex
        loadCurrentEntry()
    }

    @objc func goForwardMonth() {
        guard currentIndex < store.entries.count - 1 else { return }
        let currentYearMonth = String(EntryStore.localDate(from: store.entries[currentIndex].createdAt).prefix(7))
        // Find the earliest later month; if none exists, fall back to the current note
        if let targetMonth = store.entries[(currentIndex + 1)...]
            .map({ String(EntryStore.localDate(from: $0.createdAt).prefix(7)) })
            .filter({ $0 > currentYearMonth })
            .first,
           let targetIndex = store.entries.firstIndex(where: { String(EntryStore.localDate(from: $0.createdAt).prefix(7)) == targetMonth }) {
            saveCurrentEntry()
            currentIndex = targetIndex
        } else {
            saveCurrentEntry()
            currentIndex = store.entries.count - 1
        }
        loadCurrentEntry()
    }

    // MARK: - Auto Save

    private func startAutoSave() {
        saveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.saveCurrentEntry()
            self.store.save(to: self.storeURL)
        }
    }

    // MARK: - NSTextViewDelegate

    func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString: String?) -> Bool {
        guard let replacement = replacementString, replacement == " " else { return true }
        let str = textView.string as NSString
        if range.location >= 1 {
            let prevChar = str.substring(with: NSRange(location: range.location - 1, length: 1))
            if prevChar == "-" {
                let lineStart = str.lineRange(for: NSRange(location: range.location - 1, length: 0)).location
                if range.location - 1 == lineStart {
                    textView.textStorage?.replaceCharacters(in: NSRange(location: range.location - 1, length: 1), with: "•")
                }
            }
        }
        return true
    }

    func textDidChange(_ notification: Notification) {
        isDirty = true
        store.entries[currentIndex].content = textView.string
        updateControlBar()
    }

    // MARK: - Menu Validation

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(newEntry)   { return !EntryStore.isEffectivelyEmpty(textView.string) }
        if menuItem.action == #selector(goToCurrentNote) { return currentIndex < store.entries.count - 1 }
        if menuItem.action == #selector(goBack)         { return currentIndex > 0 }
        if menuItem.action == #selector(goForward)      { return currentIndex < store.entries.count - 1 }
        if menuItem.action == #selector(goBackYear)     {
            let yr = String(EntryStore.localDate(from: store.entries[currentIndex].createdAt).prefix(4))
            return store.entries[0..<currentIndex].contains(where: { String(EntryStore.localDate(from: $0.createdAt).prefix(4)) < yr })
        }
        if menuItem.action == #selector(goForwardYear)  { return currentIndex < store.entries.count - 1 }
        if menuItem.action == #selector(goBackMonth)    {
            let ym = String(EntryStore.localDate(from: store.entries[currentIndex].createdAt).prefix(7))
            return store.entries[0..<currentIndex].contains(where: { String(EntryStore.localDate(from: $0.createdAt).prefix(7)) < ym })
        }
        if menuItem.action == #selector(goForwardMonth) { return currentIndex < store.entries.count - 1 }
        if menuItem.action == #selector(resetFontSize)  { return fontSize != defaultFontSize }
        return true
    }

    // MARK: - Control Bar Updates

    private func updateControlBar() {
        let entry = store.entries[currentIndex]
        let entryDate = EntryStore.localDate(from: entry.createdAt)
        let today = EntryStore.todayISO()
        let yesterday = EntryStore.yesterdayISO()
        let isCurrentNote = currentIndex == store.entries.count - 1
        let accent = NSColor(red: 0.78, green: 0.26, blue: 0.13, alpha: 1)
        let dimColor = NSColor(white: 0.60, alpha: 1)

        // Count notes sharing the same local date to decide whether to show time
        let sameDayCount = store.entries.filter { EntryStore.localDate(from: $0.createdAt) == entryDate }.count
        let timeStr: String? = showEntryTime && sameDayCount > 1 ? EntryStore.displayTime(from: entry.createdAt) : nil

        func label(_ base: String) -> String {
            if let t = timeStr { return "\(base), \(t)" } else { return base }
        }

        if isCurrentNote {
            let todayCount = store.entries.filter { EntryStore.localDate(from: $0.createdAt) == today }.count
            // "Now" never shows a time
            dateLabel.stringValue = todayCount > 1 ? "Now" : "Today"
            dateLabel.textColor = accent
            if showStatusDot { dotView.layer?.backgroundColor = accent.cgColor }
        } else if entryDate == today {
            dateLabel.stringValue = label("Today")
            dateLabel.textColor = dimColor
            if showStatusDot { dotView.layer?.backgroundColor = dimColor.cgColor }
        } else if entryDate == yesterday {
            dateLabel.stringValue = label("Yesterday")
            dateLabel.textColor = dimColor
            if showStatusDot { dotView.layer?.backgroundColor = dimColor.cgColor }
        } else {
            dateLabel.stringValue = label(EntryStore.displayDate(from: entryDate))
            dateLabel.textColor = dimColor
            if showStatusDot { dotView.layer?.backgroundColor = dimColor.cgColor }
        }

        positionLabel.stringValue = "Note \(currentIndex + 1) of \(store.entries.count)"
    }

    // MARK: - Window Building

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Wren"
        window.appearance = NSAppearance(named: .darkAqua)
        window.center()

        let barHeight: CGFloat = 36
        let contentBounds = NSRect(x: 0, y: 0, width: 640, height: 480)
        let containerView = NSView(frame: contentBounds)
        containerView.autoresizingMask = [.width, .height]

        // Control bar
        let controlBar = buildControlBar(height: barHeight, width: 640)
        containerView.addSubview(controlBar)

        // Scroll view + text view
        let scrollFrame = NSRect(x: 0, y: barHeight, width: 640, height: 480 - barHeight)
        let scrollView = NSScrollView(frame: scrollFrame)
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        scrollView.backgroundColor = NSColor(white: 0.10, alpha: 1)

        let contentSize = scrollView.contentSize
        textView = NSTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.font = makeFont()
        textView.backgroundColor = NSColor(white: 0.10, alpha: 1)
        textView.textColor = NSColor(white: 0.88, alpha: 1)
        textView.insertionPointColor = NSColor(white: 0.88, alpha: 1)
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.usesFontPanel = false
        textView.allowsUndo = true
        textView.delegate = self

        scrollView.documentView = textView
        containerView.addSubview(scrollView)

        window.contentView = containerView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildControlBar(height: CGFloat, width: CGFloat) -> NSView {
        let bar = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        bar.autoresizingMask = [.width]
        bar.wantsLayer = true
        bar.layer?.backgroundColor = NSColor(white: 0.13, alpha: 1).cgColor

        // Top separator line
        let sep = NSView(frame: NSRect(x: 0, y: height - 1, width: width, height: 1))
        sep.autoresizingMask = [.width]
        sep.wantsLayer = true
        sep.layer?.backgroundColor = NSColor(white: 0.22, alpha: 1).cgColor
        bar.addSubview(sep)

        let labelH: CGFloat = 18
        let labelY: CGFloat = ((height - labelH) / 2) - 1
        let margin: CGFloat = 12

        // Status dot
        let dotSize: CGFloat = 5
        let dotX: CGFloat = margin
        let dotGap: CGFloat = 3
        if showStatusDot {
            let dotY: CGFloat = (height - dotSize) / 2
            dotView = NSView(frame: NSRect(x: dotX, y: dotY, width: dotSize, height: dotSize))
            dotView.wantsLayer = true
            dotView.layer?.cornerRadius = dotSize / 2
            dotView.layer?.backgroundColor = NSColor(white: 0.60, alpha: 1).cgColor
            bar.addSubview(dotView)
        }

        let labelX: CGFloat = showStatusDot ? dotX + dotSize + dotGap : margin

        dateLabel = NSTextField(frame: NSRect(x: labelX, y: labelY, width: width - labelX - margin, height: labelH))
        dateLabel.autoresizingMask = [.width]
        dateLabel.isEditable = false
        dateLabel.isBordered = false
        dateLabel.backgroundColor = .clear
        dateLabel.textColor = NSColor(white: 0.60, alpha: 1)
        dateLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        dateLabel.alignment = .left
        bar.addSubview(dateLabel)

        positionLabel = NSTextField(frame: NSRect(x: margin, y: labelY, width: width - margin * 2, height: labelH))
        positionLabel.autoresizingMask = [.width]
        positionLabel.isEditable = false
        positionLabel.isBordered = false
        positionLabel.backgroundColor = .clear
        positionLabel.textColor = NSColor(white: 0.60, alpha: 1)
        positionLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        positionLabel.alignment = .right
        bar.addSubview(positionLabel)

        return bar
    }

    // MARK: - Font

    private func makeFont() -> NSFont {
        NSFont.systemFont(ofSize: fontSize)
    }

    @objc private func increaseFontSize() {
        fontSize += 1
        textView.font = makeFont()
    }

    @objc private func decreaseFontSize() {
        fontSize = max(6, fontSize - 1)
        textView.font = makeFont()
    }

    @objc private func resetFontSize() {
        fontSize = defaultFontSize
        textView.font = makeFont()
    }

    // MARK: - Menu

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
        editMenu.addItem(NSMenuItem(title: "Cut",        action: #selector(NSText.cut(_:)),                       keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy",       action: #selector(NSText.copy(_:)),                      keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste",      action: #selector(NSTextView.pasteAsPlainText(_:)),      keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)),                 keyEquivalent: "a"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Increase Font Size", action: #selector(increaseFontSize), keyEquivalent: "+"))
        editMenu.addItem(NSMenuItem(title: "Decrease Font Size", action: #selector(decreaseFontSize), keyEquivalent: "-"))
        editMenu.addItem(NSMenuItem(title: "Default Font Size",  action: #selector(resetFontSize),    keyEquivalent: "0"))

        // History menu
        let histItem = NSMenuItem()
        bar.addItem(histItem)
        let histMenu = NSMenu(title: "History")
        histItem.submenu = histMenu

        let newNoteItem = NSMenuItem(title: "New Note", action: #selector(newEntry), keyEquivalent: "n")
        newNoteItem.keyEquivalentModifierMask = [.command]
        histMenu.addItem(newNoteItem)

        let currentNoteItem = NSMenuItem(title: "Current Note", action: #selector(goToCurrentNote), keyEquivalent: "t")
        currentNoteItem.keyEquivalentModifierMask = [.command]
        histMenu.addItem(currentNoteItem)

        histMenu.addItem(.separator())

        let prevItem = NSMenuItem(title: "Previous Entry", action: #selector(goBack), keyEquivalent: "[")
        prevItem.keyEquivalentModifierMask = .command
        histMenu.addItem(prevItem)

        let nextItem = NSMenuItem(title: "Next Entry", action: #selector(goForward), keyEquivalent: "]")
        nextItem.keyEquivalentModifierMask = .command
        histMenu.addItem(nextItem)

        histMenu.addItem(.separator())

        let prevYearItem = NSMenuItem(title: "Previous Year", action: #selector(goBackYear), keyEquivalent: "[")
        prevYearItem.keyEquivalentModifierMask = [.control, .option, .command]
        histMenu.addItem(prevYearItem)

        let nextYearItem = NSMenuItem(title: "Next Year", action: #selector(goForwardYear), keyEquivalent: "]")
        nextYearItem.keyEquivalentModifierMask = [.control, .option, .command]
        histMenu.addItem(nextYearItem)

        histMenu.addItem(.separator())

        let prevMonthItem = NSMenuItem(title: "Previous Month", action: #selector(goBackMonth), keyEquivalent: "[")
        prevMonthItem.keyEquivalentModifierMask = [.command, .option]
        histMenu.addItem(prevMonthItem)

        let nextMonthItem = NSMenuItem(title: "Next Month", action: #selector(goForwardMonth), keyEquivalent: "]")
        nextMonthItem.keyEquivalentModifierMask = [.command, .option]
        histMenu.addItem(nextMonthItem)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
