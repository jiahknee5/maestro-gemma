import SwiftUI

struct TeacherReportView: View {
    let session: PracticeSession
    @State private var reportText = ""
    @State private var isLoading = true
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    HStack {
                        ProgressView()
                        Text("Generating report...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if reportText.hasPrefix("Connect to") {
                    ContentUnavailableView(
                        "Home Network Required",
                        systemImage: "wifi.slash",
                        description: Text("Connect to your home network to generate a teacher report using the full AI model.")
                    )
                    .accessibilityLabel("Home network required for teacher report")
                } else {
                    Text(reportText)
                        .font(.body)
                        .padding()
                        .accessibilityLabel("Teacher report: \(reportText)")

                    Button(action: { showShareSheet = true }) {
                        Label("Share with Teacher", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Share teacher report")
                }
            }
        }
        .navigationTitle("Teacher Report")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [reportText])
        }
        .task { await generateReport() }
    }

    private func generateReport() async {
        let issueList = session.topIssues
            .map { "\($0.0.displayName): \($0.1) occurrence\($0.1 == 1 ? "" : "s")" }
            .joined(separator: ", ")

        let prompt = """
        Practice session on \(session.startedAt.formatted(date: .abbreviated, time: .omitted)):
        Duration: \(formatDuration(session.duration))
        Top issues observed: \(issueList.isEmpty ? "No significant issues detected" : issueList)
        Total AI coaching events: \(session.events.count)
        AI session summary: \(session.aiSummary ?? "Not available")
        """

        let (report, _) = await GemmaCoach.shared.analyze(requestType: .teacherReport, prompt: prompt)
        await MainActor.run {
            reportText = report
            isLoading = false
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return minutes > 0 ? "\(minutes) minutes \(seconds) seconds" : "\(seconds) seconds"
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
