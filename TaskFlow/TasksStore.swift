import SwiftUI
import UIKit
import os

@Observable
final class TasksStore {
    static let generatedTaskCount = 5_000

    private(set) var tasks: [TaskItem]
    let teammates: [Teammate]

    // Launch-time work. Ignored by Observation: the UI never reads these.
    @ObservationIgnored var searchIndex: SearchIndex
    @ObservationIgnored var cachedFeed: [ActivityItem] = []
    @ObservationIgnored var avatarCache: [UUID: UIImage] = [:]

    init() {
        let priya = Teammate(name: "Priya Raman")
        let marcus = Teammate(name: "Marcus Webb")
        let dana = Teammate(name: "Dana Ortiz")
        teammates = [priya, marcus, dana]

        let day: TimeInterval = 60 * 60 * 24
        var seeded: [TaskItem] = [
            TaskItem(
                title: "Update emergency contact info",
                notes: "HR needs current emergency contacts on file before the offsite. Includes home address and phone numbers.",
                assignee: priya,
                dueDate: .now.addingTimeInterval(2 * day),
                priority: .high,
                isSensitive: true
            ),
            TaskItem(
                title: "Prepare sprint demo",
                notes: "Walk through the new filtering flow. Keep it under ten minutes.",
                assignee: marcus,
                dueDate: .now.addingTimeInterval(1 * day),
                priority: .high
            ),
            TaskItem(
                title: "Rotate shared server credentials",
                notes: "Quarterly rotation. Update the shared vault entry and notify the on-call channel.",
                assignee: dana,
                dueDate: .now.addingTimeInterval(5 * day),
                priority: .medium,
                isSensitive: true
            ),
            TaskItem(
                title: "Review Q3 roadmap draft",
                notes: "Leave comments directly in the doc before Thursday's planning meeting.",
                assignee: priya,
                dueDate: .now.addingTimeInterval(-1 * day),
                priority: .medium
            ),
            TaskItem(
                title: "Book venue for team offsite",
                notes: "Need space for twelve, projector, and decent coffee nearby.",
                assignee: dana,
                dueDate: .now.addingTimeInterval(9 * day),
                priority: .low
            ),
            TaskItem(
                title: "Fix onboarding flow copy",
                notes: "Second screen still says \"beta\" — swap in the approved wording.",
                assignee: marcus,
                dueDate: .now.addingTimeInterval(3 * day),
                priority: .low
            ),
            TaskItem(
                title: "Send weekly status update",
                notes: "Same format as last week. Include the demo recording link.",
                assignee: priya,
                dueDate: .now.addingTimeInterval(-2 * day),
                priority: .medium,
                isComplete: true
            )
        ]
        seeded.append(contentsOf: Self.makeTasks(count: Self.generatedTaskCount, teammates: [priya, marcus, dana]))
        tasks = seeded

        // Launch work, all on the main thread, all before the first frame.
        searchIndex = SearchIndex(tasks: seeded)
        cachedFeed = FeedCache.decodeCachedFeed()
        warmAvatarCache()
    }

    // MARK: - Seed data

    private static func makeTasks(count: Int, teammates: [Teammate]) -> [TaskItem] {
        var result: [TaskItem] = []
        let verbs = ["Review", "Update", "Draft", "Schedule", "Fix", "Prepare", "Archive", "Audit"]
        let nouns = ["roadmap", "onboarding flow", "vendor contract", "sprint report", "API docs",
                     "budget sheet", "design handoff", "release notes", "security checklist", "customer feedback"]
        let day: TimeInterval = 60 * 60 * 24

        for index in 0..<count {
            let verb = verbs[index % verbs.count]
            let noun = nouns[(index / verbs.count) % nouns.count]
            result.append(
                TaskItem(
                    title: "\(verb) \(noun) #\(index)",
                    notes: "Follow up with the team about the \(noun) before the next planning meeting. Reference ticket \(1000 + index).",
                    assignee: teammates[index % teammates.count],
                    dueDate: .now.addingTimeInterval(Double(index % 60 - 20) * day),
                    priority: TaskItem.Priority.allCases[index % 3],
                    isComplete: index % 7 == 0
                )
            )
        }
        return result
    }

    // MARK: - Launch-time work

    func rebuildSearchIndex() {
        searchIndex = SearchIndex(tasks: tasks)
    }

    func warmAvatarCache() {
        let signposter = PerfSignposts.signposter
        let state = signposter.beginInterval("Warm Avatar Cache")
        defer { signposter.endInterval("Warm Avatar Cache", state) }

        for teammate in teammates {
            let first = teammate.name.split(separator: " ").first.map(String.init) ?? ""
            let fileName = "avatar-" + first.lowercased()
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "jpg"),
                  let image = UIImage(contentsOfFile: url.path()) else { continue }
            // Force the full decode now. This is what makes the images expensive.
            avatarCache[teammate.id] = image.preparingForDisplay() ?? image
        }
    }

    // MARK: - Queries

    /// Used by every task row. Walks all tasks each time it is called.
    func openTaskCount(for teammate: Teammate) -> Int {
        tasks.filter { $0.assignee == teammate && !$0.isComplete }.count
    }

    // MARK: - Existing methods

    func task(id: UUID) -> TaskItem? {
        tasks.first { $0.id == id }
    }

    func toggleComplete(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isComplete.toggle()
    }
}
