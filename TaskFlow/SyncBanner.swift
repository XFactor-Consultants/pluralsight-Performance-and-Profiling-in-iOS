import SwiftUI
import Combine

struct SyncBanner: View {
    @State private var lastSync = Date()

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .symbolEffect(.pulse, options: .repeating)
            Text("Synced \(lastSync, style: .relative) ago")
        }
        .font(.caption)
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
}
