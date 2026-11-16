import JotCore
import SwiftUI

struct PanelView: View {
    @ObservedObject var model: Model
    @State private var text = ""
    @State private var todo = false
    @State private var dateText = ""
    @FocusState private var captureFocused: Bool

    private var parsed: Due? { DueParser.parse(dateText) }
    private var dateInvalid: Bool { !dateText.isEmpty && parsed == nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Jot something…", text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($captureFocused)
                .onSubmit(save)
            HStack(spacing: 8) {
                Toggle("TODO", isOn: $todo).toggleStyle(.checkbox)
                TextField("date: fri 3pm", text: $dateText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 130)
                    .onSubmit(save)
                Text(dateText.isEmpty ? "" : (parsed.map { "→ " + $0.label() } ?? "can't read date"))
                    .font(.caption)
                    .foregroundStyle(dateInvalid ? .red : .secondary)
                Spacer()
            }
            Divider()
            TextField("Search", text: $model.query).textFieldStyle(.roundedBorder)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if model.query.isEmpty {
                        let a = model.agenda
                        SectionView(title: "Overdue", items: a.overdue, model: model, urgent: true)
                        SectionView(title: "Today", items: a.today, model: model)
                        SectionView(title: "Upcoming", items: a.upcoming, model: model)
                        SectionView(title: "To do", items: a.todo, model: model)
                        SectionView(title: "Notes", items: a.notes, model: model)
                        SectionView(title: "Done today", items: a.doneToday, model: model)
                    } else {
                        SectionView(title: "Results", items: model.results, model: model)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let error = model.error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            HStack {
                Text("⌥⌘J to open · Enter to save").font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }.buttonStyle(.link).font(.caption)
            }
        }
        .padding(12)
        .frame(width: 380, height: 500)
        .onExitCommand { model.close() }
        .onReceive(model.$opened) { _ in captureFocused = true }
    }

    private func save() {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !dateInvalid else { return }
        model.add(body, todo: todo, due: parsed)
        text = ""
        dateText = ""
        todo = false
        captureFocused = true
    }
}

struct SectionView: View {
    let title: String
    let items: [Item]
    @ObservedObject var model: Model
    var urgent = false

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(urgent ? .red : .secondary)
                ForEach(items) { RowView(item: $0, model: model, urgent: urgent) }
            }
        }
    }
}

struct RowView: View {
    let item: Item
    @ObservedObject var model: Model
    var urgent = false
    @State private var editing = false
    @State private var editText = ""
    @State private var editDate = ""

    private var done: Bool { item.status == .done }

    var body: some View {
        if editing { editor } else { row }
    }

    private var row: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if item.status != nil {
                Button { model.toggleDone(item) } label: {
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "lightbulb").foregroundStyle(.secondary)
            }
            Text(item.body)
                .strikethrough(done)
                .foregroundStyle(done ? .secondary : .primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            if let due = item.due {
                Text(due.label()).font(.caption).foregroundStyle(urgent ? .red : .secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: startEditing)
        .contextMenu {
            Button("Edit", action: startEditing)
            Button(item.status == nil ? "Make TODO" : "Make note") {
                var copy = item
                copy.status = item.status == nil ? .open : nil
                model.save(copy)
            }
            Divider()
            Button("Delete", role: .destructive) { model.delete(item) }
        }
    }

    private var editor: some View {
        let parsed = DueParser.parse(editDate)
        let invalid = !editDate.isEmpty && parsed == nil
        return VStack(alignment: .leading, spacing: 4) {
            TextField("Text", text: $editText).textFieldStyle(.roundedBorder).onSubmit { commit(parsed, invalid) }
            HStack {
                TextField("date (blank = none)", text: $editDate)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                    .onSubmit { commit(parsed, invalid) }
                Text(editDate.isEmpty ? "" : (parsed.map { "→ " + $0.label() } ?? "can't read date"))
                    .font(.caption)
                    .foregroundStyle(invalid ? .red : .secondary)
                Spacer()
                Button("Cancel") { editing = false }
                Button("Save") { commit(parsed, invalid) }.keyboardShortcut(.defaultAction)
            }
        }
    }

    private func startEditing() {
        editText = item.body
        editDate = item.due.map(editableDate) ?? ""
        editing = true
    }

    private func commit(_ parsed: Due?, _ invalid: Bool) {
        let body = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, !invalid else { return }
        var copy = item
        copy.body = body
        copy.due = parsed
        model.save(copy)
        editing = false
    }

    /// Prefill in a form the parser reads back ("2026-11-20 3:00pm").
    private func editableDate(_ due: Due) -> String {
        switch due {
        case .day(let s): return s
        case .time(let d):
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd h:mma"
            return f.string(from: d).lowercased()
        }
    }
}
