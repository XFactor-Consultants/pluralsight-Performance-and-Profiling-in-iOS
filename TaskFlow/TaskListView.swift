import SwiftUI
import Combine

struct TaskListView: View {
    @Environment(TasksStore.self) private var tasksStore
    @State private var sortOrder: SortOrder = .dueDate
    @State private var secondsSinceSync = 0

    enum SortOrder: String, CaseIterable, Identifiable {
        case dueDate = "Due Date"
        case priority = "Priority"
        var id: String { rawValue }
    }

    private var sortedTasks: [TaskItem] {
        switch sortOrder {
        case .dueDate:
            tasksStore.tasks.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .priority:
            tasksStore.tasks.sorted { $0.priority > $1.priority }
        }
    }

    var body: some View {
        NavigationStack {
            List(sortedTasks) { task in
                NavigationLink(value: task.id) {
                    TaskRowView(task: task, onToggle: {
                        tasksStore.toggleComplete(task)
                    })
                }
                .swipeActions(edge: .leading) {
                    Button {
                        tasksStore.toggleComplete(task)
                    } label: {
                        Label(
                            task.isComplete ? "Reopen" : "Done",
                            systemImage: task.isComplete ? "arrow.uturn.backward" : "checkmark"
                        )
                    }
                    .tint(.green)
                }
                .contextMenu {
                    ShareLink(item: task.shareSummary) {
                        Label("Share Task", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Tasks")
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .symbolEffect(.pulse, options: .repeating)
                    Text("Synced \(secondsSinceSync)s ago")
                }
                .font(.caption)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(.bar)
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                secondsSinceSync += 1
            }
            .navigationDestination(for: UUID.self) { id in
                if let task = tasksStore.task(id: id) {
                    TaskDetailView(task: task)
                }
            }
            .toolbar {
                Menu {
                    Picker("Sort By", selection: $sortOrder) {
                        ForEach(SortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
    }
}

struct TaskRowView: View {
    @Environment(TasksStore.self) private var tasksStore
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isComplete ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .strikethrough(task.isComplete)
                    .foregroundStyle(task.isComplete ? .secondary : .primary)

                HStack(spacing: 8) {
                    if let dueDate = task.dueDate {
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }
                    if let assignee = task.assignee {
                        Text(assignee.initials)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                        Text("\(tasksStore.openTaskCount(for: assignee)) open")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }

            Spacer()

            if task.isSensitive {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
            }

            Image(systemName: task.priority.systemImage)
                .foregroundStyle(priorityColor)
        }
        .padding(.vertical, 2)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: .gray
        case .medium: .orange
        case .high: .red
        }
    }
}

#Preview {
    TaskListView()
        .environment(TasksStore())
}
