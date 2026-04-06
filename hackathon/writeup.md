# Maestro Gemma — Kaggle Writeup
**Gemma 4 Good Hackathon · Future of Education Track**

---

## The Problem

Private violin lessons cost $80–150 per hour in the United States. For most families, that means one lesson per week — or less. Between lessons, students practice alone, with no one to correct the habits that, if unchecked, become permanent: a raised bow shoulder that causes tension and injury, a collapsed left wrist that kills tone, intonation drift that trains the ear in the wrong direction. By the next lesson arrives, the damage is done.

My son Arthur is eight years old and has been playing violin for two years. He practices thirty minutes a day. I am not a violin teacher, and I cannot be in the room correcting him every session. He is not alone — an estimated 30 million children study an instrument in the United States, and the majority quit within two years. The research consistently points to a single cause: without feedback, progress stalls, frustration grows, and children give up.

Maestro Gemma is my answer to this problem. It is an iOS application that puts a Gemma 4 AI coach in the room for every practice session — watching, listening, and coaching in real time — completely on-device, completely private, completely free.

---

## The Solution

Maestro Gemma uses Gemma 4 as the core intelligence layer, combining multimodal AI with iOS sensor frameworks. Three systems work in parallel during every practice session.

**Vision Layer:** The iPhone's front camera feeds frames to two systems simultaneously. Apple Vision runs `VNDetectHumanBodyPoseRequest` at 30fps, extracting joint positions for five heuristic posture checks: raised bow shoulder, low bow elbow, head tilted away from chin rest, collapsed left wrist, and body leaning. In parallel, every 3 seconds a camera frame is captured, resized to 384×288, and sent directly to Gemma 4 E2B as a base64 image — so the model can *see* the student and assess technique beyond what geometric rules can detect.

**Audio Layer:** AVFoundation processes microphone input through a smoothed autocorrelation pitch detector. A 5-sample moving average eliminates frame-to-frame jitter, and note hysteresis requires 3 consecutive stable readings before switching the display. Cents are snapped to the nearest 5 to reduce visual noise. The result: a stable, child-friendly pitch display that shows when you're in tune without overwhelming a young player.

**Gemma 4 Coaching Layer:** Every 3 seconds, the app assembles a multimodal prompt — the camera frame, detected posture issues, and pitch data — and calls Gemma 4 E2B via the Cactus SDK. The model runs fully on-device, INT4 quantized, on the Apple Neural Engine. It receives both the image and sensor telemetry, producing a single coaching observation: *"Try dropping your right shoulder a little"* or *"Your bow arm looks relaxed — great job!"*

This architecture means Gemma 4 is not just rephrasing sensor data — it is looking at the student and interpreting what it sees alongside the sensor readings. The output is natural language, age-appropriate, and encouraging.

---

## Intelligent Routing — The Cactus Architecture

The technical innovation in Maestro Gemma is the two-tier routing layer between Gemma 4 models of different sizes.

**On-device (E2B):** Gemma 4 E2B via Cactus SDK handles all real-time coaching with multimodal input (camera frames + sensor text). The Cactus SDK provides the XCFramework with Apple NPU support, and INT4 quantized weights from `Cactus-Compute/gemma-4-E2B-it` load directly on-device. The UI shows a green "Gemma 4 · E2B · On-Device" badge so the user always knows which model is active.

**Local server (27B):** For tasks requiring deeper reasoning — free-text questions, session summaries, practice plans, and teacher reports — the app routes to Gemma 4 27B via Ollama on a local Mac Studio. When available, vision frames are also sent to the 27B model for higher-quality technique assessment. A blue "Gemma 4 · 27B · Mac Studio" badge indicates server-side inference. No cloud. No subscription. No data ever leaves the home network.

The routing decision is deterministic:
- Real-time coaching → always on-device E2B (latency-critical)
- Ask Coach, summaries, plans → 27B if reachable, fallback to E2B
- Teacher reports → 27B only (quality-critical)

The reachability check verifies not just that Ollama responds, but that a Gemma model is actually loaded. Every AI-generated response throughout the app shows a source badge indicating which model produced it.

---

## Features

**Practice Screen:** Live camera feed with Apple Vision posture skeleton overlay. Body positioning guide that fades when the student is detected. Pitch display with smoothed note detection and cents bar. Session timer. Gemma 4 coaching overlay with model source indicator, updating every 3 seconds with multimodal input.

**Ask Coach:** Modal where the student can ask any violin technique question. Pre-populated suggestions for common beginner questions. Routes to 27B with vision capability when available, with clear source labeling.

**Session Summary:** Score rings for posture and intonation computed from severity-weighted feedback events (encouragement, suggestion, correction). AI-generated summary with source badge. Top issues by frequency. "Generate Practice Plan" button.

**Practice Plan:** AI-generated structured 5-day plan with daily focus areas, specific exercises, durations, and tips.

**Teacher Report:** Professional structured report for the student's teacher — session overview, technique observations, intonation analysis, recommendations, engagement indicators. Shared via iOS share sheet.

**History:** Session list with streak tracking, total practice time, session count, and per-session posture/intonation mini-scores.

---

## Privacy and Safety

Every design decision prioritizes privacy and safety for its primary user: a child.

- **No video or audio is ever recorded or stored.** Camera and microphone are processed in memory only and discarded.
- **No data leaves the device or local network.** No cloud APIs, no external calls. The Ollama server runs on hardware the family owns.
- **No account required.** No login, no profile, no analytics, no telemetry.
- **COPPA compliant by design.** The absence of data collection is the compliance strategy.
- **Child-appropriate language throughout.** All prompts enforce encouraging, simple, age-appropriate responses.

---

## Impact

The equity argument is direct: expert violin instruction is expensive and geographically concentrated. A child in rural Appalachia with a $50 violin and no local teachers has no access to the feedback that builds good habits. Maestro Gemma removes that barrier.

The technology works because Gemma 4's multimodal understanding — actually seeing the student through the camera, not just receiving preprocessed sensor data — produces coaching that is genuinely useful. The on-device deployment means it works anywhere, with no internet, on hardware every student already carries.

Arthur now practices with more focus. He knows someone is watching.

---

## Technical Details

- **Platform:** iOS 17+, Swift 5.10, SwiftUI, SwiftData
- **On-device model:** Gemma 4 E2B, INT4, Apple NPU via Cactus SDK v1.12
- **Model weights:** `Cactus-Compute/gemma-4-E2B-it` (HuggingFace)
- **Local server model:** Gemma 4 27B via Ollama 0.20.2
- **Vision:** Apple Vision body pose (5 heuristic checks) + Gemma 4 multimodal vision (direct frame analysis)
- **Audio:** AVFoundation + smoothed autocorrelation pitch detection with hysteresis
- **Storage:** SwiftData (local device only)
- **Routing:** Deterministic, model-verified, with source badges throughout UI
- **XCFramework:** Built from source at `github.com/cactus-compute/cactus`

---

## Tracks Entered

- **Main Track** — personal story, working demo, real-world impact
- **Future of Education** — democratizing expert music instruction for children
- **Cactus Special Technology Prize** — local-first iOS app with intelligent multimodal routing between on-device E2B and local server 27B
