# 2026-07-10-deep-sleep-tip — Implementation plan

Reference: `specs/2026-07-10-deep-sleep-tip/requirements.md`. Source docs: [PR #17](https://github.com/tadasz/BabyLight/pull/17) (`docs/DEEP_SLEEP_TIP_PLAN.md`, `docs/DEEP_SLEEP_TIP_RESEARCH.md`).

Groups land as self-contained commits, red/green TDD (simulated clock — same pattern as the existing `shouldPromptForReview` tests). Groups 1–3 = Phase 1 (one PR, ships alone); group 4 = Phase 2; group 5 = Phase 3 — each phase its own branch + PR into `main` with a TestFlight build; real-nursery feedback between phases feeds the tunable constants.

## 1. Baby profile + settling-session semantics — delivers US-1

Purpose: replace "timer resets on every activation" with a real session the estimate can trust.

✅ 1.1 `Baby Light/SleepTip/BabyProfile.swift` — birth-month storage (`UserDefaults`), age-bucket boundaries (0–3/3–6/6–12/12+ mo), window lookup per anchor kind (35/30/25/20 from `appOpen`; 20/15/10/10 from `cryCessation`).
✅ 1.2 `SettlingSession` semantics in `LightViewModel.swift`: survives resign-active < 3 min; ends on background > 3 min, auto-off reaching 0, or manual reset; on-screen timer switches to time-since-session-start. Feature-gated: with the feature off, the existing `startElapsedTimer` reset-on-activation path runs untouched (AC4). Session elapsed time derives from the session-start `Date`, not tick counting — timers don't fire while suspended, and the display must be correct after a < 3 min interruption (requirements → Decisions; resolves feed-timer's recorded tick-counting debt for this path).
✅ 1.3 Unit tests: bucket boundaries, window lookup, interruption survival/expiry with a simulated clock.

Exit criteria: AC3 passes; profile lookups pure and tested.

## 2. SleepTipEngine + session log — delivers US-1

Purpose: the testable core — when to glow, when to re-arm, what to record.

✅ 2.1 `Baby Light/SleepTip/SleepTipEngine.swift` — pure state machine `idle → settling → tipDue(round) → acknowledged`, driven by injected clock ticks + events (`sessionStarted`, `wentInactive/BecameActive`, `cryBoutConfirmed/Ended`, `acknowledged`, `manualReset`); tip time = anchor + window(ageBucket, anchorKind) + learnedOffset(bucket) + userFineTune; repeat every 5 min, max 4 rounds.
✅ 2.2 `Baby Light/SleepTip/SessionLog.swift` — record model per requirements → Data model; ring buffer ~100, JSON in Application Support; one append at session end. Background-expired sessions get their record written on the next activation; tolerate loss on force-quit (requirements → Data model durability caveat).
✅ 2.3 Unit tests: glow timing per bucket ± fine-tune, repeat/max-round rules, anchor override ordering, log record shape + ring-buffer cap.

Exit criteria: AC1, AC2, AC5 pass at engine level (UI pending group 3); Data-model invariants asserted.

## 3. Glow UI, controls, localization — delivers US-1 (completes Phase 1)

Purpose: make the engine visible and configurable without disturbing baby or existing gestures.

✅ 3.1 `Baby Light/GlowPulse.swift` — ViewModifier animating `lightened(by:)` on the light color: 3 pulses × ~1.5 s ease-in-out, ~+12 % lightness, hue preserved.
✅ 3.2 `ContentView.swift` — glow modifier wired to engine state; single-tap acknowledge active only while pulsing; long-press (0.6 s) reset via `simultaneousGesture`. Both gestures attach to the light surface — the timer text keeps `allowsHitTesting(false)`. Verify on device: no conflict with double-tap (controls) / drag (brightness), no added double-tap recognition latency, no TipKit popover interference (step-2 tip anchors on the timer text).
✅ 3.3 `ControlsOverlay.swift` — "DEEP SLEEP TIP" section: on/off, birth-month picker, fine-tune stepper (−10…+10), learned-value caption placeholder. Accessibility identifiers on elements the UI tests need (patterns §11), e.g. `deepSleepTipSection`.
✅ 3.4 Localize ~10 new strings through the 26-locale pipeline (`AppStore/LOCALIZATION.md`); update per-locale screenshots of the controls section (existing tooling).
✅ 3.5 UI tests: settings section appears; feature-off parity with current app.
✅ 3.6 Same-PR docs (CLAUDE.md §1): update README + changelog of `specs/features/{feed-timer,light-screen,controls-overlay,auto-off-timer,first-run-tutorial}`; amend `specs/patterns.md` §4 with the sanctioned SessionLog file-on-disk exception (requirements → Decisions).

Exit criteria: Phase-1 acceptance — AC1–AC5 + AC10 pass end-to-end; feature off → app identical to today; touched feature folders and patterns §4 updated.

Dogfood round 1 (TestFlight 28, 2026-07-11): settling-time gestures masked `.subviews` while controls are visible (defect: ancestor long-press swallowed picker/stepper taps); birth month → birthday; stepper relabeled "Glow earlier or later" + live window caption (requirements → Decisions). Regression UI test: `testDeepSleepTipControlsRespondWhileOverlayVisible`.

## 4. CryDetector + anchor switching — delivers US-2 (Phase 2)

