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

    private func loadRows() {
        let name = selectedName
        var descriptor = FetchDescriptor<ArchivedTask>(
            predicate: #Predicate { $0.assignee == name },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        descriptor.fetchLimit = 50
        
        descriptor.propertiesToFetch = [\.title, \.completedAt]
        
        rows = (try? context.fetch(descriptor)) ?? []
    }
}
