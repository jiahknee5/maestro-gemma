# Maestro Gemma — Video Script (3 min)
Gemma 4 Good Hackathon · Future of Education · Cactus Prize

---

## 0:00–0:30 — The Problem

**[Shot: Arthur at his music stand, violin in hand, practicing alone. Room is quiet. No teacher.]**

> "My son Arthur practices violin every day. He's been playing for two years."

**[Shot: Close on Arthur's bow arm — shoulder slightly raised, tension visible.]**

> "But I'm not a violin teacher. And a private lesson costs $120 an hour. So most days, he practices alone — with no one to catch the habits that will take months to unlearn."

**[Shot: Pull back to show the empty room.]**

> "There are 30 million kids like Arthur in the US. Most of them quit within two years. Not because they don't love music — but because practicing without feedback is discouraging and slow."

---

## 0:30–1:15 — The App in Action

**[Shot: iPhone propped on music stand facing Arthur. App open — body guide overlay visible: "Position your upper body in the frame."]**

> "I built Maestro Gemma. It uses Gemma 4 to be the coach in the room."

**[Shot: Arthur steps into frame. Body guide fades. Posture skeleton appears. Green badge reads: "Gemma 4 · E2B · On-Device"]**

> "Apple Vision tracks his body pose at 30 frames per second. AVFoundation listens for his pitch with cent-level precision."

**[Shot: Arthur starts playing. Pitch display shows "A4" with green "in tune" indicator.]**

> "But here's what matters: every three seconds, the app captures a camera frame and sends it directly to Gemma 4 E2B — running on-device, on the phone's neural engine. The AI actually *sees* Arthur play."

**[Shot: Close on coaching overlay — text updates: "Try dropping your right shoulder a little." Green dot, "Gemma 4 · E2B · On-Device"]**

> "It combines what it sees with what the sensors detect — and gives him one clear tip at a time."

**[Shot: Arthur adjusts his shoulder. New coaching text: "Much better! Your bow arm looks relaxed now." Session timer shows 1:24]**

---

## 1:15–1:45 — Ask Coach + Routing

**[Shot: Arthur taps "Ask Coach" button. AskCoachView slides up.]**

> "When Arthur has a deeper question, he asks his coach directly."

**[Shot: Arthur taps "Why does my bow sound scratchy?" from the suggestions.]**

**[Shot: Blue badge appears: "Gemma 4 · 27B · Mac Studio" — detailed response streams in.]**

> "The app routes complex questions to Gemma 4 27B running on a local server in our home — a Mac Studio in the other room. The 27B model also receives the camera frame, so it can see Arthur's technique while answering."

> "Full model. Full reasoning. Still completely private — nothing leaves our house."

**[Shot: Arthur reads the response, nods, adjusts his bow hold.]**

---

## 1:45–2:15 — After Practice

**[Shot: Arthur taps Stop. SessionSummaryView appears — score rings (Posture: 78, Intonation: 85), session timer, source badge "27B".]**

> "After every session, Gemma 4 generates a summary with posture and intonation scores — computed from the severity of each coaching event during the session."

**[Shot: Practice plan on screen — Day 1: Bow Arm, Day 2: Intonation, etc. Source badge visible.]**

> "It creates a structured 5-day practice plan with specific exercises for each day."

**[Shot: "Share with Teacher" tapped. Teacher report generates. Share sheet appears.]**

> "And with one tap, his teacher Tomoko gets a professional report — so their next lesson picks up exactly where the AI left off."

---

## 2:15–2:45 — The Architecture

**[Shot: Architecture diagram on screen]**

```
Camera Frame (384×288) ──┐
                          ├──► Gemma 4 E2B (on-device, Apple NPU) ──► real-time coaching
Sensor Data (pose+pitch) ─┘
          │
          └── complex queries ──► Gemma 4 27B (Mac Studio, Ollama) ──► deep analysis
```

> "The technical heart is a two-model multimodal routing architecture."

> "Gemma 4 E2B runs on-device via the Cactus SDK — INT4 quantized, on the Apple Neural Engine. It handles real-time multimodal coaching: camera frames plus sensor data, every three seconds."

> "For deeper reasoning, the app routes to Gemma 4 27B on the local Mac Studio — also with vision frames. No cloud. No subscriptions."

**[Shot: Quick flash of routing code in GemmaCoach.swift]**

> "The routing is deterministic and transparent. Every response shows which model generated it."

---

## 2:45–3:00 — The Vision

**[Shot: Arthur playing — confident, focused. Coaching overlay updates. Skeleton overlay glowing green.]**

> "Arthur is 8 years old. He now practices with more confidence, because he knows someone is watching."

**[Shot: Wide shot — just a kid, a violin, and a phone.]**

> "Maestro Gemma costs nothing to run. It works offline. It never stores a single frame of video or second of audio."

> "Every child with a $50 violin deserves expert feedback. Gemma 4 makes that possible."

**[Shot: App icon. GitHub URL. "Future of Education · Cactus Prize"]**

> "Maestro Gemma. Open source. Built for Arthur. Built for every Arthur."

---

## Production Notes

- Film in natural light, Arthur's actual practice space
- Use iPhone mounted on music stand — NOT screen recordings. Film the phone itself.
- Show the green/blue source badges clearly — judges need to see the routing
- Keep coaching overlay legible: portrait orientation, good contrast
- The Ask Coach sequence: have Arthur pick a suggestion, hit it on camera
- Architecture diagram: clean dark slide, animated arrows showing routing
- End card: GitHub repo URL + "Future of Education · Cactus Prize"
- Total runtime target: 2:50–3:00