Purpose: swap the fuzzy app-open anchor for cry-cessation when the mic can prove it.

✅ 4.1 `Baby Light/SleepTip/CryDetector.swift` — `SNClassifySoundRequest(classifierIdentifier: .version1)` on an `AVAudioEngine` mic tap via `SNAudioStreamAnalyzer`; runs only while a session is active and the toggle is on.
4.2 Verify exact labels via `knownClassifications` at integration time (`baby_crying`; treat `crying_sobbing` as a match if present). — labels wired as `CryDetector.cryLabels = {baby_crying, crying_sobbing}`; **`knownClassifications` verification is an on-device step, still pending** (can't run in the simulator).
✅ 4.3 Tunable constants in a single config struct: window 1.5 s, 50 % overlap, confidence ≥ 0.6; bout confirmed = ≥ 3 positive windows in 10 s; bout ended = 120 s without one. — `CryBoutTracker.Config` (debounce) + the request's `windowDuration`/`overlapFactor`.
✅ 4.4 Anchor switching in the engine: bout end re-anchors; new bout clears pending/shown tip and re-arms; cry events append to the session log. — engine path pre-existed (dormant); wired detector → engine, and session record now logs real `cryBouts`.
✅ 4.5 Permission flow: localized `NSMicrophoneUsageDescription` ("listens locally for crying to time the sleep tip; nothing is recorded or leaves the device"); denied → `appOpen` fallback; orange-dot disclosure in settings copy. — usage string + fallback + disclosure copy done; **26-locale fill complete** — 2 UI strings in `Localizable.xcstrings` + `NSMicrophoneUsageDescription` in new `InfoPlist.xcstrings`, verified compiled into the built bundle (per-locale `.lproj`).
✅ 4.6 Unit tests: bout confirm/end debounce with scripted classifier events (grunts never confirm); anchor override; denial fallback. — `CryBoutTrackerTests` (6) + existing engine anchor tests; denial fallback is by-design (start-completion ignored, anchor stays `appOpen`) — not directly unit-tested (needs the permission API).
✅ 4.7 Same-PR docs: update `specs/tech-stack.md` frameworks (SoundAnalysis, AVFoundation) and `specs/patterns.md` §8 (off-main audio callbacks); check whether `PrivacyInfo.xcprivacy` becomes required (none exists today); changelog entries for touched feature folders (controls-overlay: mic toggle). — feature-folder README + changelog updated; **constitution edits applied with owner approval 2026-07-12** (tech-stack frameworks + patterns §8); `PrivacyInfo.xcprivacy` assessed **not newly required** (mic covered by usage string; no data collection / third-party SDKs) — re-confirm at ASC submission.

Exit criteria: AC6–AC8 pass (AC6/AC7 verified via tests; AC8 code-complete, device-pending QA-3); tech-stack/patterns drift closed; localization complete; Phase-2 PR + TestFlight (device verification of live mic + label review remain before merge).

## 5. Calibration — delivers US-3 (Phase 3)

Purpose: per-baby accuracy without any new interaction.

✅ 5.1 `Baby Light/SleepTip/Calibration.swift` — outcome labels from the log (cry ≤ 5 min after glow → `tooEarly`; calm session end after glow → `success`); buckets nap/night × anchorKind; EMA α = 0.2 on the offset *relative to the age default*, clamp ±10 min, apply only after ≥ 5 outcomes, rolling window ~20. Wired into `beginSettlingSession` (app-open bucket) + `updateLearnedOffset` on the cry-cessation anchor switch.
✅ 5.2 Settings: learned-value caption ("~16 min after quiet · learned from 12 nights") + reset-learning button; controls-overlay + deep-sleep-tip feature-folder changelog entries. — caption "Learned from your last N nights — glows about M min…" + **Reset** button (id `sleepTipResetLearning`); localized ×26; feature folders updated.
✅ 5.3 Unit tests: cold start (offset 0), clamp, ≥ 5 gate, aging-out, relative-to-default drift as the baby ages. — `CalibrationTests` (10): gate, reinforce, ±clamp, too-early nudge, window aging-out, age-relative consistency, unknown-exclusion, bucket scoping, cry-timing outcome.

**Group-5 Decisions (owner delegated 2026-07-12; confirm against real data):**
- Per-record EMA target: a `success` reinforces the offset that produced it; a `tooEarly` rousing argues for +`tooEarlyNudgeMinutes` (default 5). EMA seeded with the first target so consistent outcomes converge instead of lagging from 0.
- Reset-learning is **non-destructive** — a `sleepTipLearningResetDate` marker filters the log; the raw records stay for the success measurement (rather than deleting the log).
- Caption reflects the **night × app-open** bucket (the representative case); nap/cry-cessation buckets calibrate independently but aren't separately surfaced in the caption.

Exit criteria: AC9 passes at logic level (device/nursery tuning outstanding); Phase-3 PR + TestFlight.

## Non-goals for this plan

- Phase-4 refinements: Watch wrist-tap (WatchConnectivity), tap-to-anchor sleep onset, CoreMotion transfer detection — separate proposals.
- dB-threshold audio metering — rejected alternative (requirements → Why → Alternatives).
- Cloud sync / analytics / custom ML — out of scope by privacy design.
- Any change outside `Baby Light/`, its test target, and the localization/App Store assets named above.
