import Foundation
import SQLite3

public struct StoreError: Error, CustomStringConvertible {
    public let description: String
}

enum SQLValue {
    case text(String), int(Int64), null
    static func of(_ s: String?) -> SQLValue { s.map { .text($0) } ?? .null }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
private let cols = "id, body, status, due, created_at, updated_at"

public final class Store {
    private var db: OpaquePointer?
    public let path: String

    /// `JOT_DB` overrides the location (tests, scratch runs).
    public static var defaultPath: String {
        if let p = ProcessInfo.processInfo.environment["JOT_DB"], !p.isEmpty { return p }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Jot/jot.db").path
    }

    public init(path: String = Store.defaultPath) throws {
        self.path = path
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: path).deletingLastPathComponent(), withIntermediateDirectories: true)
        guard sqlite3_open(path, &db) == SQLITE_OK else {
            throw StoreError(description: "can't open \(path)")
        }
        sqlite3_busy_timeout(db, 3000)
        // WAL lets the widget's CLI read while the app writes.
        try exec("PRAGMA journal_mode=WAL")
        try exec("""
            CREATE TABLE IF NOT EXISTS items(
              id INTEGER PRIMARY KEY,
              body TEXT NOT NULL,
              status TEXT CHECK (status IN ('open', 'done')),
              due TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
            """)
    }

    deinit { sqlite3_close(db) }

    @discardableResult
    public func add(_ body: String, status: Status? = nil, due: Due? = nil, now: Date = Date()) throws -> Item {
        let ts = iso.string(from: now)
        try run("INSERT INTO items(body, status, due, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
                [.text(body), .of(status?.rawValue), .of(due?.stored), .text(ts), .text(ts)])
        return try get(sqlite3_last_insert_rowid(db))!
    }

    public func update(_ item: Item, now: Date = Date()) throws {
        try run("UPDATE items SET body = ?, status = ?, due = ?, updated_at = ? WHERE id = ?",
                [.text(item.body), .of(item.status?.rawValue), .of(item.due?.stored), .text(iso.string(from: now)), .int(item.id)])
    }

    @discardableResult
    public func setDone(_ id: Int64, _ done: Bool = true, now: Date = Date()) throws -> Bool {
        try run("UPDATE items SET status = ?, updated_at = ? WHERE id = ?",
                [.text(done ? "done" : "open"), .text(iso.string(from: now)), .int(id)])
        return sqlite3_changes(db) > 0
    }

    @discardableResult
    public func delete(_ id: Int64) throws -> Bool {
        try run("DELETE FROM items WHERE id = ?", [.int(id)])
        return sqlite3_changes(db) > 0
    }

    public func get(_ id: Int64) throws -> Item? {
        try rows("SELECT \(cols) FROM items WHERE id = ?", [.int(id)]).first
    }

    public func search(_ text: String) throws -> [Item] {
        try rows("SELECT \(cols) FROM items WHERE body LIKE '%' || ? || '%' ORDER BY updated_at DESC", [.text(text)])
    }

    public func agenda(now: Date = Date(), calendar: Calendar = .current) throws -> Agenda {
        // Skip done items finished before today; ISO UTC strings compare correctly as text.
        let startOfDay = iso.string(from: calendar.startOfDay(for: now))
        let items = try rows("SELECT \(cols) FROM items WHERE status IS NOT 'done' OR updated_at >= ?", [.text(startOfDay)])
        return Agenda.build(items, now: now, calendar: calendar)
    }

    /// Consistent snapshot even while the DB is in use. Fails if `path` exists.
    public func backup(to path: String) throws {
        try run("VACUUM INTO ?", [.text(path)])
    }

    // MARK: - SQLite plumbing

    private func exec(_ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw lastError() }
    }

    private func prepare(_ sql: String, _ args: [SQLValue]) throws -> OpaquePointer {
        var st: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &st, nil) == SQLITE_OK, let st else { throw lastError() }
        for (i, a) in args.enumerated() {
            let idx = Int32(i + 1)
            switch a {
            case .text(let s): sqlite3_bind_text(st, idx, s, -1, SQLITE_TRANSIENT)
            case .int(let n): sqlite3_bind_int64(st, idx, n)
            case .null: sqlite3_bind_null(st, idx)
            }
        }
        return st
    }

    private func run(_ sql: String, _ args: [SQLValue]) throws {
        let st = try prepare(sql, args)
        defer { sqlite3_finalize(st) }
        guard sqlite3_step(st) == SQLITE_DONE else { throw lastError() }
    }

    private func rows(_ sql: String, _ args: [SQLValue]) throws -> [Item] {
        let st = try prepare(sql, args)
        defer { sqlite3_finalize(st) }
        var out: [Item] = []
        while true {
            let rc = sqlite3_step(st)
            if rc == SQLITE_DONE { break }
            guard rc == SQLITE_ROW else { throw lastError() }
            out.append(Item(
                id: sqlite3_column_int64(st, 0),
                body: text(st, 1) ?? "",
                status: text(st, 2).flatMap(Status.init(rawValue:)),
                due: text(st, 3).flatMap(Due.init(stored:)),
                createdAt: text(st, 4).flatMap(iso.date(from:)) ?? .distantPast,
                updatedAt: text(st, 5).flatMap(iso.date(from:)) ?? .distantPast))
        }
        return out
    }

    private func text(_ st: OpaquePointer, _ i: Int32) -> String? {
        sqlite3_column_text(st, i).map { String(cString: $0) }
    }

    private func lastError() -> StoreError {
        StoreError(description: String(cString: sqlite3_errmsg(db)))
    }
}
