import Foundation
import os

struct SearchIndex {
    private(set) var postings: [String: [UUID]] = [:]

    init(tasks: [TaskItem]) {
        let signposter = PerfSignposts.signposter
        let state = signposter.beginInterval("Build Search Index")

        var built: [String: [UUID]] = [:]
        for task in tasks {
            for gram in Self.trigrams(of: task.title + " " + task.notes) {
                built[gram, default: []].append(task.id)
            }
        }
        postings = built

        signposter.endInterval("Build Search Index", state)
    }

    static func trigrams(of text: String) -> [String] {
        let characters = Array(text.lowercased())
        guard characters.count >= 3 else { return [] }
        return (0...(characters.count - 3)).map { start in
            String(characters[start..<(start + 3)])
        }
    }
}
