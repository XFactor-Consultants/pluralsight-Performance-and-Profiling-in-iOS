import SwiftUI
import Combine

struct SyncBanner: View {
    @State private var secondsSinceSync = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .symbolEffect(.pulse, options: .repeating)
            Text("Synced \(secondsSinceSync)s ago")
        }
        .font(.caption)
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(.bar)
        .onReceive(timer) { _ in secondsSinceSync += 1 }
    }
}
