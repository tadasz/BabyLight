# 2026-07-10-deep-sleep-tip — Deep-Sleep Tip (glow put-down cue)

**Jira:** none · **Status on ingest:** proposal — [PR #17](https://github.com/tadasz/BabyLight/pull/17) (docs-only: `docs/DEEP_SLEEP_TIP_PLAN.md` + `docs/DEEP_SLEEP_TIP_RESEARCH.md`) · **Target release:** three phased PRs (Phase 4 deferred to separate proposals)

## Review focus

- **Problem:** parents settling a baby can't tell when it has reached deep sleep; put-downs attempted during active sleep fail and restart the whole settling cycle.
- **Genuine forks:** cry-cessation anchor vs. tap-to-mark sleep onset; Apple built-in sound classifier vs. dB threshold — see Decisions.
- **Constitution:** checked 2026-07-10 against `specs/mission.md`, `specs/tech-stack.md`, `specs/patterns.md` (merged after this spec was first authored). Four deviations identified and owner-approved in the PR #21 review: session-log file on disk (patterns §4), new `SleepTip/` module (patterns §2), deliberate glow brightening (patterns §1 dark-is-sacred), feed-timer session semantics (feature contract) — each recorded under Decisions.
- **Open questions:** none — see Resolved.

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

1. **Entry point** — the parent already opens Baby Light on the nightstand when settling starts (it *is* the night light). One-time setup: double-tap → controls overlay → "DEEP SLEEP TIP" section → toggle on, pick the baby's birthday.
2. App becomes active → a settling session starts; the big on-screen timer now counts time since session start.
3. Parent briefly checks a message (< 3 min) → on return the timer and estimate have kept running, not reset.
4. At the age window (e.g. 6–12 mo: ~25 min from open) → the background gently pulses 3 × ~1.5 s, ~+12 % lightness, keeping hue; no sound, no haptics.
5. Parent does the limp-limb test and attempts the put-down → single tap on the light acknowledges (the timer text has `allowsHitTesting(false)`; the gesture lives on the light surface); pulsing stops (tap-to-acknowledge is live only while pulsing).
6. **Most likely failure:** baby wasn't deep yet and rouses → parent long-presses the light (0.6 s) → fresh session starts; (unacknowledged glows would re-fire every 5 min, max 4 rounds).
7. **Empty / first-use state:** feature off by default → app behaves exactly as today; enabling reveals the birthday picker, the glow-offset stepper, and the live "glows about N min" caption.
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
- Docs, same-PR obligations (CLAUDE.md §1): touched `specs/features/*` README + changelog per phase (see Touches features); `specs/patterns.md` §4 amendment recording the sanctioned session-log file exception (Phase 1); `specs/tech-stack.md` frameworks + `specs/patterns.md` §8 concurrency notes (Phase 2).

**Containment:** changes stay within the files above; overflow re-opens scope. Read-only adjacencies a tempted implementer would otherwise touch: the double-tap (controls) and drag (brightness) gesture handlers in `ContentView.swift` (new gestures must coexist via `simultaneousGesture`, not modify them); `UIScreen.brightness` / idle-timer lifecycle code in `LightViewModel.swift` beyond the session-semantics change; `TimerOption.swift` auto-off logic (session end *consumes* it, never alters it).

**AI-readiness flag:** no file-size/complexity sensors exist in this repo; targets are small single-purpose SwiftUI files, but caps were not machine-checked — first SDD ticket here, sensors are a candidate follow-up.

## Touches features

The `specs/features/` corpus exists since PR #20; every touched folder's README + changelog must be updated in the same PR that changes its behaviour (CLAUDE.md §1):

- `specs/features/feed-timer/` — **contract change**: with the feature on, the elapsed display becomes date-derived time-since-session-start and survives < 3 min interruptions. Its README pins reset-on-activation as the product behaviour — that stays true with the feature off (AC4). The watch timer is untouched (deliberate iOS↔watch semantics divergence, recorded per patterns §3).
- `specs/features/light-screen/` — glow pulse renders on the light surface; tap-to-acknowledge and long-press join the existing double-tap/drag gesture stack.
- `specs/features/controls-overlay/` — new "DEEP SLEEP TIP" section.
- `specs/features/auto-off-timer/` — auto-off reaching 0 ends the settling session (read-only consumption; its logic is never altered).
- `specs/features/first-run-tutorial/` — its step-2 tip anchors on the timer text this feature adds gestures around; verify no TipKit interference (read-mostly).
- New after Phase-1 ship: `specs/features/deep-sleep-tip/` (README + metadata + changelog seeded from this folder).

## Data model

On-device persistence only — no server, nothing leaves the device.

- `UserDefaults`: birthday (optional `Date`; stored under the original `sleepTipBirthMonth` key — permanent API), feature on/off, mic toggle (Phase 2), fine-tune minutes (−10…+10).
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

**Lifecycle & invariants:** engine writes one record at session end (from Phase 1, so calibration has history when it ships); Calibration (Phase 3) and the settings caption read. Invariants: learned offset is stored *relative to the age default*, clamped ±10 min, applied only after ≥ 5 outcomes per (nap/night × anchorKind) bucket, rolling window ~20; the log never leaves the device. Durability caveat: a `background`-expired session's record can only be written on the *next* activation (no code runs at the 3-min mark while suspended); a force-quit before then loses that record — AC5 is per-completed-session, not a durability guarantee, and calibration reads must tolerate an incomplete log.

## Decisions

- Cry-cessation anchor over tap-to-mark sleep onset — zero-interaction principle; the tap variant is Phase 4.
- Apple built-in classifier (`SNClassifySoundRequest(.version1)`) over dB threshold — white noise is the nursery norm, not the edge case; metering can't tell crying from it.
- Pulse background lightness via `lightened(by:)`, never `UIScreen.brightness` — works with hardware brightness near zero and avoids the lifecycle brightness fights the app already has.
- New confirmed cry = full re-anchor (v1) — simplest correct behavior; conservative failure direction (glow later, never earlier); revisit with real usage.
- Learned offset relative to age default (not absolute), clamp ±10, ≥ 5-outcome gate, α = 0.2 EMA — stays valid as the baby ages; regressions age out via the ~20-outcome window.
- Session survives < 3 min interruptions — checking a message must not restart the estimate (today `elapsedSeconds` resets on every activation).
- Session logging ships in Phase 1 despite calibration being Phase 3 — calibration needs history on day one.
- Dogfood amendments (TestFlight 28, 2026-07-11, owner): (1) full **birthday** instead of birth month — the picker was already date-granular; labels/copy now say birthday and the age math gains day precision; the `sleepTipBirthMonth` UserDefaults key is permanent API and keeps its name. (2) The fine-tune stepper is relabeled "Glow earlier or later" and a live caption ("Glows about N min after you open the app — the typical time to reach deep sleep at this age.") explains the age-window logic and makes the stepper's effect visible — no later story covered explaining the logic, so it lands in Phase 1. (3) The tap-acknowledge and long-press gestures are masked to `.subviews` while the controls overlay is open — an ancestor long-press recognizer swallowed taps meant for the overlay's date picker and stepper (the dogfood defect), and the mask also prevents accidental session resets while adjusting settings.
- Success measured by on-device log + parent-reported nursery protocol — analytics are out by privacy design; this is the honest maximum evidence available.
- Session semantics are feature-gated — feature off leaves the existing reset-on-activation path (`startElapsedTimer`) untouched, which is what makes AC4's parity clause literal. With the feature on, the elapsed display derives from the session-start `Date` (wall-clock), not tick counting — timers don't fire while suspended, so a < 3 min interruption must not under-count. This deliberately changes the feed-timer contract for the feature-on path and resolves that folder's recorded tick-counting debt there (owner-approved 2026-07-10; feed-timer README updated in the Phase-1 PR).
- SessionLog persists as a JSON file in Application Support — a sanctioned deviation from patterns §4 ("no files on disk"; UserDefaults is unsuited to a ~100-record ring buffer). Owner-approved 2026-07-10; the Phase-1 PR amends patterns §4 to record the exception.
- The `SleepTip/` module (engine, profile, log, detector, calibration) is a spec-level architecture Decision per patterns §2: pure logic with an injected clock is the only way to test timing without wall-clock waits, and phases isolate cleanly. The one-view-model rule stands — `LightViewModel` remains the sole owner of UI state.
- The glow is a *sanctioned, expected* brightening under patterns §1 (dark is sacred): opt-in, hue-preserving, ~+12 % lightness for ~4.5 s, never system UI. Owner-approved 2026-07-10.
- Phase 2 adds SoundAnalysis/AVFoundation and off-main audio callbacks — the Phase-2 PR updates `tech-stack.md`'s framework list and patterns §8's main-thread-only note, and checks whether a `PrivacyInfo.xcprivacy` becomes required (none exists today).

## Open questions

- none.

## Resolved

- No Jira/issue tracker entry exists for this work — GitHub issue or dated slug? → Dated slug accepted (Tadas, 2026-07-10, by instructing implementation to proceed without a tracker entry); revisit if the spec corpus outgrows it.
- PR #21 porting review (2026-07-10) → folded into this spec: constitution check re-run against the now-merged `specs/{mission,tech-stack,patterns}.md`; Touches features corrected to the real feature-folder list; timer-semantics feature-gating and wall-clock derivation pinned as Decisions; AC5 durability caveat added; tap/long-press targets corrected to the light surface; `Tips.swift` mislabel fixed in validation.md.

- Where should the spec live (originally drafted in `dogo-app/marketing-automation-mastra`, the authoring session's only writable repo)? → Ported here to `tadasz/BabyLight` `specs/`; the implementation target and the spec now share a repo.
