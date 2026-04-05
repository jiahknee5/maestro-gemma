import SwiftUI
import SwiftData

struct SessionSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    let session: PracticeSession

    @State private var aiSummary = ""
    @State private var isLoadingSummary = true
    @State private var isLoadingPlan = false
    @State private var practicePlan = ""
    @State private var showPlan = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Score rings
                HStack(spacing: 32) {
                    ScoreRingView(label: "Posture", score: session.postureScore)
                    ScoreRingView(label: "Intonation", score: session.intonationScore)
                    VStack {
                        Text(formatDuration(session.duration))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                // AI Summary
                VStack(alignment: .leading, spacing: 8) {
                    Label("Session Summary", systemImage: "sparkles")
                        .font(.headline)

                    if isLoadingSummary {
                        HStack {
                            ProgressView()
                            Text("Generating summary...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(aiSummary)
                            .font(.body)
                    }
                }

                // Top Issues
                if !session.topIssues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Top Issues", systemImage: "list.bullet")
                            .font(.headline)

                        ForEach(session.topIssues, id: \.0) { category, count in
                            HStack {
                                Text(category.displayName)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(count)x")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .accessibilityLabel("\(category.displayName): \(count) times")
                        }
                    }
                }

                // Practice Plan
                if showPlan && !practicePlan.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("This Week's Practice Plan", systemImage: "calendar.badge.checkmark")
                            .font(.headline)
                        Text(practicePlan)
                            .font(.body)
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    Button(action: generatePlan) {
                        Label(isLoadingPlan ? "Generating..." : "Generate Practice Plan",
                              systemImage: "calendar.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isLoadingPlan)
                    .accessibilityLabel("Generate 5-day practice plan")

                    NavigationLink(destination: TeacherReportView(session: session)) {
                        Label("Share with Teacher", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Generate teacher report")
                }
            }
            .padding()
        }
        .navigationTitle("Practice Summary")
        .navigationBarTitleDisplayMode(.inline)
        .task { await generateSummary() }
    }

    private func generateSummary() async {
        let issueList = session.topIssues.map { "\($0.0.displayName): \($0.1)x" }.joined(separator: ", ")
        let prompt = "Session: \(formatDuration(session.duration)) duration. Issues: \(issueList.isEmpty ? "none detected" : issueList). Total feedback events: \(session.events.count)."
        let (summary, _) = await GemmaCoach.shared.analyze(requestType: .sessionSummary, prompt: prompt)
        await MainActor.run {
            aiSummary = summary
            session.aiSummary = summary
            isLoadingSummary = false
        }
    }

    private func generatePlan() {
        isLoadingPlan = true
        Task {
            let issueList = session.topIssues.map { $0.0.displayName }.joined(separator: ", ")
            let prompt = "Student's main issues from recent practice: \(issueList.isEmpty ? "general technique" : issueList). Create a 5-day practice plan."
            let (plan, _) = await GemmaCoach.shared.analyze(requestType: .practicePlan, prompt: prompt)
            await MainActor.run {
                practicePlan = plan
                session.practicePlan = plan
                showPlan = true
                isLoadingPlan = false
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }
}

struct ScoreRingView: View {
    let label: String
    let score: Int

    private var color: Color {
        score >= 80 ? .green : score >= 60 ? .yellow : .red
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                Text("\(score)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityLabel("\(label) score: \(score) percent")
        .accessibilityValue("\(score)")
    }
}
