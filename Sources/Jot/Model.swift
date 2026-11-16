import Foundation
import JotCore

final class Model: ObservableObject {
    @Published var agenda = Agenda()
    @Published var query = "" { didSet { reload() } }
    @Published var results: [Item] = []
    @Published var error: String?
    @Published var opened = 0          // bumped on each open so the panel can refocus capture
    var close: () -> Void = {}

    private let store: Store?

    init() {
        do { store = try Store() } catch {
            store = nil
            self.error = "\(error)"
        }
        reload()
    }

    /// Re-read from disk: the widget and CLI write to the same DB.
    func reload() {
        attempt { _ in }
    }

    func add(_ body: String, todo: Bool, due: Due?) {
        attempt { try $0.add(body, status: todo ? .open : nil, due: due) }
    }

    func toggleDone(_ item: Item) {
        attempt { try $0.setDone(item.id, item.status != .done) }
    }

    func save(_ item: Item) {
        attempt { try $0.update(item) }
    }

    func delete(_ item: Item) {
        attempt { try $0.delete(item.id) }
    }

    private func attempt(_ change: (Store) throws -> Void) {
        guard let store else { return }
        do {
            try change(store)
            agenda = try store.agenda()
            results = query.isEmpty ? [] : try store.search(query)
            error = nil
        } catch {
            self.error = "\(error)"
        }
    }
}
