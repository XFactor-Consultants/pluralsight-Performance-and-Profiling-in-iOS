import Foundation
import SwiftData

@Model
final class ArchivedTask {
    var title: String
    var notes: String
    var assignee: String
    var completedAt: Date

    init(title: String, notes: String, assignee: String, completedAt: Date) {
        self.title = title
        self.notes = notes
        self.assignee = assignee
        self.completedAt = completedAt
    }
}

enum ArchiveSeeder {
    static let archiveSize = 20_000

    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<ArchivedTask>())) ?? 0
        guard existing == 0 else { return }

        let names = ["Priya Raman", "Marcus Webb", "Dana Ortiz"]
        let note = String(repeating: "Archived note text for this completed task. ", count: 6)
        for index in 0..<archiveSize {
            context.insert(
                ArchivedTask(
                    title: "Completed task #\(index)",
                    notes: note,
                    assignee: names[index % names.count],
                    completedAt: Date.now.addingTimeInterval(-Double(index) * 3_600)
                )
            )
        }
        try? context.save()
    }
}
