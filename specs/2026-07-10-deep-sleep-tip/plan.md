# 2026-07-10-deep-sleep-tip — Implementation plan

Reference: `specs/2026-07-10-deep-sleep-tip/requirements.md`. Source docs: [PR #17](https://github.com/tadasz/BabyLight/pull/17) (`docs/DEEP_SLEEP_TIP_PLAN.md`, `docs/DEEP_SLEEP_TIP_RESEARCH.md`).

Groups land as self-contained commits, red/green TDD (simulated clock — same pattern as the existing `shouldPromptForReview` tests). Groups 1–3 = Phase 1 (one PR, ships alone); group 4 = Phase 2; group 5 = Phase 3 — each phase its own branch + PR into `main` with a TestFlight build; real-nursery feedback between phases feeds the tunable constants.

## 1. Baby profile + settling-session semantics — delivers US-1

Purpose: replace "timer resets on every activation" with a real session the estimate can trust.

1.1 `Baby Light/SleepTip/BabyProfile.swift` — birth-month storage (`UserDefaults`), age-bucket boundaries (0–3/3–6/6–12/12+ mo), window lookup per anchor kind (35/30/25/20 from `appOpen`; 20/15/10/10 from `cryCessation`).
1.2 `SettlingSession` semantics in `LightViewModel.swift`: survives resign-active < 3 min; ends on background > 3 min, auto-off reaching 0, or manual reset; on-screen timer switches to time-since-session-start.
1.3 Unit tests: bucket boundaries, window lookup, interruption survival/expiry with a simulated clock.

Exit criteria: AC3 passes; profile lookups pure and tested.

## 2. SleepTipEngine + session log — delivers US-1

Purpose: the testable core — when to glow, when to re-arm, what to record.

2.1 `Baby Light/SleepTip/SleepTipEngine.swift` — pure state machine `idle → settling → tipDue(round) → acknowledged`, driven by injected clock ticks + events (`sessionStarted`, `wentInactive/BecameActive`, `cryBoutConfirmed/Ended`, `acknowledged`, `manualReset`); tip time = anchor + window(ageBucket, anchorKind) + learnedOffset(bucket) + userFineTune; repeat every 5 min, max 4 rounds.
2.2 `Baby Light/SleepTip/SessionLog.swift` — record model per requirements → Data model; ring buffer ~100, JSON in Application Support; one append at session end.
2.3 Unit tests: glow timing per bucket ± fine-tune, repeat/max-round rules, anchor override ordering, log record shape + ring-buffer cap.

Exit criteria: AC1, AC2, AC5 pass at engine level (UI pending group 3); Data-model invariants asserted.

## 3. Glow UI, controls, localization — delivers US-1 (completes Phase 1)

Purpose: make the engine visible and configurable without disturbing baby or existing gestures.

3.1 `Baby Light/GlowPulse.swift` — ViewModifier animating `lightened(by:)` on the light color: 3 pulses × ~1.5 s ease-in-out, ~+12 % lightness, hue preserved.
3.2 `ContentView.swift` — glow modifier wired to engine state; single-tap acknowledge active only while pulsing; long-press (0.6 s) reset via `simultaneousGesture`; verify no conflict with double-tap (controls) / drag (brightness) on device.
3.3 `ControlsOverlay.swift` — "DEEP SLEEP TIP" section: on/off, birth-month picker, fine-tune stepper (−10…+10), learned-value caption placeholder.
3.4 Localize ~10 new strings through the 26-locale pipeline (`AppStore/LOCALIZATION.md`); update per-locale screenshots of the controls section (existing tooling).
3.5 UI tests: settings section appears; feature-off parity with current app.

Exit criteria: Phase-1 acceptance — AC1–AC5 + AC10 pass end-to-end; feature off → app identical to today.

## 4. CryDetector + anchor switching — delivers US-2 (Phase 2)

Purpose: swap the fuzzy app-open anchor for cry-cessation when the mic can prove it.

4.1 `Baby Light/SleepTip/CryDetector.swift` — `SNClassifySoundRequest(classifierIdentifier: .version1)` on an `AVAudioEngine` mic tap via `SNAudioStreamAnalyzer`; runs only while a session is active and the toggle is on.
4.2 Verify exact labels via `knownClassifications` at integration time (`baby_crying`; treat `crying_sobbing` as a match if present).
4.3 Tunable constants in a single config struct: window 1.5 s, 50 % overlap, confidence ≥ 0.6; bout confirmed = ≥ 3 positive windows in 10 s; bout ended = 120 s without one.
4.4 Anchor switching in the engine: bout end re-anchors; new bout clears pending/shown tip and re-arms; cry events append to the session log.
4.5 Permission flow: localized `NSMicrophoneUsageDescription` ("listens locally for crying to time the sleep tip; nothing is recorded or leaves the device"); denied → `appOpen` fallback; orange-dot disclosure in settings copy.
4.6 Unit tests: bout confirm/end debounce with scripted classifier events (grunts never confirm); anchor override; denial fallback.

Exit criteria: AC6–AC8 pass; Phase-2 PR + TestFlight.

## 5. Calibration — delivers US-3 (Phase 3)

Purpose: per-baby accuracy without any new interaction.

5.1 `Baby Light/SleepTip/Calibration.swift` — outcome labels from the log (cry ≤ 5 min after glow → `tooEarly`; calm session end after glow → `success`); buckets nap/night × anchorKind; EMA α = 0.2 on the offset *relative to the age default*, clamp ±10 min, apply only after ≥ 5 outcomes, rolling window ~20.
5.2 Settings: learned-value caption ("~16 min after quiet · learned from 12 nights") + reset-learning button.
5.3 Unit tests: cold start (offset 0), clamp, ≥ 5 gate, aging-out, relative-to-default drift as the baby ages.

Exit criteria: AC9 passes; Phase-3 PR + TestFlight.

## Non-goals for this plan

- Phase-4 refinements: Watch wrist-tap (WatchConnectivity), tap-to-anchor sleep onset, CoreMotion transfer detection — separate proposals.
- dB-threshold audio metering — rejected alternative (requirements → Why → Alternatives).
- Cloud sync / analytics / custom ML — out of scope by privacy design.
- Any change outside `Baby Light/`, its test target, and the localization/App Store assets named above.
