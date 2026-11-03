import SwiftUI
import UIKit

struct RootView: View {
    @Environment(TasksStore.self) private var tasksStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            Tab("Tasks", systemImage: "checklist") {
                TaskListView()
            }
            Tab("Activity", systemImage: "bolt") {
                ActivityView()
            }
            Tab("History", systemImage: "clock") {
                HistoryView()
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
        .task {
            tasksStore.warmAvatarCache()
            tasksStore.cachedFeed = FeedCache.decodeCachedFeed()
            await tasksStore.loadSearchIndex()
        }
        // Refreshes the index on return to the foreground; skipped if nothing changed.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await tasksStore.loadSearchIndex() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            tasksStore.avatarCache.removeAll()
        }
    }
}

#Preview {
    RootView()
        .environment(TasksStore())
        .environment(ActivityStore())
}
