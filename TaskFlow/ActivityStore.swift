import SwiftUI

@Observable
final class ActivityStore {
    private(set) var items: [ActivityItem] = []
    private(set) var loadCount = 0

    func load() async {
        loadCount += 1

        // Three independent requests, awaited one after another.
        let feedData = try? await fetchFeed()
        let mentionData = try? await fetchMentions()
        let relatedData = try? await fetchRelated()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var combined: [ActivityItem] = []
        for data in [feedData, mentionData, relatedData] {
            if let data, let decoded = try? decoder.decode([ActivityItem].self, from: data) {
                combined.append(contentsOf: decoded)
            }
        }
        items = combined
    }

    func fetchFeed() async throws -> Data {
        try await Task.sleep(for: .milliseconds(350))
        return FeedCache.makeData(count: 1_500)
    }

    func fetchMentions() async throws -> Data {
        try await Task.sleep(for: .milliseconds(250))
        return FeedCache.makeData(count: 500)
    }

    func fetchRelated() async throws -> Data {
        try await Task.sleep(for: .milliseconds(200))
        return FeedCache.makeData(count: 500)
    }
}
