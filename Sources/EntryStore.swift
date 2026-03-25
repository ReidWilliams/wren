import Foundation

struct Entry: Codable {
    var date: String    // ISO 8601, e.g. "2026-03-25"
    var content: String
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

    // An entry is empty if it has no user-written lines beyond the date header.
    static func isEffectivelyEmpty(_ content: String) -> Bool {
        let nonEmpty = content.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return nonEmpty.count <= 1
    }

    static func makeInitialContent() -> String {
        return ""
    }

    static func todayISO() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    static func displayDate(from iso: String) -> String {
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        guard let date = inFmt.date(from: iso) else { return iso }
        let outFmt = DateFormatter()
        outFmt.dateFormat = "MMM d, yyyy"
        return outFmt.string(from: date)
    }
}
