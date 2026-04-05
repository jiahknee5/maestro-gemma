import SwiftUI
import SwiftData
import AVFoundation
import Vision

struct PracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var pitchDetector = PitchDetector()
    @StateObject private var postureAnalyzer = PostureAnalyzer()
    @StateObject private var cameraManager = CameraManager()

    @State private var isSessionActive = false
    @State private var currentSession: PracticeSession?
    @State private var coachingText = "Tap Start to begin your practice session."
    @State private var coachingSource: RoutingTarget = .onDevice
    @State private var showAskCoach = false
    @State private var coachingTask: Task<Void, Never>?
    @State private var navigateToSummary = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera feed
                CameraPreview(cameraManager: cameraManager)
                    .ignoresSafeArea()
                    .accessibilityLabel("Camera feed")
                    .accessibilityHint("Shows live posture analysis")

                // Posture skeleton overlay
                PostureSkeletonView(bodyPoints: postureAnalyzer.bodyPoints)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    // Pitch display
                    PitchDisplayView(note: pitchDetector.detectedNote, cents: pitchDetector.detectedCents)
                        .padding(.top, 60)

                    Spacer()

                    // Coaching overlay
                    CoachingOverlayView(text: coachingText, source: coachingSource)
                        .padding(.horizontal, 20)

                    // Controls
                    HStack(spacing: 20) {
                        if isSessionActive {
                            Button(action: stopSession) {
                                Label("Stop", systemImage: "stop.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(Color.red.opacity(0.85))
                                    .clipShape(Capsule())
                            }
                            .accessibilityLabel("Stop practice session")

                            Button(action: { showAskCoach = true }) {
                                Label("Ask Coach", systemImage: "questionmark.bubble.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(Color.blue.opacity(0.85))
                                    .clipShape(Capsule())
                            }
                            .accessibilityLabel("Ask the AI coach a question")
                        } else {
                            Button(action: startSession) {
                                Label("Start Practice", systemImage: "play.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 14)
                                    .background(Color.green.opacity(0.85))
                                    .clipShape(Capsule())
                            }
                            .accessibilityLabel("Start practice session")
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $navigateToSummary) {
                if let session = currentSession {
                    SessionSummaryView(session: session)
                }
            }
            .sheet(isPresented: $showAskCoach) {
                AskCoachView()
            }
        }
        .onAppear {
            cameraManager.postureAnalyzer = postureAnalyzer
            cameraManager.requestPermissions()
        }
    }

    // MARK: - Session Control

    private func startSession() {
        let session = PracticeSession()
        modelContext.insert(session)
        currentSession = session
        isSessionActive = true
        coachingText = "Great! Let's practice. I'm watching your technique."

        pitchDetector.start()
        cameraManager.start()
        startCoachingLoop()
    }

    private func stopSession() {
        guard let session = currentSession else { return }
        coachingTask?.cancel()
        coachingTask = nil
        pitchDetector.stop()
        cameraManager.stop()

        session.endedAt = Date()
        isSessionActive = false

        guard session.duration >= 30 else {
            coachingText = "Session too short for a summary — keep practicing!"
            return
        }

        navigateToSummary = true
    }

    // MARK: - Coaching Loop

    private func startCoachingLoop() {
        coachingTask = Task {
            while !Task.isCancelled && isSessionActive {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // every 2s
                guard !Task.isCancelled else { break }

                let issues = postureAnalyzer.postureIssues
                let note = pitchDetector.detectedNote
                let cents = pitchDetector.detectedCents

                let prompt = buildRealtimePrompt(issues: issues, note: note, cents: cents)
                let (text, source) = await GemmaCoach.shared.analyze(requestType: .realtimeFrame, prompt: prompt)

                guard !Task.isCancelled else { break }

                // Log to session
                if let session = currentSession, !text.contains("warming up") {
                    let category = inferCategory(from: issues, note: note)
                    let event = FeedbackEvent(category: category, message: text, severity: .suggestion, source: source)
                    session.events.append(event)
                }

                await MainActor.run {
                    coachingText = text
                    coachingSource = source
                }
            }
        }
    }

    private func buildRealtimePrompt(issues: [String], note: String, cents: Int) -> String {
        var parts: [String] = []
        if issues.contains("raisedBowShoulder") { parts.append("raised bow shoulder detected") }
        if issues.contains("lowBowElbow") { parts.append("bow elbow is low") }
        if note != "—" && abs(cents) > 15 { parts.append("intonation: \(note) is \(cents > 0 ? "+\(cents)" : "\(cents)") cents") }
        if parts.isEmpty { parts.append("technique looks good so far") }
        return "Current observations: \(parts.joined(separator: ", ")). Give one short coaching tip."
    }

    private func inferCategory(from issues: [String], note: String) -> FeedbackCategory {
        if issues.contains("raisedBowShoulder") { return .bowArm }
        if issues.contains("lowBowElbow") { return .bowArm }
        if note != "—" { return .intonation }
        return .general
    }
}
