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

## 0:30–1:00 — The App in Action

**[Shot: iPhone propped on music stand facing Arthur. App open, Practice tab active.]**

> "I built Maestro Gemma. It uses Gemma 4 to be the coach in the room."

**[Shot: Arthur starts playing. Camera shows posture skeleton overlay appearing on the iPhone screen.]**

> "Apple Vision tracks his body at 30 frames per second. AVFoundation listens for his pitch with cent-level precision."

**[Shot: Close on phone screen — coaching text updates: "Try dropping your right shoulder a little."]**

> "And Gemma 4 E2B runs on-device — no internet required — giving him natural language feedback every two seconds."

**[Shot: Arthur adjusts his shoulder. New coaching text: "Much better! Your bow arm looks relaxed now."]**

---

## 1:00–1:30 — Ask Coach

**[Shot: Arthur taps "Ask Coach" button. AskCoachView slides up.]**

> "When Arthur has a question his AI coach can't answer on-device, he asks it directly."

**[Shot: Arthur types — or says — "Why does my bow sound scratchy?"]**

**[Shot: Routing indicator shows "Maestro (Studio)" — response streams in from Gemma 4 26B.]**

> "The app routes complex questions to Gemma 4 26B running on a local server in our home. Full model. Full reasoning. Still completely private."

**[Shot: Arthur reads the response, nods, adjusts his bow hold.]**

---

## 1:30–2:00 — After Practice

**[Shot: Arthur taps Stop. SessionSummaryView appears — score rings, AI summary.]**

> "After every session, Gemma 4 generates a summary of what he worked on, what needs attention, and a 5-day practice plan."

**[Shot: Practice plan on screen — Day 1: Bow arm, Day 2: Intonation, etc.]**

**[Shot: "Share with Teacher" button tapped. Teacher report generates. Share sheet appears.]**

> "And with one tap, his teacher Tomoko gets a structured report — so their next lesson picks up exactly where the AI left off."

---

## 2:00–2:30 — The Architecture

**[Shot: Architecture diagram — iPhone → Cactus E2B → Ollama 26B on Studio]**

> "The technical heart of Maestro Gemma is a two-model routing architecture — exactly what the Cactus prize is designed for."

> "Gemma 4 E2B runs on-device via the Cactus SDK, on the Apple Neural Engine, INT4 quantized. It handles real-time frame analysis — always fast, always private, works offline."

> "For deeper reasoning, the app routes to Gemma 4 26B running via Ollama on a local Mac Studio. No cloud. No subscriptions. No data ever leaves the home."

**[Shot: GemmaCoach.swift routing logic briefly on screen — clean, readable code.]**

> "The routing decision is simple: real-time → on-device. Complex reasoning → local server. If the server's unreachable, the app falls back gracefully."

---

## 2:30–3:00 — The Vision

**[Shot: Arthur playing — confident, focused. Coaching overlay updates.]**

> "Arthur is 8 years old. He now practices with more confidence, because he knows someone is watching."

**[Shot: Wide shot — just a kid, a violin, and a phone.]**

> "Maestro Gemma costs nothing to run. It works offline. It never stores a single frame of video or second of audio. It speaks to children in language they understand."

> "Every child with a $50 violin deserves expert feedback. Gemma 4 makes that possible."

**[Shot: App icon. GitHub URL. Kaggle competition badge.]**

> "Maestro Gemma. Open source. Built for Arthur. Built for every Arthur."

---

## Production Notes

- Film in natural light, Arthur's actual practice space
- Use iPhone mounted on music stand for app demo shots — don't use a screen recording
- Keep coaching overlay legible — use portrait orientation, good contrast
- The Ask Coach sequence: have Arthur pre-type the question, hit submit on camera
- Architecture diagram: clean white/dark slide, animated arrows showing routing
- End card: GitHub repo URL + "Future of Education · Cactus Prize"
- Total runtime target: 2:45–3:00
