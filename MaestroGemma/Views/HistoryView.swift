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

    private var totalPracticeTime: TimeInterval {
        completedSessions.reduce(0) { $0 + $1.duration }
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
                        // Stats header
                        HStack(spacing: 24) {
                            if streak > 0 {
                                VStack(spacing: 2) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text("\(streak)")
                                            .font(.title3.bold())
                                    }
                                    Text("day streak")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            VStack(spacing: 2) {
                                Text("\(completedSessions.count)")
                                    .font(.title3.bold())
                                Text("sessions")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            VStack(spacing: 2) {
                                Text(formatTotalTime(totalPracticeTime))
                                    .font(.title3.bold())
                                Text("total")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .accessibilityLabel("\(streak) day streak, \(completedSessions.count) sessions, \(formatTotalTime(totalPracticeTime)) total practice")

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

    private func formatTotalTime(_ t: TimeInterval) -> String {
        let hours = Int(t) / 3600
        let mins = (Int(t) % 3600) / 60
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }
}

struct SessionRowView: View {
    let session: PracticeSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
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
            Spacer()
            HStack(spacing: 12) {
                MiniScore(label: "P", score: session.postureScore)
                MiniScore(label: "I", score: session.intonationScore)
            }
        }
        .padding(.vertical, 4)
        .accessibilityLabel("Session on \(session.startedAt.formatted(date: .abbreviated, time: .shortened)), \(formatDuration(session.duration)), posture \(session.postureScore), intonation \(session.intonationScore)")
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }
}

struct MiniScore: View {
    let label: String
    let score: Int

    private var color: Color {
        score >= 80 ? .green : score >= 60 ? .yellow : .red
    }

    var body: some View {
        VStack(spacing: 1) {
            Text("\(score)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(width: 30)
    }
}
