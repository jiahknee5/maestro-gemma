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
    @State private var sessionStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var lastCoachingText: String = ""

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

                // Body positioning guide (fades when body detected)
                BodyGuideOverlay(bodyDetected: postureAnalyzer.bodyDetected)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Pitch display
                    PitchDisplayView(note: pitchDetector.detectedNote, cents: pitchDetector.detectedCents)
                        .padding(.top, 60)

                    Spacer()

                    // Session timer
                    if isSessionActive {
                        Text(formatElapsed(elapsedTime))
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.bottom, 4)
                    }

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
        sessionStartTime = Date()
        elapsedTime = 0
        lastCoachingText = ""
        coachingText = "Great! Let's practice. I'm watching your technique."

        pitchDetector.start()
        cameraManager.start()
        startCoachingLoop()
        startTimer()
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

    // MARK: - Timer

    private func startTimer() {
        Task {
            while !Task.isCancelled && isSessionActive {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let start = sessionStartTime else { break }
                await MainActor.run { elapsedTime = Date().timeIntervalSince(start) }
            }
        }
    }

    private func formatElapsed(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Coaching Loop

    private func startCoachingLoop() {
        coachingTask = Task {
            while !Task.isCancelled && isSessionActive {
                // Wait BEFORE inference so previous response has time to display
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { break }

                let issues = postureAnalyzer.postureIssues
                let note = pitchDetector.detectedNote
                let cents = pitchDetector.detectedCents

                // Capture camera frame for Gemma vision
                let frameBase64 = cameraManager.captureFrameBase64()

                let prompt = buildRealtimePrompt(issues: issues, note: note, cents: cents)
                let (text, source) = await GemmaCoach.shared.analyze(
                    requestType: .realtimeFrame,
                    prompt: prompt,
                    imageBase64: frameBase64
                )

                guard !Task.isCancelled else { break }

                // Skip if model returned same text (avoid repetitive display)
                guard text != lastCoachingText else { continue }

                // Log to session with inferred severity
                if let session = currentSession, !text.contains("warming up") {
                    let category = inferCategory(from: issues, note: note)
                    let severity = inferSeverity(issues: issues, cents: cents)
                    let event = FeedbackEvent(category: category, message: text, severity: severity, source: source)
                    session.events.append(event)
                }

                await MainActor.run {
                    lastCoachingText = text
                    coachingText = text
                    coachingSource = source
                }
            }
        }
    }

    private func buildRealtimePrompt(issues: [String], note: String, cents: Int) -> String {
        var parts: [String] = []

        // Sensor data as context alongside the image
        if issues.contains("raisedBowShoulder") { parts.append("Sensor: right shoulder is raised") }
        if issues.contains("lowBowElbow") { parts.append("Sensor: bow arm elbow is dropping") }
        if issues.contains("headTiltedAway") { parts.append("Sensor: head tilting away from chin rest") }
        if issues.contains("collapsedLeftWrist") { parts.append("Sensor: left wrist is collapsing") }
        if issues.contains("bodyLeaning") { parts.append("Sensor: body is leaning") }
        if note != "—" {
            if abs(cents) > 20 {
                let direction = cents > 0 ? "sharp" : "flat"
                parts.append("Microphone: playing \(note), \(abs(cents)) cents \(direction)")
            } else {
                parts.append("Microphone: playing \(note), in tune")
            }
        }
        if parts.isEmpty { parts.append("Sensors: no issues detected") }

        return "Look at the image of the student practicing violin. \(parts.joined(separator: ". ")). Based on what you SEE and the sensor data, give ONE short coaching tip."
    }

    private func inferCategory(from issues: [String], note: String) -> FeedbackCategory {
        if issues.contains("raisedBowShoulder") || issues.contains("lowBowElbow") { return .bowArm }
        if issues.contains("collapsedLeftWrist") { return .leftHand }
        if issues.contains("headTiltedAway") || issues.contains("bodyLeaning") { return .posture }
        if note != "—" { return .intonation }
        return .general
    }

    private func inferSeverity(issues: [String], cents: Int) -> Severity {
        if issues.isEmpty && abs(cents) <= 20 { return .encouragement }
        if issues.count >= 2 || abs(cents) > 40 { return .correction }
        return .suggestion
    }
}
