import SwiftUI
import SwiftData

@main
struct TaskFlowApp: App {
    @State private var tasksStore = TasksStore()
    @State private var activityStore = ActivityStore()
    private let container: ModelContainer

    init() {
        let container = try! ModelContainer(for: ArchivedTask.self)
        ArchiveSeeder.seedIfNeeded(in: container.mainContext)
        self.container = container
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(tasksStore)
                .environment(activityStore)
        }
        .modelContainer(container)
    }
}
