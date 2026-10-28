import Foundation
import os

struct ActivityItem: Codable, Identifiable {
    let id: UUID
    let author: String
    let text: String
    let timestamp: Date
}

enum FeedCache {
    static let cachedItemCount = 15_000

    static func makeData(count: Int) -> Data {
        let authors = ["Priya Raman", "Marcus Webb", "Dana Ortiz"]
        let items = (0..<count).map { index in
            ActivityItem(
                id: UUID(),
                author: authors[index % authors.count],
                text: "Updated task #\(index) and left a comment for the team.",
                timestamp: Date.now.addingTimeInterval(-Double(index) * 60)
            )
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return (try? encoder.encode(items)) ?? Data()
    }

    static var cacheURL: URL {
        URL.cachesDirectory.appending(path: "activity-feed.json")
    }

    static func decodeCachedFeed() -> [ActivityItem] {
        // First launch only: write the cache file. Not part of the measured interval.
        if !FileManager.default.fileExists(atPath: cacheURL.path()) {
            try? makeData(count: cachedItemCount).write(to: cacheURL)
        }

        let signposter = PerfSignposts.signposter
        let state = signposter.beginInterval("Decode Cached Feed")
        defer { signposter.endInterval("Decode Cached Feed", state) }

        guard let data = try? Data(contentsOf: cacheURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ActivityItem].self, from: data)) ?? []
    }
}
