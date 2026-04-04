# Blueprint: Maestro Gemma — Violin Coach powered by Gemma 4
Version: 1
Locked: [lock after Gate 0 approval]. Do not modify after locking. Use Change Log only.

---

## Objective

Maestro Gemma is a standalone iOS violin practice coach built for the Gemma 4 Good Hackathon. It is a fresh app — separate from MaestroAI v1 — built around Gemma 4 as the core intelligence: real-time multimodal coaching on-device, with deeper technique analysis routed to a local Gemma 4 26B server. Built for Johnny's son Arthur, who practices violin daily without a teacher present. The personal story is real and drives the video pitch.

"Done" means: working iOS app with Gemma 4 coaching layer that is demo-ready, and Kaggle submission filed before May 18, 2026.

---

## Prize Strategy

| Prize | Track | Amount | How we win |
|---|---|---|---|
| Main Track (3rd or 4th) | Main | $10–15K | Personal story + working demo |
| Future of Education | Impact | $10K | Music access inequality framing |
| Cactus | Special Tech | $10K | Intelligent on-device routing architecture |
| **Total target** | | **$30–35K** | |

Judging rubric:
- Impact & Vision: 40pts (video-demonstrated, real-world problem)
- Video Pitch & Storytelling: 30pts (3-min YouTube, "most important part")
- Technical Depth: 30pts (innovative Gemma 4 use, real + functional)

---

## Stack (locked)

Platform: iOS 17+ (SwiftUI), requires iOS 13.0+ minimum
Language: Swift 5.10 (Swift 5.7+ required by Cactus)
On-device model: Gemma 4 E2B via Cactus SDK (INT4, Apple NPU) — weights at huggingface.co/Cactus-Compute/gemma-4-E2B-it
Local server model: Gemma 4 26B via Ollama REST API at http://192.168.0.201:11434
Routing: Cactus built-in `cloud_handoff` confidence scoring — automatic per-token routing signal
  (Note: no SPM package exists — must build XCFramework from source: github.com/cactus-compute/cactus)
Vision: Apple Vision Framework (body pose overlay, 30fps)
Audio: AVFoundation (pitch detection, cents precision)
Storage: SwiftData (local session history)
No accounts, no cloud APIs, no recordings stored — fully private, COPPA compliant

---

## Architecture

```
iPhone (on-device)
├── Apple Vision              → body pose skeleton overlay, 30fps
├── AVFoundation              → real-time pitch display (note + cents)
└── Cactus SDK (Gemma 4 E2B) → natural language coaching overlay
      INT4, Apple NPU, ~1s per frame
      "Your bow arm looks tense — try relaxing your elbow"
      Response includes: { "cloud_handoff": bool, "confidence": float }
              │
              └── cloud_handoff: true (low confidence)
                        ↓
              Mac Studio 192.168.0.201:11434
              └── Gemma 4 26B via Ollama
                    → deeper technique explanation
                    → "Ask Coach" free-text answers
                    → end-of-session AI summary
                    → weekly practice plan
                    → teacher report for Tomoko
```

Routing mechanism (Cactus built-in):
- Every `cactusComplete()` response includes `cloud_handoff` (bool) + `confidence` (float)
- Real-time frame: if cloud_handoff=false → show response; if true → escalate to Ollama 26B
- "Ask Coach" queries: always send to 26B if reachable (complex reasoning required)
- Offline (Studio unreachable) → use on-device response regardless of cloud_handoff flag

---

## Screens

1. **Practice** — Camera + posture skeleton + live pitch + Gemma 4 coaching text + "Ask Coach" button
2. **Session Summary** — Score breakdown, AI summary, top issues, "Generate Practice Plan"
3. **Practice Plan** — AI-generated 5-day plan from session history
4. **Teacher Report** — Structured summary for Tomoko, sharable via iOS share sheet
5. **History** — Calendar grid, past sessions, streaks

---

## Subtask Breakdown

**Subtask 0 — Infra (sealed foundation, complete first)**
- Build Cactus XCFramework from source (`git clone github.com/cactus-compute/cactus && source ./setup && cactus build --apple`)
- Download Gemma 4 E2B INT4 weights via `cactus download gemma-4-E2B-it`
- Embed XCFramework + copy `apple/Cactus.swift` into Xcode project
- Xcode project scaffold (SwiftUI, SwiftData schema, tab navigation)
- Ollama REST client (connect to 192.168.0.201:11434, health check, offline detection)
- `cloud_handoff` routing layer: read flag from cactusComplete() → escalate to Ollama if needed
- Shared types: CoachingFeedback, RoutingDecision, PracticePlan, TeacherReport
- Camera + mic permissions, AVCapture session setup
- Apple Vision body pose pipeline

**Subtask 1 — Practice Screen**
- Camera feed with body pose skeleton overlay
- Live pitch display (note name + cents bar)
- Gemma 4 E2B coaching text overlay (updates ~1s)
- "Ask Coach" button → AskCoachView modal
- Start/stop session controls

