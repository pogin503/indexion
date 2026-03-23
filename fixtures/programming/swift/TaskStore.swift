import Foundation

/// A task with title and completion status.
struct Task: Identifiable {
    let id: UUID
    var title: String
    var done: Bool = false

    /// Returns a formatted summary.
    func summary() -> String {
        let status = done ? "✓" : "○"
        return "\(status) \(title)"
    }
}

/// Manages tasks in memory — supports add, complete, and list.
class TaskStore: ObservableObject {
    @Published private(set) var tasks: [Task] = []

    /// Adds a new task with the given title.
    func add(title: String) {
        tasks.append(Task(id: UUID(), title: title))
    }

    /// Marks the task with the given ID as done.
    func complete(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].done = true
    }

    /// Returns all pending tasks.
    var pending: [Task] {
        tasks.filter { !$0.done }
    }
}
