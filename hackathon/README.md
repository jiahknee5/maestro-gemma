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

- **Real-time posture analysis** — Apple Vision tracks body pose at 30fps. Raised bow shoulder, low elbow, collapsed wrist — caught immediately.
- **Live pitch detection** — AVFoundation detects pitch with cent-level precision. Note name and intonation shown in real time.
- **Gemma 4 coaching overlay** — Gemma 4 E2B runs on-device via Cactus SDK (Apple NPU, INT4). Natural language coaching updates every 2 seconds: *"Try relaxing your bow shoulder a little."*
- **Ask Coach** — Free-text questions routed to Gemma 4 26B on a local server. *"Why does my bow sound scratchy?"* gets a full explanation.
- **Session Summary** — AI-generated summary of each practice session with score rings and top issues.
- **Practice Plan** — 5-day AI-generated practice plan based on session history.
- **Teacher Report** — Structured summary for the student's teacher, exported via iOS share sheet.

---

## Architecture

```
iPhone (on-device)
├── Apple Vision        → body pose skeleton, 30fps
├── AVFoundation        → pitch detection, cents precision
└── Gemma 4 E2B         → real-time coaching text (Cactus SDK, Apple NPU)
         │
         └── complex queries (Ask Coach, summaries, plans)
                   ↓
         Mac Studio (local network)
         └── Gemma 4 26B via Ollama
               → deep technique explanations
               → practice plans + teacher reports
```

**Routing logic** (in `GemmaCoach.swift`): Real-time frame analysis always uses on-device E2B for low latency. Ask Coach, session summaries, and teacher reports route to Gemma 4 26B on the local server when reachable. Full offline mode falls back to on-device for all features except teacher reports.

This architecture is purpose-built for the **Cactus prize** — a local-first mobile app that intelligently routes tasks between a small edge model and a larger local server model.

---

## Gemma 4 Integration

| Feature | Model | Deployment |
|---|---|---|
| Real-time coaching overlay | Gemma 4 E2B | On-device, Cactus SDK, Apple NPU, INT4 |
| Ask Coach | Gemma 4 26B | Local server, Ollama |
| Session summary | Gemma 4 26B | Local server, Ollama |
| Practice plan | Gemma 4 26B | Local server, Ollama |
| Teacher report | Gemma 4 26B | Local server, Ollama |

Models: `Cactus-Compute/gemma-4-E2B-it` (INT4) · `gemma4:26b` via Ollama

---

## Privacy

**Zero data leaves the device or local network.** No cloud APIs, no accounts, no recordings stored. All processing happens on-device or on the user's own local server. Fully COPPA compliant — built for children.

---

## Tech Stack

- Swift 5.10 / SwiftUI / SwiftData
- Cactus SDK v1.12 (XCFramework, built from source)
- Apple Vision Framework (body pose)
- AVFoundation (pitch detection via autocorrelation)
- Ollama (local server inference)
- Gemma 4 E2B + 26B

---

## Project Structure

```
MaestroGemma/
  Models/
    CoachingTypes.swift     # SwiftData models + shared types
    GemmaCoach.swift        # Cactus inference + routing logic
    OllamaClient.swift      # Ollama REST client
    PitchDetector.swift     # AVFoundation pitch detection
    PostureAnalyzer.swift   # Apple Vision body pose analysis
  Views/
    PracticeView.swift      # Main practice screen
    AskCoachView.swift      # Ask Coach modal
    SessionSummaryView.swift
    TeacherReportView.swift
    HistoryView.swift
  Resources/
    coaching-prompts.json   # Age-appropriate prompt templates
```

---

## Built for the Gemma 4 Good Hackathon

This project targets three prize tracks:
- **Main Track** — compelling real-world problem with personal story and working demo
- **Future of Education** — democratizing expert music instruction for children who can't afford it
- **Cactus** — local-first iOS app with intelligent routing between on-device E2B and local server 26B
