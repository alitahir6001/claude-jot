import Foundation

public enum Status: String, Sendable { case open, done }

/// All-day dates stay as local `YYYY-MM-DD` so they never shift across time zones.
public enum Due: Equatable, Sendable {
    case day(String)
    case time(Date)
}

public struct Item: Identifiable, Equatable, Sendable {
    public var id: Int64
    public var body: String
    public var status: Status?   // nil = plain note
    public var due: Due?
    public var createdAt: Date
    public var updatedAt: Date
}

let iso = ISO8601DateFormatter()

extension Due {
    public var stored: String {
        switch self {
        case .day(let s): return s
        case .time(let d): return iso.string(from: d)
        }
    }

    public init?(stored s: String) {
        if s.count == 10 { self = .day(s) }
        else if let d = iso.date(from: s) { self = .time(d) }
        else { return nil }
    }

    public func dayKey(_ cal: Calendar) -> String {
        switch self {
        case .day(let s): return s
        case .time(let d): return dayString(d, cal)
        }
    }

    public func sortDate(_ cal: Calendar) -> Date {
        switch self {
        case .day(let s): return dateFromDay(s, cal) ?? .distantFuture
        case .time(let d): return d
        }
    }

    /// "Today", "Tomorrow 3:00 PM", "Fri", "Nov 20", "Jan 4, 2027".
    public func label(now: Date = Date(), calendar cal: Calendar = .current) -> String {
        let start = sortDate(cal)
        let dayStart = cal.startOfDay(for: start)
        let diff = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: dayStart).day ?? 0
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = cal
        f.timeZone = cal.timeZone
        var out: String
        switch diff {
        case 0: out = "Today"
        case 1: out = "Tomorrow"
        case -1: out = "Yesterday"
        case 2...6: f.dateFormat = "EEE"; out = f.string(from: dayStart)
        default:
            let sameYear = cal.component(.year, from: dayStart) == cal.component(.year, from: now)
            f.dateFormat = sameYear ? "MMM d" : "MMM d, yyyy"
            out = f.string(from: dayStart)
        }
        if case .time(let d) = self {
            f.dateFormat = "h:mm a"
            out += " " + f.string(from: d)
        }
        return out
    }
}

func dayString(_ d: Date, _ cal: Calendar) -> String {
    let c = cal.dateComponents([.year, .month, .day], from: d)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
}

func dateFromDay(_ s: String, _ cal: Calendar) -> Date? {
    let p = s.split(separator: "-").compactMap { Int($0) }
    guard p.count == 3 else { return nil }
    return cal.date(from: DateComponents(year: p[0], month: p[1], day: p[2]))
}
