import Foundation
import Observation

@Observable
final class TaskDetailModel {
    let taskID: UUID

    // About 2 to 3 MB per instance. Makes the staircase easy to see.
    @ObservationIgnored private var activityLog: [String]

    // The closure below captures self strongly, and self stores the closure.
    // That is the retain cycle: the model can never be released.
    @ObservationIgnored var onTasksChanged: (() -> Void)?

    init(taskID: UUID) {
        self.taskID = taskID
        self.activityLog = (0..<25_000).map { index in
            "Event \(index) recorded for task \(taskID.uuidString)"
        }
        self.onTasksChanged = {
            self.reload()
        }
    }

    func reload() {
        activityLog.append("Reloaded")
    }
}
