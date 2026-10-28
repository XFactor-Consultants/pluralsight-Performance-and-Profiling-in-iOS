import SwiftUI

struct ActivityView: View {
    @Environment(ActivityStore.self) private var store

    var body: some View {
        NavigationStack {
            List(store.items) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.text)
                    Text(item.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Activity")
            .toolbar {
                Text("Loads: \(store.loadCount)")
                    .font(.caption)
                    .monospacedDigit()
            }
            // Two triggers for one visit. This is the "loads more than once" bug.
            .task {
                await store.load()
            }
            .onAppear {
                Task {
                    await store.load()
                }
            }
        }
    }
}

#Preview {
    ActivityView()
        .environment(ActivityStore())
}
