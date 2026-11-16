import Foundation
import Testing
@testable import JotCore

let ny: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/New_York")!
    return c
}()

func at(_ y: Int, _ mo: Int, _ d: Int, _ h: Int = 0, _ mi: Int = 0, cal: Calendar = ny) -> Date {
    cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
}

// Sunday, Nov 15 2026, 10:00 New York.
let now = at(2026, 11, 15, 10)

func p(_ s: String) -> Due? { DueParser.parse(s, now: now, calendar: ny) }

@Suite struct ParserTests {
    @Test func relativeDays() {
        #expect(p("today") == .day("2026-11-15"))
        #expect(p("tomorrow") == .day("2026-11-16"))
        #expect(p("in 3 days") == .day("2026-11-18"))
        #expect(p("in 2 weeks") == .day("2026-11-29"))
    }

    @Test func weekdaysAreAlwaysAhead() {
        #expect(p("fri") == .day("2026-11-20"))
        #expect(p("next friday") == .day("2026-11-20"))
        #expect(p("sun") == .day("2026-11-22"))   // today is Sunday: next week, not today
        #expect(p("mon") == .day("2026-11-16"))
    }

    @Test func absoluteDates() {
        #expect(p("nov 20") == .day("2026-11-20"))
        #expect(p("20 nov") == .day("2026-11-20"))
        #expect(p("November 20th") == .day("2026-11-20"))
        #expect(p("11/20") == .day("2026-11-20"))
        #expect(p("2027-01-04") == .day("2027-01-04"))
        #expect(p("nov 10") == .day("2027-11-10"))      // already passed: next year
        #expect(p("nov 10 2026") == .day("2026-11-10")) // explicit year is kept
    }

    @Test func times() {
        #expect(p("3pm") == .time(at(2026, 11, 15, 15)))
        #expect(p("tomorrow 3:30 pm") == .time(at(2026, 11, 16, 15, 30)))
        #expect(p("fri at 9am") == .time(at(2026, 11, 20, 9)))
        #expect(p("nov 20 15:00") == .time(at(2026, 11, 20, 15)))
        #expect(p("12am tomorrow") == .time(at(2026, 11, 16, 0)))
        #expect(p("noon") == .time(at(2026, 11, 15, 12)))
    }

    @Test func dstUsesLocalWallClock() {
        // US DST starts Mar 8 2026: 3pm is 20:00Z the day before, 19:00Z that day.
        let utc = { (h: Int, d: Int) in ISO8601DateFormatter().date(from: "2026-03-0\(d)T\(h):00:00Z")! }
        #expect(p("mar 7 2026 3pm") == .time(utc(20, 7)))
        #expect(p("mar 8 2026 3pm") == .time(utc(19, 8)))
    }

    @Test func rejectsJunk() {
        #expect(p("") == nil)
        #expect(p("someday") == nil)
        #expect(p("feb 30") == nil)
        #expect(p("13pm") == nil)
        #expect(p("next week") == nil)
    }
}

@Suite struct DueTests {
    @Test func storageRoundTrip() {
        let t = Due.time(at(2026, 11, 20, 15))
        #expect(t.stored == "2026-11-20T20:00:00Z")
        #expect(Due(stored: t.stored) == t)
        #expect(Due(stored: "2026-11-20") == .day("2026-11-20"))
    }

    @Test func allDayKeepsItsDateInAnyTimeZone() {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        #expect(Due.day("2026-11-20").dayKey(tokyo) == "2026-11-20")
    }

    @Test func labels() {
        #expect(Due.day("2026-11-15").label(now: now, calendar: ny) == "Today")
        #expect(Due.time(at(2026, 11, 16, 15)).label(now: now, calendar: ny) == "Tomorrow 3:00 PM")
        #expect(Due.day("2026-11-20").label(now: now, calendar: ny) == "Fri")
        #expect(Due.day("2026-12-01").label(now: now, calendar: ny) == "Dec 1")
        #expect(Due.day("2027-01-04").label(now: now, calendar: ny) == "Jan 4, 2027")
    }
}

