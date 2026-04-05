# Maestro Gemma — Kaggle Writeup
**Gemma 4 Good Hackathon · Future of Education Track**
Target word count: 1,400–1,500

---

## The Problem

Private violin lessons cost $80–150 per hour in the United States. For most families, that means one lesson per week — or less. Between lessons, students practice alone, with no one to correct the habits that, if unchecked, become permanent: a raised bow shoulder that causes tension and injury, a collapsed left wrist that kills tone, intonation drift that trains the ear in the wrong direction. By the time the next lesson arrives, the damage is done.

My son Arthur is eight years old and has been playing violin for two years. He practices thirty minutes a day. I am not a violin teacher, and I cannot be in the room correcting him every session. He is not alone in this situation — an estimated 30 million children study an instrument in the United States, and the majority quit within two years. The research consistently points to a single cause: without feedback, progress stalls, frustration grows, and children give up.

Maestro Gemma is my answer to this problem. It is an iOS application that puts a Gemma 4 AI coach in the room for every practice session — watching, listening, and coaching in real time — completely on-device, completely private, completely free.

---

## The Solution

Maestro Gemma uses Gemma 4 as the core intelligence layer on top of existing iOS frameworks. The architecture has three distinct components working in parallel during a practice session.

**Vision Layer (Apple Vision):** The iPhone's front camera feeds a continuous stream of frames to Apple's Vision framework, which runs a `VNDetectHumanBodyPoseRequest` at 30fps. The app extracts joint positions for shoulders, elbows, and wrists and runs lightweight heuristic checks for the most common beginner issues — raised bow shoulder, low bow elbow — that can be detected from body geometry alone.

**Audio Layer (AVFoundation):** An AVAudioEngine tap processes microphone input in real time, running an autocorrelation-based pitch detection algorithm on each 4096-sample buffer. The detected frequency is converted to note name and cents deviation, displayed live as the student plays.

**Gemma 4 Coaching Layer (Cactus SDK):** Every two seconds during an active session, the app assembles a prompt from the Vision and Audio observations — detected posture issues, intonation data, session context — and calls Gemma 4 E2B via the Cactus SDK. The model runs fully on-device, INT4 quantized, on the iPhone's Apple Neural Engine. The response is a single, child-appropriate coaching observation: *"Try dropping your right shoulder a little."* or *"Your bow arm looks relaxed — great job!"*

This three-layer approach means that Gemma 4 is not replacing the existing sensors — it is interpreting them. The output is natural language, age-appropriate, and encouraging. Apple Vision provides the geometry; Gemma 4 provides the meaning.

---

## Intelligent Routing — The Cactus Architecture

The real technical innovation in Maestro Gemma is the routing layer between two Gemma 4 models.

**On-device (E2B):** Gemma 4 E2B via Cactus SDK handles all real-time coaching. The Cactus SDK builds the XCFramework from source with Apple NPU support, and the INT4 quantized weights from `Cactus-Compute/gemma-4-E2B-it` load directly into the app. Inference runs in under 500ms per frame on an iPhone 15, entirely offline.

**Local server (26B):** For tasks requiring deeper reasoning — free-text questions from the student, end-of-session summaries, weekly practice plans, and teacher reports — the app routes to Gemma 4 26B running via Ollama on a local Mac Studio connected via Tailscale. This is the same home network the iPhone is on. No cloud. No subscription. No data ever leaves the home network.

The routing logic in `GemmaCoach.swift` is explicit and simple:

```swift
switch requestType {
case .realtimeFrame:
    return await cactusInference(prompt)          // always on-device

case .askCoach, .sessionSummary, .practicePlan:
    if await ollamaClient.isReachable() {
        return await ollamaClient.generate(prompt) // route to 26B
    }
    return await cactusInference(prompt)           // fallback on-device

case .teacherReport:
    guard await ollamaClient.isReachable() else {
        throw CoachError.studioRequired("Connect to home network")
    }
    return await ollamaClient.generate(prompt)     // 26B only
}
```

This architecture directly targets the **Cactus Special Technology Prize** — a local-first mobile application that intelligently routes tasks between models based on task complexity and latency requirements. Small model for speed; large model for depth. The routing decision is deterministic, transparent, and documented in the code.

---

## Features

**Practice Screen:** Live camera feed with Apple Vision posture skeleton overlay. Pitch display with note name and cents deviation. Gemma 4 coaching text overlay updating every 2 seconds. "Ask Coach" button for free-text questions.

**Ask Coach:** A modal where the student can ask any violin technique question. Pre-populated with common beginner questions (*"Why does my bow sound scratchy?"*). Routes to Gemma 4 26B with a source indicator showing whether the response came from on-device or the local server.

**Session Summary:** After each practice session, Gemma 4 26B generates a natural language summary with score rings for posture and intonation, the top technique issues by frequency, and a "Generate Practice Plan" button.

**Practice Plan:** AI-generated 5-day practice plan based on session history, structured as specific daily exercises with durations.

**Teacher Report:** Structured summary for the student's teacher — issues by frequency, progress trend, recommended focus — exported via iOS share sheet. Requires the local server for full-quality output.

**History:** Session calendar with streak tracking.

---

## Privacy and Safety

Every design decision in Maestro Gemma prioritizes privacy and safety for its primary user: a child.

- **No video or audio is ever recorded or stored.** The camera and microphone are processed in memory only, in real time, and discarded.
- **No data leaves the device or local network.** There are no external API calls. The Ollama server runs on hardware the family owns.
- **No account required.** No login, no profile, no analytics.
- **COPPA compliant by design.** The absence of data collection is the compliance strategy.
- **Child-appropriate language throughout.** All Gemma 4 prompts include: *"Speak encouragingly. Give one clear observation at a time. Never be harsh."*

---

## Impact

The equity argument for Maestro Gemma is direct: expert violin instruction is expensive and geographically concentrated. A child in rural Appalachia with a $50 violin and no local teachers has no access to the feedback that builds good habits. Maestro Gemma removes that barrier.

The technology works because Gemma 4's multimodal understanding, combined with Apple Vision's body pose detection and AVFoundation's pitch analysis, produces coaching that is genuinely useful — not generic. The on-device deployment means it works anywhere, with no internet, on hardware every student already carries.

Arthur now practices with more focus. He knows someone is watching.

---

## Technical Details

- **Platform:** iOS 17+, Swift 5.10, SwiftUI, SwiftData
- **On-device model:** Gemma 4 E2B, INT4, Apple NPU via Cactus SDK v1.12
- **Model weights:** `Cactus-Compute/gemma-4-E2B-it` (HuggingFace)
- **Local server model:** Gemma 4 26B via Ollama 0.20.2
- **Vision:** Apple Vision `VNDetectHumanBodyPoseRequest`
- **Audio:** AVFoundation + autocorrelation pitch detection
- **Storage:** SwiftData (local device only)
- **Routing:** Manual, deterministic, documented in `GemmaCoach.swift`
- **XCFramework:** Built from source at `github.com/cactus-compute/cactus`

---

## Tracks Entered

- **Main Track** — personal story, working demo, real-world impact
- **Future of Education** — democratizing expert music instruction for children
- **Cactus Special Technology Prize** — local-first mobile app with intelligent on-device/server routing
