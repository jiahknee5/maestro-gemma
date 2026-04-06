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
        guard let modelPath = await ModelDownloader.shared.modelPath() else {
            print("[GemmaCoach] Model not ready — on-device coaching unavailable")
            return
        }
        do {
            let loaded = try await Task.detached {
                try cactusInit(modelPath, nil, false)
            }.value
            model = loaded
            isLoaded = true
            print("[GemmaCoach] Model loaded from: \(modelPath)")
        } catch {
            print("[GemmaCoach] Failed to load model: \(error)")
        }
    }

    // MARK: - Routing

    func analyze(requestType: RequestType, prompt: String, imageBase64: String? = nil) async -> (String, RoutingTarget) {
        switch requestType {
        case .realtimeFrame:
            return (await onDeviceInference(prompt: prompt, imageBase64: imageBase64), .onDevice)

        case .askCoach, .sessionSummary, .practicePlan:
            if await OllamaClient.shared.isReachable() {
                let systemPrompt = prompts[requestType.promptKey] ?? prompts["askCoach"] ?? Self.defaultPrompts["askCoach"]!
                if let result = try? await OllamaClient.shared.generate(prompt: prompt, systemPrompt: systemPrompt, imageBase64: imageBase64) {
                    return (result, .localServer)
                }
            }
            return (await onDeviceInference(prompt: prompt, imageBase64: imageBase64), .onDevice)

        case .teacherReport:
            guard await OllamaClient.shared.isReachable() else {
                return ("Connect to your home network to generate a teacher report.", .onDevice)
            }
            let systemPrompt = prompts["teacherReport"] ?? Self.defaultPrompts["teacherReport"]!
            let result = (try? await OllamaClient.shared.generate(prompt: prompt, systemPrompt: systemPrompt, imageBase64: imageBase64)) ?? "Unable to generate report."
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
            let resultJson = try await Task.detached {
                try cactusComplete(model, messagesJson, options, nil, nil)
            }.value
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
        "realtimeCoaching": """
        You are Maestro, a warm and supportive AI violin coach for a young student (age 6–14). You can SEE the student through their camera and HEAR their instrument through their microphone.

        When an image is provided, look at the student's actual posture and technique:
        - Violin hold: Is the violin resting properly on the shoulder/chin rest?
        - Bow arm: Is the right arm relaxed? Elbow at the right height? Wrist flexible?
        - Left hand: Is the wrist straight (not collapsed)? Are fingers curved?
        - Posture: Is the student standing tall? Shoulders relaxed and level?
        - Head position: Tilted gently toward the chin rest?

        You will also receive sensor data about pitch detection and posture landmarks. Use BOTH the image and the sensor data together.

        Rules:
        - Give exactly ONE short tip per response (under 15 words)
        - Speak directly to the student ("Try relaxing your shoulder" not "The student should...")
        - Be encouraging — always acknowledge what's going well before correcting
        - Use simple, child-friendly language
        - If everything looks good, offer positive reinforcement
        """,
        "askCoach": """
        You are Maestro, a warm and expert violin teacher helping a young student (age 6–14). Answer clearly and encouragingly.
        - Use simple analogies kids can understand
        - Give practical, actionable advice
        - Keep answers to 2-3 short paragraphs maximum
        - If you mention technique, describe how it should feel, not just look
        """,
        "sessionSummary": """
        You are Maestro reviewing a practice session. Write an encouraging 2-3 sentence summary.
        - Start with something positive about the session
        - Mention the #1 area to focus on next time
        - End with motivation to keep practicing
        - Use child-friendly language — the student reads this directly
        """,
        "practicePlan": """
        You are Maestro creating a 5-day practice plan for a young violin student.
        Format each day as:
        **Day N: [Focus Area]**
        - Exercise: [specific exercise]
        - Duration: [minutes]
        - Tip: [one practical tip]

        Keep exercises achievable and fun. Build in difficulty gradually across the week. Include at least one "reward day" with a favorite piece.
        """,
        "teacherReport": """
        You are helping generate a structured practice report for a violin teacher. Be professional but warm.
        Include:
        1. **Session Overview** — date, duration, AI coaching events
        2. **Technique Observations** — posture issues detected and frequency
        3. **Intonation** — any recurring pitch issues
        4. **Recommendation** — suggested focus for the next lesson
        5. **Student Engagement** — overall practice quality indicators
        Keep the tone collaborative — you are assisting the teacher, not replacing them.
        """
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
