import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \PracticeSession.startedAt, order: .reverse) private var sessions: [PracticeSession]

    private var completedSessions: [PracticeSession] {
        sessions.filter { $0.endedAt != nil && $0.duration >= 30 }
    }

    private var streak: Int {
        var count = 0
        var date = Calendar.current.startOfDay(for: Date())
        let sessionDates = Set(completedSessions.map { Calendar.current.startOfDay(for: $0.startedAt) })
        while sessionDates.contains(date) {
            count += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        }
        return count
    }

    var body: some View {
        NavigationStack {
            Group {
                if completedSessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions Yet",
                        systemImage: "music.note",
                        description: Text("Your practice history will appear here. Start your first session!")
                    )
                    .accessibilityLabel("No practice sessions yet. Start your first session.")
                } else {
                    List {
                        // Streak banner
                        if streak > 0 {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(streak) day streak")
                                    .font(.headline)
                            }
                            .accessibilityLabel("\(streak) day practice streak")
                        }

                        ForEach(completedSessions) { session in
                            NavigationLink(destination: SessionSummaryView(session: session)) {
                                SessionRowView(session: session)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct SessionRowView: View {
    let session: PracticeSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline.weight(.medium))
            HStack {
                Text(formatDuration(session.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !session.topIssues.isEmpty {
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(session.topIssues.first?.0.displayName ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityLabel("Session on \(session.startedAt.formatted(date: .abbreviated, time: .shortened)), \(formatDuration(session.duration))")
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }
}
