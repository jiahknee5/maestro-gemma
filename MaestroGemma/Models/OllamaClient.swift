import Foundation

actor OllamaClient {
    static let shared = OllamaClient()

    private let baseURL = "http://100.103.189.47:11434"
    private let model = "gemma4:26b"
    private let reachabilityTimeout: TimeInterval = 1.0
    private let generateTimeout: TimeInterval = 30.0

    private var _isReachable = false
    private var lastReachabilityCheck = Date.distantPast

    // MARK: - Reachability

    func isReachable() async -> Bool {
        // Cache reachability for 5 seconds
        if Date().timeIntervalSince(lastReachabilityCheck) < 5 {
            return _isReachable
        }
        let result = await checkReachability()
        _isReachable = result
        lastReachabilityCheck = Date()
        return result
    }

    private func checkReachability() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
        var request = URLRequest(url: url, timeoutInterval: reachabilityTimeout)
        request.httpMethod = "GET"
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
            // Verify our target model is actually loaded
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                let names = models.compactMap { $0["name"] as? String }
                let hasModel = names.contains { $0.hasPrefix("gemma") }
                if !hasModel {
                    print("[OllamaClient] Ollama reachable but no Gemma model found. Available: \(names)")
                }
                return hasModel
            }
            return true
        } catch {
            return false
        }
    }

    // MARK: - Generate (text only)

    func generate(prompt: String, systemPrompt: String, maxTokens: Int = 500) async throws -> String {
        return try await generate(prompt: prompt, systemPrompt: systemPrompt, imageBase64: nil, maxTokens: maxTokens)
    }

    // MARK: - Generate (with optional vision)

    func generate(prompt: String, systemPrompt: String, imageBase64: String?, maxTokens: Int = 500) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw CoachError.inferenceFailure("Invalid Ollama URL")
        }

        let fullPrompt = systemPrompt.isEmpty ? prompt : "\(systemPrompt)\n\n\(prompt)"

        var body: [String: Any] = [
            "model": model,
            "prompt": fullPrompt,
            "stream": false,
            "options": ["temperature": 0.7, "num_predict": maxTokens]
        ]

        // Attach image for multimodal analysis if provided
        if let img = imageBase64 {
            body["images"] = [img]
        }

        var request = URLRequest(url: url, timeoutInterval: generateTimeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw CoachError.inferenceFailure("Ollama returned error status")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["response"] as? String else {
            throw CoachError.inferenceFailure("Unexpected Ollama response format")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
