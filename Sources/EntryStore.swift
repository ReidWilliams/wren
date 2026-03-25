import Foundation

struct Entry: Codable {
    var content: String
    var createdAt: String  // ISO 8601 datetime, e.g. "2026-03-25T14:30:00-07:00"
}

struct EntryStore: Codable {
    var entries: [Entry] = []

    static func load(from url: URL) -> EntryStore {
        guard let data = try? Data(contentsOf: url),
              let store = try? JSONDecoder().decode(EntryStore.self, from: data) else {
            return EntryStore()
        }
        return store
    }

    func save(to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func isEffectivelyEmpty(_ content: String) -> Bool {
        let nonEmpty = content.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return nonEmpty.count == 0
    }

    static func makeInitialContent() -> String {
        return ""
    }

    // Current datetime as ISO 8601 with timezone offset
    static func nowISO() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: Date())
    }

    // Parse an ISO 8601 datetime string into a Date
    private static func parseISO(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }

    // Local "yyyy-MM-dd" from a createdAt string
    static func localDate(from createdAt: String) -> String {
        guard let date = parseISO(createdAt) else { return String(createdAt.prefix(10)) }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static func todayISO() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    static func yesterdayISO() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date(timeIntervalSinceNow: -86400))
    }

    static func currentYearString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f.string(from: Date())
    }

    // "24 Mar" (current year) or "24 Mar 2025" (other year)
    static func displayDate(from localDateStr: String) -> String {
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        guard let date = inFmt.date(from: localDateStr) else { return localDateStr }
        let outFmt = DateFormatter()
        let yearStr = String(localDateStr.prefix(4))
        outFmt.dateFormat = yearStr == currentYearString() ? "d MMM" : "d MMM yyyy"
        return outFmt.string(from: date)
    }

    // "3pm", "8am", "12pm" from a createdAt string; nil if unparseable
    static func displayTime(from createdAt: String) -> String? {
        guard let date = parseISO(createdAt) else { return nil }
        let f = DateFormatter()
        f.dateFormat = "ha"
        f.amSymbol = "am"
        f.pmSymbol = "pm"
        return f.string(from: date).lowercased()
    }
}
