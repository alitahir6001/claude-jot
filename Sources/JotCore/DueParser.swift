import Foundation

/// Deterministic parser for short date phrases. NSDataDetector was rejected: it takes no reference date, so it can't be tested.
/// Accepts: today, tomorrow, weekdays ("fri", "next friday"), "in 3 days" / "in 2 weeks",
/// "nov 20", "20 nov", "11/20", "2026-11-20", optional year, plus a time ("3pm", "3:30 pm", "15:00", "noon").
public enum DueParser {
    public static func parse(_ input: String, now: Date = Date(), calendar cal: Calendar = .current) -> Due? {
        var s = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }

        var hour: Int?
        var minute = 0
        if let m = firstMatch(timeRe, s) {
            if m.range(at: 7).location != NSNotFound {
                hour = 12
            } else if let h = group(m, 1, s).flatMap(Int.init) {
                guard (1...12).contains(h) else { return nil }
                minute = group(m, 2, s).flatMap(Int.init) ?? 0
                let pm = group(m, 3, s) == "pm"
                hour = h % 12 + (pm ? 12 : 0)
            } else if let h = group(m, 4, s).flatMap(Int.init), let mm = group(m, 5, s).flatMap(Int.init) {
                guard (0...23).contains(h) else { return nil }
                hour = h
                minute = mm
            }
            guard minute < 60 else { return nil }
            s = (s as NSString).replacingCharacters(in: m.range, with: " ")
        }
        s = s.split(whereSeparator: { $0 == " " || $0 == "," }).joined(separator: " ")
        if s.hasSuffix(" at") { s.removeLast(3) }

        let today = cal.startOfDay(for: now)
        guard let day = parseDay(s, today: today, hasTime: hour != nil, cal: cal) else { return nil }

        guard let hour else { return .day(dayString(day, cal)) }
        var c = cal.dateComponents([.year, .month, .day], from: day)
        c.hour = hour
        c.minute = minute
        return cal.date(from: c).map { .time($0) }
    }

    private static func parseDay(_ s: String, today: Date, hasTime: Bool, cal: Calendar) -> Date? {
        let plus = { (n: Int) in cal.date(byAdding: .day, value: n, to: today) }
        switch s {
        case "": return hasTime ? today : nil
        case "today", "tod", "tonight": return today
        case "tomorrow", "tmrw", "tmr", "tom": return plus(1)
        default: break
        }

        // Weekday: always the next occurrence after today (1-7 days out).
        let word = s.hasPrefix("next ") ? String(s.dropFirst(5)) : s
        if word.count >= 3, let i = weekdays.firstIndex(where: { $0.hasPrefix(word) }) {
            let cur = cal.component(.weekday, from: today)
            let delta = (i + 1 - cur + 7) % 7
            return plus(delta == 0 ? 7 : delta)
        }

        if let m = firstMatch(inRe, s), let n = group(m, 1, s).flatMap(Int.init) {
            let unit = group(m, 2, s) ?? ""
            return plus(unit.hasPrefix("w") ? n * 7 : n)
        }

        var y: Int?, mo: Int?, d: Int?
        if let m = firstMatch(isoRe, s) {
            (y, mo, d) = (group(m, 1, s).flatMap(Int.init), group(m, 2, s).flatMap(Int.init), group(m, 3, s).flatMap(Int.init))
        } else if let m = firstMatch(slashRe, s) {
            (mo, d) = (group(m, 1, s).flatMap(Int.init), group(m, 2, s).flatMap(Int.init))
            y = group(m, 3, s).flatMap(Int.init).map { $0 < 100 ? 2000 + $0 : $0 }
        } else if let m = firstMatch(monthDayRe, s) {
            (mo, d) = (month(group(m, 1, s)), group(m, 2, s).flatMap(Int.init))
            y = group(m, 3, s).flatMap(Int.init)
        } else if let m = firstMatch(dayMonthRe, s) {
            (d, mo) = (group(m, 1, s).flatMap(Int.init), month(group(m, 2, s)))
            y = group(m, 3, s).flatMap(Int.init)
        }
        guard let mo, let d else { return nil }

        let year = y ?? cal.component(.year, from: today)
        guard let date = validDate(year, mo, d, cal) else { return nil }
        // No year given and the date already passed: assume next year.
        if y == nil && date < today { return validDate(year + 1, mo, d, cal) }
        return date
    }

    private static func validDate(_ y: Int, _ m: Int, _ d: Int, _ cal: Calendar) -> Date? {
        guard let date = cal.date(from: DateComponents(year: y, month: m, day: d)) else { return nil }
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return (c.year, c.month, c.day) == (y, m, d) ? date : nil   // rejects Feb 30 etc.
    }

    private static func month(_ token: String?) -> Int? {
        guard let t = token, t.count >= 3 else { return nil }
        return months.firstIndex(where: { $0.hasPrefix(t) }).map { $0 + 1 }
    }

    private static let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    private static let months = ["january", "february", "march", "april", "may", "june", "july",
                                 "august", "september", "october", "november", "december"]

    private static let timeRe = re(#"(?:\bat\s+)?\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b|(?:\bat\s+)?\b(\d{1,2}):(\d{2})\b|(?:\bat\s+)?\b((noon))\b"#)
    private static let inRe = re(#"^in (\d+) ?(d|days?|w|wks?|weeks?)$"#)
    private static let isoRe = re(#"^(\d{4})-(\d{1,2})-(\d{1,2})$"#)
    private static let slashRe = re(#"^(\d{1,2})/(\d{1,2})(?:/(\d{2}|\d{4}))?$"#)
    private static let monthDayRe = re(#"^([a-z]+)\.? (\d{1,2})(?:st|nd|rd|th)?(?: (\d{4}))?$"#)
    private static let dayMonthRe = re(#"^(\d{1,2})(?:st|nd|rd|th)? ([a-z]+)(?: (\d{4}))?$"#)

    private static func re(_ p: String) -> NSRegularExpression { try! NSRegularExpression(pattern: p) }

    private static func firstMatch(_ r: NSRegularExpression, _ s: String) -> NSTextCheckingResult? {
        r.firstMatch(in: s, range: NSRange(s.startIndex..., in: s))
    }

    private static func group(_ m: NSTextCheckingResult, _ i: Int, _ s: String) -> String? {
        Range(m.range(at: i), in: s).map { String(s[$0]) }
    }
}
