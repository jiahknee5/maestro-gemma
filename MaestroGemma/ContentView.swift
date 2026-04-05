import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PracticeView()
                .tabItem { Label("Practice", systemImage: "music.note") }
                .accessibilityLabel("Practice")

            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
                .accessibilityLabel("History")
        }
        .task {
            await GemmaCoach.shared.load()
        }
    }
}
