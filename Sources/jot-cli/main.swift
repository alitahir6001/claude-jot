import Foundation
import JotCore

let usage = """
    usage:
      jot-cli add [-t] [-d <date>] <text>   add a note (-t: TODO, -d: "fri 3pm", "nov 20", ...)
      jot-cli agenda [--json]
      jot-cli find <text> [--json]
      jot-cli done <id> | undo <id> | rm <id>
      jot-cli backup [dir]                  snapshot the DB (default ~/Documents/Jot Backups)
    """

struct Row: Encodable {
    let id: Int64, body: String, todo: Bool, done: Bool, label: String?
    init(_ i: Item) {
        id = i.id; body = i.body; todo = i.status != nil; done = i.status == .done
        label = i.due?.label()
    }
}

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write(Data((msg + "\n").utf8))
    exit(1)
}

func printJSON<T: Encodable>(_ v: T) {
    let e = JSONEncoder()
    e.outputFormatting = [.sortedKeys]
    print(String(decoding: try! e.encode(v), as: UTF8.self))
}

func line(_ i: Item) -> String {
    let box = i.status == nil ? "-" : (i.status == .done ? "[x]" : "[ ]")
    let when = i.due.map { "  (\($0.label()))" } ?? ""
    return "  #\(i.id) \(box) \(i.body)\(when)"
}

func idArg(_ args: [String]) -> Int64 {
    guard let s = args.first, let id = Int64(s.trimmingCharacters(in: ["#"])) else { fail(usage) }
    return id
}

var args = Array(CommandLine.arguments.dropFirst())
guard !args.isEmpty else { fail(usage) }
let cmd = args.removeFirst()
let json = args.contains("--json")
args.removeAll { $0 == "--json" }

do {
    let store = try Store()
    switch cmd {
    case "add":
        var todo = false, dateText: String?, words: [String] = []
        var it = args.makeIterator()
        while let a = it.next() {
            switch a {
            case "-t": todo = true
            case "-d":
                guard let d = it.next() else { fail("-d needs a date") }
                dateText = d
            default: words.append(a)
            }
        }
        let body = words.joined(separator: " ")
        guard !body.isEmpty else { fail(usage) }
        var due: Due?
        if let dateText {
            guard let d = DueParser.parse(dateText) else { fail("can't read date: \(dateText)") }
            due = d
        }
        let item = try store.add(body, status: todo ? .open : nil, due: due)
        print("added" + line(item))

    case "agenda":
        let a = try store.agenda()
        let sections: [(String, [Item])] = [
            ("overdue", a.overdue), ("today", a.today), ("upcoming", a.upcoming),
            ("todo", a.todo), ("notes", a.notes), ("doneToday", a.doneToday),
        ]
        if json {
            printJSON(Dictionary(uniqueKeysWithValues: sections.map { ($0.0, $0.1.map(Row.init)) }))
        } else {
            for (name, items) in sections where !items.isEmpty {
                print(name == "doneToday" ? "DONE TODAY" : name.uppercased())
                items.forEach { print(line($0)) }
            }
        }

    case "find":
        let results = try store.search(args.joined(separator: " "))
        if json { printJSON(results.map(Row.init)) } else { results.forEach { print(line($0)) } }

    case "done", "undo":
        guard try store.setDone(idArg(args), cmd == "done") else { fail("no such item") }

    case "rm":
        guard try store.delete(idArg(args)) else { fail("no such item") }

    case "backup":
        let dir = args.first.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Jot Backups")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        let dest = dir.appendingPathComponent("jot-\(f.string(from: Date())).db").path
        try store.backup(to: dest)
        print("backed up to \(dest)")

    default:
        fail(usage)
    }
} catch {
    fail("error: \(error)")
}
