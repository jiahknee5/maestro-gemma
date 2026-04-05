import SwiftUI
import SwiftData

@main
struct MaestroGemmaApp: App {
    @StateObject private var downloader = ModelDownloader.shared

    var body: some Scene {
        WindowGroup {
            if downloader.isReady {
                ContentView()
                    .modelContainer(for: [PracticeSession.self, FeedbackEvent.self])
            } else {
                ModelLoadingView(downloader: downloader)
            }
        }
    }
}
