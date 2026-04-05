import Foundation
import SwiftData

// MARK: - Routing

enum RoutingTarget: String, Codable {
    case onDevice     // Gemma 4 E2B via Cactus SDK
    case localServer  // Gemma 4 26B via Ollama on Mac Studio
}

enum RequestType {
    case realtimeFrame   // always on-device
    case askCoach        // Ollama if reachable, else on-device
    case sessionSummary  // Ollama if reachable, else on-device
    case practicePlan    // Ollama if reachable, else defer
    case teacherReport   // Ollama only
}

// MARK: - Feedback

enum FeedbackCategory: String, Codable, CaseIterable {
    case posture, bowArm, leftHand, intonation, tone, general

    var displayName: String {
        switch self {
        case .posture: return "Posture"
        case .bowArm: return "Bow Arm"
        case .leftHand: return "Left Hand"
        case .intonation: return "Intonation"
        case .tone: return "Tone"
        case .general: return "General"
        }
    }
}

enum Severity: String, Codable {
    case encouragement
    case suggestion
    case correction
}

// MARK: - SwiftData Models

@Model
final class PracticeSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var aiSummary: String?
    var practicePlan: String?
    @Relationship(deleteRule: .cascade) var events: [FeedbackEvent]

    init() {
        self.id = UUID()
        self.startedAt = Date()
        self.events = []
    }

    var duration: TimeInterval {
        guard let end = endedAt else { return Date().timeIntervalSince(startedAt) }
        return end.timeIntervalSince(startedAt)
    }

    var topIssues: [(FeedbackCategory, Int)] {
        var counts: [FeedbackCategory: Int] = [:]
        for event in events { counts[event.category, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }

    var postureScore: Int {
        let relevant = events.filter { $0.category == .posture || $0.category == .bowArm || $0.category == .leftHand }
        let corrections = relevant.filter { $0.severity == .correction }.count
        let total = max(relevant.count, 1)
        return max(0, 100 - (corrections * 100 / total))
    }

    var intonationScore: Int {
        let relevant = events.filter { $0.category == .intonation || $0.category == .tone }
        let corrections = relevant.filter { $0.severity == .correction }.count
        let total = max(relevant.count, 1)
        return max(0, 100 - (corrections * 100 / total))
    }
}

@Model
final class FeedbackEvent {
    var id: UUID
    var timestamp: Date
    var categoryRaw: String
    var message: String
    var severityRaw: String
    var sourceRaw: String

    init(category: FeedbackCategory, message: String, severity: Severity, source: RoutingTarget) {
        self.id = UUID()
        self.timestamp = Date()
        self.categoryRaw = category.rawValue
        self.message = message
        self.severityRaw = severity.rawValue
        self.sourceRaw = source.rawValue
    }

    var category: FeedbackCategory { FeedbackCategory(rawValue: categoryRaw) ?? .general }
    var severity: Severity { Severity(rawValue: severityRaw) ?? .suggestion }
    var source: RoutingTarget { RoutingTarget(rawValue: sourceRaw) ?? .onDevice }
}

// MARK: - Practice Plan

struct PracticePlan: Codable {
    let generatedAt: Date
    let weekOf: Date
    let focus: [PracticeFocus]
    let source: RoutingTarget
}

struct PracticeFocus: Codable {
    let day: Int
    let area: FeedbackCategory
    let exercise: String
    let durationMinutes: Int
}

// MARK: - Errors

enum CoachError: LocalizedError {
    case studioRequired(String)
    case modelNotLoaded
    case inferenceFailure(String)
    case sessionTooShort

    var errorDescription: String? {
        switch self {
        case .studioRequired(let msg): return msg
        case .modelNotLoaded: return "AI coach is loading..."
        case .inferenceFailure(let msg): return msg
        case .sessionTooShort: return "Session too short for a summary — keep practicing!"
        }
    }
}
