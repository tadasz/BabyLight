# 2026-07-10-deep-sleep-tip — Deep-Sleep Tip (glow put-down cue)

**Jira:** none · **Status on ingest:** proposal — [PR #17](https://github.com/tadasz/BabyLight/pull/17) (docs-only: `docs/DEEP_SLEEP_TIP_PLAN.md` + `docs/DEEP_SLEEP_TIP_RESEARCH.md`) · **Target release:** four phased PRs

## Review focus

- **Problem:** parents settling a baby can't tell when it has reached deep sleep; put-downs attempted during active sleep fail and restart the whole settling cycle.
- **Genuine forks:** cry-cessation anchor vs. tap-to-mark sleep onset; Apple built-in sound classifier vs. dB threshold — see Decisions.
- **Constitution:** none — BabyLight has no constitution docs yet; this spec follows PR #17's plan/research and the app's existing conventions.
- **Open questions:** 1 unresolved.

## Context

BabyLight is a night-light iOS app parents leave open while settling a baby. The settling parent has no signal for when the baby has descended into deep sleep — the safe moment to attempt the put-down — so transfers are guesswork and often fail. This spec turns PR #17's research + plan into the SDD contract for a silent, on-device "worth trying now" glow cue.

## Why this, why now

**Underlying problem.** A parent rocking a baby at 2am must decide when to attempt the transfer to the crib. Newborns enter sleep through active (REM) sleep and only reach transferable quiet sleep ~20–30 min after onset; a transfer attempted too early wakes the baby and restarts settling from zero. The app already sits open on the nightstand with a timer, but the timer resets on every re-activation and says nothing about deep sleep.

**Evidence.** Sleep-lab literature summarized in `docs/DEEP_SLEEP_TIP_RESEARCH.md` §2 (sourced: Parenting Science, Sleep Foundation, Ask Dr. Sears); the author's own 6-month-old (successful transfers land 7–12 min after sleep onset, the fast edge of the age range); no in-app metrics exist by design (privacy label "Data Not Collected").

**Success outcome.** Within ~3 weeks of the Phase-1 TestFlight, real-nursery sessions (developer-parent protocol) show the first glow landing inside the successful-transfer window in most sessions, and put-downs attempted on the glow succeed more often than pre-feature guessing — evidenced by the on-device session log plus parent report, since analytics are out by privacy design.

**Alternatives considered.** Do nothing — parents keep guessing, failed transfers persist and the app stays a passive light. Loudness threshold instead of a classifier — rejected: can't distinguish crying from white noise (the common case in a nursery), a parent's voice, or active-sleep grunts. Tap-to-mark sleep onset — more accurate anchor but violates the zero-interaction principle; deferred to Phase 4.

**Assumptions.** (1) Cry-cessation is a usable sleep-onset proxy for babies who fuss until they drop off. (2) Apple's built-in `baby_crying` classification works in nursery conditions (white noise, quiet speech nearby). (3) Literature-based age windows are close enough to be useful before per-baby calibration accumulates.

## Users and use cases

### US-1 — Glow tip from app-open anchor (P1)

When settling a baby with the app open, the settling parent wants a subtle, silent cue when the baby has likely reached deep sleep, so they can attempt the put-down at the highest-odds moment instead of guessing.

Independent slice: birth-month setting + settling-session semantics + tip engine + glow pulses + manual reset + session logging — no microphone (Phase 1, ships alone).

Acceptance scenarios:

1. Given the feature is on and birth month set, when the app becomes active, then a settling session starts and the light glow-pulses at the age-default window ± fine-tune.
2. Given a glow was not acknowledged, when 5 min pass, then it re-glows, max 4 rounds.
3. Given a settling session is running, when the parent switches apps for < 3 min, then the session and estimate continue uninterrupted.
4. Given the feature is off, when the app is used, then behavior is identical to today.

### US-2 — Cry-anchored timing (P2)

When the baby cries during settling, the settling parent wants the estimate anchored to the end of the last crying bout (detected on-device), so the cue reflects actual sleep onset rather than when they happened to open the app.

Independent slice: CryDetector + anchor switching + permission flow; a new bout re-arms — reset falls out for free.

Acceptance scenarios:

1. Given sustained crying then ≥ 2 min quiet, when the bout ends, then the countdown re-anchors to bout end with the (shorter) cry-cessation window.
2. Given isolated grunts/squawks, when they occur, then the anchor never moves.
3. Given mic permission is denied, when a session runs, then everything works from the app-open anchor.

### US-3 — Per-baby calibration (P3)

When the same baby is settled night after night, the settling parent wants the glow time to drift toward that baby's observed successful put-down times, so accuracy improves without any extra interaction.

Independent slice: bucketed EMA offset from logged session outcomes, surfaced + resettable in settings.

Acceptance scenarios:

1. Given ≥ 5 logged outcomes in a bucket, when the next session runs, then the glow shifts toward observed successful times, never beyond ±10 min of the age default.
2. Given learning has occurred, when the parent opens settings, then the learned value ("~16 min after quiet · learned from 12 nights") is visible and resettable.

## How it will be used

Phase-1 (P1) journey; cry-anchored variants layer onto the same steps in Phase 2.

1. **Entry point** — the parent already opens Baby Light on the nightstand when settling starts (it *is* the night light). One-time setup: double-tap → controls overlay → "DEEP SLEEP TIP" section → toggle on, pick birth month.
2. App becomes active → a settling session starts; the big on-screen timer now counts time since session start.
3. Parent briefly checks a message (< 3 min) → on return the timer and estimate have kept running, not reset.
4. At the age window (e.g. 6–12 mo: ~25 min from open) → the background gently pulses 3 × ~1.5 s, ~+12 % lightness, keeping hue; no sound, no haptics.
5. Parent does the limp-limb test and attempts the put-down → single tap on the timer acknowledges; pulsing stops (tap-to-acknowledge is live only while pulsing).
6. **Most likely failure:** baby wasn't deep yet and rouses → parent long-presses the timer (0.6 s) → fresh session starts; (unacknowledged glows would re-fire every 5 min, max 4 rounds).
7. **Empty / first-use state:** feature off by default → app behaves exactly as today; enabling reveals the birth-month picker and fine-tune stepper.
8. **Success:** session ends calmly (app backgrounded after the put-down) → one session record lands in the on-device log — the raw material the Success outcome and Phase-3 calibration are measured from.

## Goal

A parent can act on a silent glow cue whose timing is verifiably anchored (app-open, later cry-cessation) and age-appropriate, and every session leaves a local log record proving the mechanism ran.

## Acceptance criteria

- [ ] AC1 (US-1) — Opening the app with the feature on starts a settling session; glow fires at the age-default window (0–3/3–6/6–12/12+ mo → 35/30/25/20 min from app open) ± user fine-tune (−10…+10 min).
- [ ] AC2 (US-1) — Unacknowledged glow repeats every 5 min, max 4 rounds; stops on acknowledge, reset, new cry bout, or backgrounding; single-tap acknowledge is active only while pulsing.
- [ ] AC3 (US-1) — Session survives interruptions < 3 min; ends on background > 3 min, auto-off reaching 0, or long-press (0.6 s) manual reset.
- [ ] AC4 (US-1) — Feature off → app behaves exactly as today (gesture, timer, and brightness parity).
- [ ] AC5 (US-1) — Every session appends one record to the capped on-device log (see Data model), starting in Phase 1.
- [ ] AC6 (US-2) — Sustained crying then ≥ 2 min quiet re-anchors the countdown to bout end + cry-cessation window (e.g. 6–12 mo → ~10 min after quiet); isolated grunts/squawks (< 3 positive windows in 10 s) never move the anchor.
- [ ] AC7 (US-2) — A new confirmed bout clears any pending/shown tip and re-arms from its own end.
- [ ] AC8 (US-2) — Mic permission denied → app-open anchor fallback; all other behavior intact; orange-dot disclosure present in settings copy.
- [ ] AC9 (US-3) — With ≥ 5 outcomes in a bucket, glow shifts toward observed successful times, clamped to ±10 min of the age default; settings shows the learned value with a reset-learning control.
- [ ] AC10 (US-1) — All new user-facing strings (~10 + mic usage description in Phase 2) go through the 26-locale pipeline; App Store privacy label stays "Data Not Collected".

## In scope

- Phases 1–3 of `docs/DEEP_SLEEP_TIP_PLAN.md`: glow tip + age setting + session semantics + logging; cry detection + anchor switching; per-baby calibration.
- Settings UI ("DEEP SLEEP TIP" section in the controls overlay) and localization of its strings.

## Out of scope

- Watch wrist-tap tip, tap-to-anchor "fell asleep" gesture, CoreMotion transfer detection — Phase 4, separate proposals per the source plan.
- Cloud sync, accounts, any analytics on baby data — everything stays on-device (privacy label unchanged).
- Medical claims in copy — the glow is always "a good moment to try", never "asleep now".
- Custom ML models — Apple's built-in classifier only.

## Edit surface & blast radius

Paths verified against `main` where marked *(edit)*; the rest are new:

- `Baby Light/SleepTip/SleepTipEngine.swift` (+ tests) — pure state machine `idle → settling → tipDue(round) → acknowledged`; injected clock, no timers/UI.
- `Baby Light/SleepTip/BabyProfile.swift` (+ tests) — birth-month storage, age-bucket + window lookup.
- `Baby Light/SleepTip/SessionLog.swift` (+ tests) — record model + ring-buffer persistence.
- `Baby Light/SleepTip/CryDetector.swift` (+ tests) — AVAudioEngine + SNAudioStreamAnalyzer wrapper, bout debounce, permission state (Phase 2).
- `Baby Light/SleepTip/Calibration.swift` (+ tests) — bucketed EMA offsets (Phase 3).
- `Baby Light/GlowPulse.swift` — ViewModifier pulsing `lightened(by:)` on the light color.
- `Baby Light/LightViewModel.swift` *(edit)* — owns engine/detector; scene-phase handlers gain session semantics.
- `Baby Light/ContentView.swift` *(edit)* — glow modifier, tap-to-acknowledge, long-press reset.
- `Baby Light/ControlsOverlay.swift` *(edit)* — new "DEEP SLEEP TIP" settings section.
- `Baby Light/Localizable.xcstrings` *(edit)* + `AppStore/LOCALIZATION.md` pipeline — new strings.

**Containment:** changes stay within the files above; overflow re-opens scope. Read-only adjacencies a tempted implementer would otherwise touch: the double-tap (controls) and drag (brightness) gesture handlers in `ContentView.swift` (new gestures must coexist via `simultaneousGesture`, not modify them); `UIScreen.brightness` / idle-timer lifecycle code in `LightViewModel.swift` beyond the session-semantics change; `TimerOption.swift` auto-off logic (session end *consumes* it, never alters it).

**AI-readiness flag:** no file-size/complexity sensors exist in this repo; targets are small single-purpose SwiftUI files, but caps were not machine-checked — first SDD ticket here, sensors are a candidate follow-up.

## Touches features

- none — no `specs/features/` corpus exists in BabyLight yet; if SDD sticks, `specs/features/deep-sleep-tip/` graduates from this ticket after ship (README + metadata + changelog seeded from this folder).

## Data model

On-device persistence only — no server, nothing leaves the device.

- `UserDefaults`: birth month (optional `Date`), feature on/off, mic toggle (Phase 2), fine-tune minutes (−10…+10).
- Session log: JSON ring buffer, ~100 records, Application Support — owned by `SessionLog.swift`.

| Field | Type | Null? | Notes |
|---|---|---|---|
| `date` | Date | no | session start |
| `ageMonths` | Int | yes | nil when birth month unset |
| `napOrNight` | enum | no | by clock hour |
| `anchorKind` | enum | no | `appOpen` \| `cryCessation` |
| `anchorTime` | Date | no | last-writer-wins per session |
| `glowTimes` | [Date] | no | may be empty |
| `cryBouts` | [{start, end}] | no | Phase 2+; empty before |
| `acknowledgeTime` | Date | yes | tap on timer |
| `outcome` | enum | no | `success` \| `tooEarly` \| `unknown` |
| `endReason` | enum | no | `background` \| `autoOff` \| `manualReset` |

**Change type:** additive — new files, no migration.

**Lifecycle & invariants:** engine writes one record at session end (from Phase 1, so calibration has history when it ships); Calibration (Phase 3) and the settings caption read. Invariants: learned offset is stored *relative to the age default*, clamped ±10 min, applied only after ≥ 5 outcomes per (nap/night × anchorKind) bucket, rolling window ~20; the log never leaves the device.

## Decisions

- Cry-cessation anchor over tap-to-mark sleep onset — zero-interaction principle; the tap variant is Phase 4.
- Apple built-in classifier (`SNClassifySoundRequest(.version1)`) over dB threshold — white noise is the nursery norm, not the edge case; metering can't tell crying from it.
- Pulse background lightness via `lightened(by:)`, never `UIScreen.brightness` — works with hardware brightness near zero and avoids the lifecycle brightness fights the app already has.
- New confirmed cry = full re-anchor (v1) — simplest correct behavior; conservative failure direction (glow later, never earlier); revisit with real usage.
- Learned offset relative to age default (not absolute), clamp ±10, ≥ 5-outcome gate, α = 0.2 EMA — stays valid as the baby ages; regressions age out via the ~20-outcome window.
- Session survives < 3 min interruptions — checking a message must not restart the estimate (today `elapsedSeconds` resets on every activation).
- Session logging ships in Phase 1 despite calibration being Phase 3 — calibration needs history on day one.
- Success measured by on-device log + parent-reported nursery protocol — analytics are out by privacy design; this is the honest maximum evidence available.

## Open questions

- No Jira/issue tracker entry exists for this work — track via GitHub issues in this repo, or accept the dated slug for side-project velocity? — who answers: Tadas.

## Resolved

- Where should the spec live (originally drafted in `dogo-app/marketing-automation-mastra`, the authoring session's only writable repo)? → Ported here to `tadasz/BabyLight` `specs/`; the implementation target and the spec now share a repo.
