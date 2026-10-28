import Foundation

// Named TaskItem, not Task, to avoid colliding with Swift Concurrency's `Task` type.
// This matters later in the series (Swift Concurrency course) and prevents confusing
// compiler errors the moment anyone writes `Task { ... }` in this codebase.
struct TaskItem: Identifiable, Equatable, Hashable {
    enum Priority: Int, CaseIterable, Comparable, Identifiable, Hashable {
        case low = 0
        case medium = 1
        case high = 2

        var id: Int { rawValue }

        var label: String {
            switch self {
            case .low: "Low"
            case .medium: "Medium"
            case .high: "High"
            }
        }

        var systemImage: String {
            switch self {
            case .low: "arrow.down.circle.fill"
            case .medium: "equal.circle.fill"
            case .high: "exclamationmark.circle.fill"
            }
        }

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    let id: UUID
    var title: String
    var notes: String
    var assignee: Teammate?
    var dueDate: Date?
    var priority: Priority
    var isSensitive: Bool
    var isComplete: Bool

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        assignee: Teammate? = nil,
        dueDate: Date? = nil,
        priority: Priority = .medium,
        isSensitive: Bool = false,
        isComplete: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.assignee = assignee
        self.dueDate = dueDate
        self.priority = priority
        self.isSensitive = isSensitive
        self.isComplete = isComplete
    }

    var isOverdue: Bool {
        guard let dueDate, !isComplete else { return false }
        return dueDate < .now
    }

    /// Plain-text summary used by the Share action.
    var shareSummary: String {
        var lines = ["Task: \(title)"]
        if let assignee {
            lines.append("Assigned to: \(assignee.name)")
        }
        if let dueDate {
            lines.append("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
        }
        lines.append("Priority: \(priority.label)")
        return lines.joined(separator: "\n")
    }
}

struct Teammate: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    var initials: String {
        name.split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }
}
