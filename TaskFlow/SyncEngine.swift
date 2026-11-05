//
//  SyncEngine.swift
//  TaskFlow
//
//

import Foundation

final class SyncEngine {
    
    static let shared = SyncEngine()
    
    private var syncTask: Task<Void, Never>?
    
    private(set) var lastChecksum = 0
    
    func apply(_ checksum: Int) {
        lastChecksum = checksum
    }
    
    func startSyncLoop() {
        syncTask?.cancel()
        syncTask = Task.detached(priority: .background) {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                let checksum = SyncEngine.performSync()
                await SyncEngine.shared.apply(checksum)
            }
        }
    }
    
    nonisolated static func performSync() -> Int {
        var values = (0..<1_500_000).map { ($0 &* 2_654_435_761) % 1_000_003 }
        values.sort()
        return values[values.count / 2]
    }
    
}
