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
    @State private var summarySource: RoutingTarget = .onDevice
    @State private var planSource: RoutingTarget = .onDevice

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
                    HStack {
                        Label("Session Summary", systemImage: "sparkles")
                            .font(.headline)
                        Spacer()
                        if !isLoadingSummary {
                            SourceBadge(source: summarySource)
                        }
                    }

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
                        HStack {
                            Label("This Week's Practice Plan", systemImage: "calendar.badge.checkmark")
                                .font(.headline)
                            Spacer()
                            SourceBadge(source: planSource)
                        }
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
        let encouragements = session.events.filter { $0.severity == .encouragement }.count
        let corrections = session.events.filter { $0.severity == .correction }.count
        let prompt = "Session: \(formatDuration(session.duration)). Issues: \(issueList.isEmpty ? "none" : issueList). \(session.events.count) coaching events (\(encouragements) encouragements, \(corrections) corrections). Posture score: \(session.postureScore)/100, Intonation score: \(session.intonationScore)/100."
        let (summary, source) = await GemmaCoach.shared.analyze(requestType: .sessionSummary, prompt: prompt)
        await MainActor.run {
            aiSummary = summary
            summarySource = source
            session.aiSummary = summary
            isLoadingSummary = false
        }
    }

    private func generatePlan() {
        isLoadingPlan = true
        Task {
            let issueList = session.topIssues.map { "\($0.0.displayName): \($0.1)x" }.joined(separator: ", ")
            let prompt = "Student's main issues: \(issueList.isEmpty ? "general technique" : issueList). Posture score: \(session.postureScore)/100. Intonation score: \(session.intonationScore)/100. Create a 5-day practice plan."
            let (plan, source) = await GemmaCoach.shared.analyze(requestType: .practicePlan, prompt: prompt)
            await MainActor.run {
                practicePlan = plan
                planSource = source
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

struct SourceBadge: View {
    let source: RoutingTarget

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(source == .localServer ? Color.blue : Color.green)
                .frame(width: 5, height: 5)
            Text(source == .localServer ? "27B" : "E2B")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(.tertiarySystemBackground))
        .clipShape(Capsule())
    }
}