@Suite struct AgendaTests {
    func item(_ id: Int64, _ status: Status?, _ due: Due?, updated: Date = at(2026, 11, 1)) -> Item {
        Item(id: id, body: "#\(id)", status: status, due: due, createdAt: at(2026, 11, 1, Int(id)), updatedAt: updated)
    }

    @Test func bucketsAroundMidnight() {
        let late = at(2026, 11, 15, 23, 59)
        let items = [
            item(1, .open, .day("2026-11-14")),                 // overdue
            item(2, .open, .day("2026-11-15")),                 // today (all-day isn't overdue until tomorrow)
            item(3, .open, .time(at(2026, 11, 15, 9))),         // overdue: time passed
            item(4, nil, .time(at(2026, 11, 15, 9))),           // past note today: still today
            item(5, nil, .day("2026-11-14")),                   // past note: dropped
            item(6, .open, .day("2026-11-16")),                 // upcoming
            item(7, nil, .time(at(2026, 11, 16, 0, 30))),       // upcoming
            item(8, .open, nil),                                // todo
            item(9, nil, nil),                                  // note
            item(10, .done, .day("2026-11-15"), updated: at(2026, 11, 15, 8)),  // done today
            item(11, .done, nil, updated: at(2026, 11, 14, 8)), // done yesterday: dropped
        ]
        let a = Agenda.build(items, now: late, calendar: ny)
        #expect(a.overdue.map(\.id) == [1, 3])
        #expect(a.today.map(\.id) == [2, 4])
        #expect(a.upcoming.map(\.id) == [6, 7])
        #expect(a.todo.map(\.id) == [8])
        #expect(a.notes.map(\.id) == [9])
        #expect(a.doneToday.map(\.id) == [10])
    }
}

@Suite struct StoreTests {
    func tempStore() throws -> Store {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return try Store(path: dir.appendingPathComponent("jot.db").path)
    }

    @Test func crud() throws {
        let s = try tempStore()
        let a = try s.add("buy milk", status: .open, due: .day("2026-11-16"), now: now)
        #expect(a.body == "buy milk" && a.status == .open && a.due == .day("2026-11-16"))

        var edited = a
        edited.body = "buy oat milk"
        edited.due = .time(at(2026, 11, 16, 9))
        try s.update(edited, now: now)
        #expect(try s.get(a.id)?.body == "buy oat milk")
        #expect(try s.get(a.id)?.due == .time(at(2026, 11, 16, 9)))

        #expect(try s.setDone(a.id, now: now))
        #expect(try s.get(a.id)?.status == .done)
        #expect(try s.delete(a.id))
        #expect(try s.get(a.id) == nil)
        #expect(try s.delete(a.id) == false)
    }

    @Test func searchFindsMidBodyWord() throws {
        let s = try tempStore()
        try s.add("call the dentist about Tuesday")
        try s.add("unrelated")
        #expect(try s.search("dentist").map(\.body) == ["call the dentist about Tuesday"])
    }

    @Test func agendaSkipsOldDoneItems() throws {
        let s = try tempStore()
        let old = try s.add("old", status: .open, now: at(2026, 11, 1))
        try s.setDone(old.id, now: at(2026, 11, 10))
        let fresh = try s.add("fresh", status: .open, now: at(2026, 11, 1))
        try s.setDone(fresh.id, now: at(2026, 11, 15, 8))
        #expect(try s.agenda(now: now, calendar: ny).doneToday.map(\.body) == ["fresh"])
    }

    @Test func backupRestores() throws {
        let s = try tempStore()
        try s.add("keep me")
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".db").path
        try s.backup(to: dest)
        #expect(try Store(path: dest).search("keep").count == 1)
    }
}
