import Foundation

public struct Agenda: Equatable, Sendable {
    public var overdue: [Item] = []
    public var today: [Item] = []
    public var upcoming: [Item] = []
    public var todo: [Item] = []       // open TODOs with no date
    public var notes: [Item] = []      // undated notes
    public var doneToday: [Item] = []
    public var claude: [Item] = []     // not-done items with a project, dated or not

    public init() {}

    /// Groups sorted by project name; items keep their order.
    public static func byProject(_ items: [Item]) -> [(project: String, items: [Item])] {
        Dictionary(grouping: items) { $0.project ?? "" }
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { (project: $0.key, items: $0.value) }
    }

    /// Done items show only on the day they were finished; past dated notes drop off (still searchable).
    public static func build(_ items: [Item], now: Date, calendar cal: Calendar) -> Agenda {
        var a = Agenda()
        let todayKey = dayString(now, cal)
        for item in items {
            if item.status == .done {
                if cal.isDate(item.updatedAt, inSameDayAs: now) { a.doneToday.append(item) }
                continue
            }
            if item.project != nil {
                a.claude.append(item)
                continue
            }
            guard let due = item.due else {
                if item.status == .open { a.todo.append(item) } else { a.notes.append(item) }
                continue
            }
            let key = due.dayKey(cal)
            let isPast: Bool
            switch due {
            case .day: isPast = key < todayKey
            case .time(let d): isPast = d < now
            }
            if isPast && item.status == .open { a.overdue.append(item) }
            else if key == todayKey { a.today.append(item) }
            else if !isPast { a.upcoming.append(item) }
        }
        let byDue: (Item, Item) -> Bool = { $0.due!.sortDate(cal) < $1.due!.sortDate(cal) }
        a.overdue.sort(by: byDue)
        a.today.sort(by: byDue)
        a.upcoming.sort(by: byDue)
        a.todo.sort { $0.createdAt > $1.createdAt }
        a.notes.sort { $0.createdAt > $1.createdAt }
        a.doneToday.sort { $0.updatedAt > $1.updatedAt }
        a.claude.sort { $0.createdAt > $1.createdAt }
        return a
    }
}
