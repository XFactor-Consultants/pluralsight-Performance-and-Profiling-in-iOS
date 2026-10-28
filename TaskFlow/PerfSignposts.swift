import OSLog

enum PerfSignposts {
    // The pointsOfInterest category is what puts these intervals on the
    // Points of Interest track in Instruments.
    nonisolated static let signposter = OSSignposter(
        logHandle: OSLog(subsystem: "TaskFlow", category: .pointsOfInterest)
    )
}
