# Maestro Gemma — AI Violin Coach powered by Gemma 4

**Submission for the [Gemma 4 Good Hackathon](https://www.kaggle.com/competitions/gemma-4-good-hackathon)**
Tracks: Main Track · Future of Education · Cactus Special Technology Prize

---

## The Problem

Private violin lessons cost $80–150/hour. Most families can't afford daily instruction, so children practice alone — with no one to catch the bad habits that become permanent. By the next lesson, the damage is done.

My son Arthur practices every day. I built Maestro Gemma so he's never truly alone.

---

## What It Does

Maestro Gemma is an iOS app that gives every child expert-level violin technique feedback during every practice session — for free, privately, on their own iPhone.

- **Multimodal AI coaching** — Gemma 4 E2B *sees* the student through the camera and receives sensor data. Every 3 seconds, it produces a personalized coaching tip based on what it actually observes.
- **Real-time posture analysis** — Apple Vision tracks body pose at 30fps. 5 heuristic checks: raised shoulder, low elbow, head tilt, collapsed wrist, body lean. Visual skeleton overlay.
- **Smoothed pitch detection** — AVFoundation detects pitch with moving-average smoothing, note hysteresis, and 5-cent snapping. Stable display that won't overwhelm a young player.
- **Body positioning guide** — Dashed outline overlay guides the student into frame. Auto-fades when body is detected.
- **Ask Coach** — Free-text questions routed to Gemma 4 27B with vision frames for deep technique analysis.
- **Session Summary** — AI-generated summary with posture and intonation scores computed from severity-weighted feedback events.
- **Practice Plan** — Structured 5-day plan with daily focus areas, exercises, and tips.
- **Teacher Report** — Professional report for the student's teacher, exported via iOS share sheet.
- **History** — Session list with streak tracking, total practice time, and per-session scores.
- **Transparent routing** — Every AI response shows which model generated it (green = E2B on-device, blue = 27B server).

---

## Architecture

```
Camera Frame (384×288 JPEG) ──┐
                               ├──► Gemma 4 E2B (on-device, Cactus SDK, Apple NPU)
Apple Vision (pose skeleton) ──┤        → real-time coaching every 3s
AVFoundation (pitch + cents) ──┘
                │
                └── Ask Coach / Summaries / Plans / Reports
                          ↓
                Gemma 4 27B (Mac Studio, Ollama, local network)
                    → deep technique analysis with vision frames
                    → practice plans, teacher reports
```

**Routing logic** (in `GemmaCoach.swift`):

| Request Type | Primary | Fallback |
|---|---|---|
| Real-time coaching | E2B on-device (always) | — |
| Ask Coach | 27B server + vision | E2B on-device |
| Session summary | 27B server | E2B on-device |
| Practice plan | 27B server | E2B on-device |
| Teacher report | 27B server (required) | Error message |

Reachability check verifies a Gemma model is loaded, not just that Ollama responds. Source badges throughout the UI show which model produced each response.

---

## Gemma 4 Integration

| Feature | Model | Input | Deployment |
|---|---|---|---|
| Real-time coaching | Gemma 4 E2B | Camera frame + sensor text | On-device, Cactus SDK, Apple NPU, INT4 |
| Ask Coach | Gemma 4 27B | Text + camera frame | Local server, Ollama |
| Session summary | Gemma 4 27B | Session metrics | Local server, Ollama |
| Practice plan | Gemma 4 27B | Issue history + scores | Local server, Ollama |
| Teacher report | Gemma 4 27B | Full session data | Local server, Ollama |

Models: `Cactus-Compute/gemma-4-E2B-it` (INT4) · `gemma4:27b` via Ollama

---

## Privacy

**Zero data leaves the device or local network.** No cloud APIs, no accounts, no recordings stored. All processing happens on-device or on the user's own local server. Fully COPPA compliant — built for children.

---

## Tech Stack

- Swift 5.10 / SwiftUI / SwiftData
- Cactus SDK v1.12 (XCFramework, built from source)
- Apple Vision Framework (body pose detection, 5 heuristic checks)
- AVFoundation (pitch detection with smoothing + hysteresis)
- Ollama (local server multimodal inference)
- Gemma 4 E2B (on-device) + 27B (local server)

---

## Project Structure

```
MaestroGemma/
  MaestroGemmaApp.swift           # App entry point, model container
  ContentView.swift                # Tab navigation (Practice, History)
  Models/
    Cactus.swift                   # Cactus SDK Swift FFI wrapper
    CoachingTypes.swift            # SwiftData models, enums, types
    GemmaCoach.swift               # Routing logic + multimodal inference
    ModelDownloader.swift          # First-launch model download from HuggingFace
    OllamaClient.swift             # Ollama REST client with vision support
    PitchDetector.swift            # AVFoundation pitch detection + smoothing
    PostureAnalyzer.swift          # Apple Vision pose analysis (5 checks)
  Views/
    PracticeView.swift             # Main practice screen + coaching loop
    AskCoachView.swift             # Free-text coach modal
    SessionSummaryView.swift       # Post-session analytics + scores
    TeacherReportView.swift        # Teacher report + share sheet
    HistoryView.swift              # Session history + streak + stats
    CameraManager.swift            # Camera + frame capture for Gemma vision
    ModelLoadingView.swift         # First-launch download progress
    BodyGuideOverlay.swift         # Body positioning guide
    PitchDisplayView.swift         # Real-time pitch display
    PostureSkeletonView.swift      # Vision skeleton overlay
    CoachingOverlayView.swift      # Coaching text + source badge
  Resources/
    coaching-prompts.json          # Age-appropriate prompt templates
```

---

## Running Locally

1. Clone this repo
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
3. Run `xcodegen generate` in the project root
4. Open `MaestroGemma.xcodeproj` in Xcode 16+
5. Select your development team in Signing & Capabilities
6. Build and run on an iPhone (iOS 17+)
7. On first launch, the app downloads ~9GB of Gemma 4 E2B weights (one time only)

**Optional — Mac Studio server:**
```bash
# On your Mac Studio (or any Mac with 32GB+ RAM)
ollama pull gemma4:27b
ollama serve
# Update the IP in OllamaClient.swift if needed
```

---

## Built for the Gemma 4 Good Hackathon

- **Main Track** — personal story, working demo, real-world impact
- **Future of Education** — democratizing expert music instruction for children
- **Cactus Special Technology Prize** — local-first iOS app with intelligent multimodal routing between on-device E2B and local server 27B
