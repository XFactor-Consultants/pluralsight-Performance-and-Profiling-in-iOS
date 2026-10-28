import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(TasksStore.self) private var tasksStore
    @State private var selectedName = "Priya Raman"
    @State private var rows: [ArchivedTask] = []

    var body: some View {
        NavigationStack {
            List(rows, id: \.persistentModelID) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title)
                    Text(row.completedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("History")
            .toolbar {
                Picker("Teammate", selection: $selectedName) {
                    ForEach(tasksStore.teammates) { teammate in
                        Text(teammate.name).tag(teammate.name)
                    }
                }
                .pickerStyle(.menu)
            }
            .onAppear { loadRows() }
            .onChange(of: selectedName) { loadRows() }
        }
    }

    // Fetches the entire archive, then filters it on the main thread.
    private func loadRows() {
        let all = (try? context.fetch(FetchDescriptor<ArchivedTask>())) ?? []
        rows = all
            .filter { $0.assignee == selectedName }
            .sorted { $0.completedAt > $1.completedAt }
    }
}
