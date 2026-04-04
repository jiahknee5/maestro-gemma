# Contracts
Sealed at Gate 2. No agent may modify this file after Gate 2 approval.

---

## Cactus SDK — Actual API (from apple/README.md)

```swift
// Lifecycle
func cactusInit(_ modelPath: String, _ corpusDir: String?, _ cacheIndex: Bool) throws -> CactusModelT
func cactusDestroy(_ model: CactusModelT)
func cactusReset(_ model: CactusModelT)
func cactusStop(_ model: CactusModelT)

// Text + vision completion (add "images": ["path"] to message for vision)
func cactusComplete(
    _ model: CactusModelT,
    _ messagesJson: String,       // OpenAI-format messages JSON string
    _ optionsJson: String?,        // e.g. {"max_tokens": 200, "temperature": 0.7}
    _ toolsJson: String?,
    _ callback: ((String, UInt32) -> Void)?   // streaming token callback
) throws -> String                 // returns response JSON

// Audio transcription (16kHz mono PCM)
func cactusTranscribe(
    _ model: CactusModelT,
    _ audioPath: String?,
    _ prompt: String?,
    _ optionsJson: String?,
    _ callback: ((String, UInt32) -> Void)?,
    _ pcmData: Data?
) throws -> String

// Streaming transcription
func cactusStreamTranscribeStart(_ model: CactusModelT, _ optionsJson: String?) throws -> CactusStreamTranscribeT
func cactusStreamTranscribeProcess(_ stream: CactusStreamTranscribeT, _ pcmData: Data) throws -> String
func cactusStreamTranscribeStop(_ stream: CactusStreamTranscribeT) throws -> String

// Token scoring (used for confidence-based routing)
func cactusTokenize(_ model: CactusModelT, _ text: String) throws -> [UInt32]
func cactusScoreWindow(_ model: CactusModelT, _ tokens: [UInt32], _ start: Int, _ end: Int, _ context: Int) throws -> String
```

**Vision usage** — add `"images"` key to message content:
```swift
let messages = #"[{"role":"user","content":"Analyze this image","images":["path/to/frame.jpg"]}]"#
```

**NOTE:** The `cloud_handoff` flag mentioned in early research does NOT exist in the actual SDK.
Routing between on-device and Ollama is implemented manually in `GemmaCoach.swift`.

---

## Routing Strategy (manual — no built-in signal)

```swift
// GemmaCoach.swift routing logic

enum RequestType {
    case realtimeFrame      // → always on-device (latency)
    case askCoach           // → Ollama if reachable, else on-device
    case sessionSummary     // → Ollama if reachable, else on-device
    case practicePlan       // → Ollama if reachable, else defer
    case teacherReport      // → Ollama only, error if unreachable
}

// Routing decision:
switch requestType {
case .realtimeFrame:
    return await cactusInference(frame)           // always on-device

case .askCoach, .sessionSummary, .practicePlan:
    if await ollamaClient.isReachable() {
        return await ollamaClient.generate(prompt)
    }
    return await cactusInference(prompt)          // fallback

case .teacherReport:
    guard await ollamaClient.isReachable() else {
        throw CoachError.studioRequired("Connect to home network to generate teacher report")
    }
    return await ollamaClient.generate(prompt)
}
```

---

## Core Swift Types

```swift
// CoachingTypes.swift — ALL shared types live here

enum RoutingTarget: String, Codable {
    case onDevice       // Gemma 4 E2B via Cactus SDK
    case localServer    // Gemma 4 26B via Ollama
}

struct CoachingFeedback: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let category: FeedbackCategory
    let message: String         // Child-appropriate natural language
    let severity: Severity
    let source: RoutingTarget
}

enum FeedbackCategory: String, Codable {
    case posture, bowArm, leftHand, intonation, tone, general
}

enum Severity: String, Codable {
    case encouragement  // "Great job keeping your bow straight!"
    case suggestion     // "Try relaxing your bow shoulder a little"
    case correction     // "Your left wrist is collapsing — lift it up"
}

struct PracticePlan: Codable {
    let generatedAt: Date
    let weekOf: Date
    let focus: [PracticeFocus]
    let source: RoutingTarget
}

struct PracticeFocus: Codable {
    let day: Int            // 1–5
    let area: FeedbackCategory
    let exercise: String
    let durationMinutes: Int
}

struct TeacherReport: Codable {
    let sessionDate: Date
    let duration: TimeInterval
    let topIssues: [IssueFrequency]
    let progressNotes: String
    let recommendedFocus: String
}

struct IssueFrequency: Codable {
    let category: FeedbackCategory
    let count: Int
    let exampleFeedback: String
}

enum CoachError: Error {
    case studioRequired(String)
    case modelNotLoaded
    case inferenceFailure(String)
}
```

---

## Ollama API Contract

Base URL: `http://mac-studio.local:11434` (or Tailscale: `http://100.103.189.47:11434`)
Model: `gemma4:26b`

### GET /api/tags (health check)
Response 200: `{ "models": [...] }` — if unreachable within 1s, mark Studio offline

### POST /api/generate
```json
{
  "model": "gemma4:26b",
  "prompt": "string",
  "stream": false,
  "options": { "temperature": 0.7, "num_predict": 500 }
}
```
Response: `{ "response": "string", "done": true }`

---

## Prompt Templates Contract

All prompts in `Resources/coaching-prompts.json`.

Keys:
- `realtimeCoaching` — system prompt for E2B frame analysis (≤150 tokens — keep fast)
- `askCoach` — system prompt for 26B free-text queries
- `sessionSummary` — end-of-session summary
- `practicePlan` — weekly plan generation
- `teacherReport` — teacher report (structured output)

Required in all prompts: `"You are a supportive violin coach for a child aged 6–14. Give one clear, encouraging observation. Never criticize harshly."`
