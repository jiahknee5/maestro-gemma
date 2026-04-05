import SwiftUI
import SwiftData

@main
struct MaestroGemmaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [PracticeSession.self, FeedbackEvent.self])
        }
    }
}
