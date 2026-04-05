import Foundation
import UIKit

// Wraps Cactus SDK for on-device Gemma 4 E2B inference
// and routes to Ollama for complex requests.
actor GemmaCoach {
    static let shared = GemmaCoach()

    private var model: CactusModelT?
    private var isLoaded = false
    private var prompts: [String: String] = [:]

    // MARK: - Setup

    func load() async {
        loadPrompts()
        await loadModel()
    }

    private func loadPrompts() {
        guard let url = Bundle.main.url(forResource: "coaching-prompts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            prompts = Self.defaultPrompts
            return
        }
        prompts = json
    }

    private func loadModel() async {
        guard let modelPath = cactusFindModel() else {
            print("[GemmaCoach] Model not found — on-device coaching unavailable")
            return
        }
        do {
            model = try cactusInit(modelPath, nil, false)
            isLoaded = true
            print("[GemmaCoach] Model loaded: \(modelPath)")
        } catch {
            print("[GemmaCoach] Failed to load model: \(error)")
        }
    }

    private func cactusFindModel() -> String? {
        // Check app bundle first, then Documents directory
        let modelName = "gemma-4-e2b-it"
        if let bundlePath = Bundle.main.path(forResource: modelName, ofType: nil) {
            return bundlePath
        }
        let docsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(modelName)").path
        return FileManager.default.fileExists(atPath: docsPath) ? docsPath : nil
    }

    // MARK: - Routing

    func analyze(requestType: RequestType, prompt: String, imageBase64: String? = nil) async -> (String, RoutingTarget) {
        switch requestType {
        case .realtimeFrame:
            return (await onDeviceInference(prompt: prompt, imageBase64: imageBase64), .onDevice)

        case .askCoach, .sessionSummary, .practicePlan:
            if await OllamaClient.shared.isReachable() {
                let systemPrompt = prompts[requestType.promptKey] ?? prompts["askCoach"] ?? Self.defaultPrompts["askCoach"]!
                if let result = try? await OllamaClient.shared.generate(prompt: prompt, systemPrompt: systemPrompt) {
                    return (result, .localServer)
                }
            }
            return (await onDeviceInference(prompt: prompt), .onDevice)

        case .teacherReport:
            guard await OllamaClient.shared.isReachable() else {
                return ("Connect to your home network to generate a teacher report.", .onDevice)
            }
            let systemPrompt = prompts["teacherReport"] ?? Self.defaultPrompts["teacherReport"]!
            let result = (try? await OllamaClient.shared.generate(prompt: prompt, systemPrompt: systemPrompt)) ?? "Unable to generate report."
            return (result, .localServer)
        }
    }

    // MARK: - On-Device Inference

    private func onDeviceInference(prompt: String, imageBase64: String? = nil) async -> String {
        guard isLoaded, let model = model else {
            return "AI coach is warming up — keep playing!"
        }

        let systemPrompt = prompts["realtimeCoaching"] ?? Self.defaultPrompts["realtimeCoaching"]!

        var messageContent: Any = prompt
        if let img = imageBase64 {
            messageContent = ["text": prompt, "images": [img]]
        }

        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": messageContent]
        ]

        guard let messagesData = try? JSONSerialization.data(withJSONObject: messages),
              let messagesJson = String(data: messagesData, encoding: .utf8) else {
            return "Unable to prepare coaching request."
        }

        let options = #"{"max_tokens":100,"temperature":0.6}"#

        do {
            let resultJson = try cactusComplete(model, messagesJson, options, nil, nil)
            return parseContent(from: resultJson) ?? "Keep going — you're doing great!"
        } catch {
            return "Keep going — you're doing great!"
        }
    }

    private func parseContent(from json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return json.isEmpty ? nil : json
        }
        return obj["content"] as? String
            ?? obj["response"] as? String
            ?? obj["text"] as? String
    }

    // MARK: - Default Prompts

    private static let defaultPrompts: [String: String] = [
        "realtimeCoaching": "You are a supportive violin coach watching a student practice. Give ONE short, encouraging observation about their technique. Speak directly to the student. Keep it under 15 words. Child-friendly language only.",
        "askCoach": "You are a warm, expert violin teacher helping a young student. Answer clearly and encouragingly. Keep explanations simple. The student is aged 6–14.",
        "sessionSummary": "You are a violin teacher reviewing a student's practice session data. Write a short, encouraging 2-3 sentence summary of their session. Mention the main area to focus on next time. Child-friendly language.",
        "practicePlan": "You are a violin teacher creating a 5-day practice plan for a young student based on their recent session feedback. Format as Day 1, Day 2... etc. Each day: one area to focus on, one specific exercise, and how many minutes. Keep it encouraging and achievable.",
        "teacherReport": "You are helping a violin student's parent share a practice report with the student's teacher. Write a structured, professional summary including: practice frequency, top technique issues observed, and a recommended focus area for upcoming lessons."
    ]
}

// MARK: - RequestType extension

extension RequestType {
    var promptKey: String {
        switch self {
        case .realtimeFrame: return "realtimeCoaching"
        case .askCoach: return "askCoach"
        case .sessionSummary: return "sessionSummary"
        case .practicePlan: return "practicePlan"
        case .teacherReport: return "teacherReport"
        }
    }
}