**Subtask 2 — Ask Coach + Deep Analysis**
- AskCoachView: free-text input + suggested questions
- Routes to Gemma 4 26B via Ollama
- Displays response with source indicator (on-device vs. Studio)
- Offline graceful degradation

**Subtask 3 — Session Intelligence**
- Log CoachingFeedback events with timestamps during session
- End-of-session: route to 26B → AI natural language summary
- SessionSummaryView: score rings + AI summary + top issues
- "Generate Practice Plan" → PracticePlanView (5-day AI plan)

**Subtask 4 — Teacher Report**
- TeacherReportView: issues by frequency, progress trend, recommended focus
- Export via iOS share sheet (PDF or text)
- "Share with Teacher" button in session summary

**Subtask 5 — Hackathon Submission**
- Public GitHub repo: clean README, architecture diagram, Gemma 4 usage documented
- Kaggle writeup: 1,500 words, Future of Education track
- YouTube video script: 3 min, Arthur in demo, Johnny narrates
- Live demo: TestFlight link or screen recording fallback

---

## Performance Budget

On-device E2B inference: < 500ms per frame (iPhone 15+, LiteRT)
Ollama round-trip: < 3s (local network, Gemma 4 26B)
App launch to camera live: < 2s
30-min practice session battery drain: < 15%

---

## Constraints

- All data on-device or local network only. No external API calls.
- Routing to Mac Studio only when on local network (192.168.0.201 reachable).
- All Gemma 4 prompts tuned for children aged 6–14: encouraging, simple, one correction at a time.
- Public repo must clearly show Gemma 4 integration — judges verify via code.
- Video must feature Arthur playing (real use case, not stock footage).
- Do not touch or reference MaestroAI v1.

---

## External Dependencies

Must be confirmed before Gate 2:
- [x] Cactus iOS SDK confirmed: github.com/cactus-compute/cactus v1.12 — XCFramework build required (no SPM)
- [x] Gemma 4 E2B weights confirmed: huggingface.co/Cactus-Compute/gemma-4-E2B-it (INT4, Apple NPU, uploaded 2026-04-04)
- [x] Cactus XCFramework built — `cactus-sdk/apple/cactus-ios.xcframework` on M5 Max
- [x] Ollama gemma4:26b pulled on Mac Studio (Tailscale: 100.103.189.47:11434, Ollama 0.20.2)
- [x] Apple Developer account active
- [x] Kaggle account registered
- [ ] YouTube channel confirmed for video upload (needed by Subtask 5 only)

---

## File Structure

```
maestro-gemma/
  MaestroGemma/               ← Xcode project (new, standalone)
    Models/
      GemmaCoach.swift        # LiteRT model wrapper + inference
      OllamaClient.swift      # Ollama REST client
      CactusRouter.swift      # Routing decision logic
      CoachingTypes.swift     # All shared Swift types
    Views/
      PracticeView.swift
      AskCoachView.swift
      SessionSummaryView.swift
      PracticePlanView.swift
      TeacherReportView.swift
      HistoryView.swift
    Resources/
      coaching-prompts.json   # Age-appropriate prompt templates
  memory/
    PROJECT.md                # Agent memory log (append-only)
  .claude/
    BLUEPRINT.md              # This file
    STATE.md                  # Pipeline state
    CONTRACTS.md              # Swift type + API contracts
  hackathon/
    writeup.md                # Kaggle writeup draft
    video-script.md           # YouTube video script
    README.md                 # Public GitHub README
```

---

## Naming Conventions

Files: PascalCase (Swift), kebab-case (JSON/markdown)
Types/Structs/Enums: PascalCase
Functions/variables: camelCase
SwiftData models: PascalCase, singular (Session, FeedbackEvent)

---

## Hackathon Video Outline (3 min)

0:00–0:30 — The problem. Arthur practicing alone. "No teacher can be there every day."
0:30–1:00 — App in action. Camera on Arthur. Coaching overlay updates live.
1:00–1:30 — Ask Coach. Arthur asks "why does my bow sound scratchy?" — 26B answers.
1:30–2:00 — Session summary + practice plan. "This week, focus on bow pressure."
2:00–2:30 — Architecture. Cactus routing diagram. E2B on-device → 26B on Studio.
2:30–3:00 — Vision. Every child with a $50 violin deserves expert feedback.

---

## Out of Scope

- MaestroAI v1 (do not touch)
- Multi-instrument support (violin only)
- Cloud sync, subscriptions, in-app purchase
- Android
- Fine-tuning Gemma 4

---

## Domain Compliance

[x] Children's app — zero data collection, COPPA clear, 4+ rating target
[x] Accessibility — VoiceOver labels on all interactive elements
[ ] Healthcare / Payments / GDPR — N/A

---

## Change Log
<!-- APPEND ONLY after Gate 2. -->
