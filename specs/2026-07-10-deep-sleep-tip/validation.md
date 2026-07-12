# 2026-07-10-deep-sleep-tip — Validation

Merge gate per phase PR: every box relevant to the phase ticked = ready for `main`.

## Success outcome — did this actually work?

- [ ] Outcome restated: first glow lands inside the successful-transfer window in most real-nursery sessions; glow-timed put-downs beat pre-feature guessing.
- [ ] Measurement plan: on-device session log (outcome field) + parent-reported nursery protocol — owner: Tadas, due: ~3 weeks after Phase-1 TestFlight.

## Acceptance criteria — verification

- [x] AC1 (US-1, P1) glow at age window ± fine-tune — verify by: engine unit tests (simulated clock, all four buckets) — ✅ 2026-07-10 `SleepTipEngineTests`
- [x] AC2 (US-1, P1) repeat 5 min × ≤ 4, acknowledge only while pulsing — verify by: engine unit tests + manual QA-G — ✅ 2026-07-10
- [x] AC3 (US-1, P1) session survives < 3 min interruptions — verify by: session unit tests + QA-1 — ✅ 2026-07-10 `SettlingSession*Tests`
- [x] AC4 (US-1, P1) feature-off parity — verify by: UI test (XCTest) feature-off behavior parity — ✅ 2026-07-10 `testDeepSleepTipOffByDefaultAndGesturesUnchanged` + full pre-existing suite green
- [x] AC5 (US-1, P1) one log record per session — verify by: SessionLog unit tests (shape + ring cap) + QA-G step 6 — ✅ 2026-07-10 (endReason asserted for background/autoOff/manualReset paths)
- [x] AC6 (US-2, P2) cry-cessation re-anchor; grunts never move anchor — verify by: bout-debounce unit tests (scripted classifier events) + QA-2 — ✅ 2026-07-12 `CryBoutTrackerTests` (3-in-10s confirms, isolated grunts/spaced squawks never confirm, 120s-quiet ends) + engine `cryBoutOverridesAnchor`; QA-2 (device) still owed
- [x] AC7 (US-2, P2) new bout clears tip, re-arms — verify by: engine unit tests + QA-2 — ✅ 2026-07-12 `SleepTipEngineTests.newBoutClearsShownTipAndReArms` (green against the now-wired detector path)
- [ ] AC8 (US-2, P2) mic-denied fallback + orange-dot disclosure — verify by: unit test (permission state) + QA-3 — orange-dot disclosure copy + denied→appOpen fallback are **code-complete**; permission state can't be unit-tested (AVAudioApplication) and QA-3 is device — **device-pending**
- [ ] AC9 (US-3, P3) calibration shift, ±10 clamp, ≥ 5 gate, reset control — verify by: calibration unit tests + QA-4
- [x] AC10 (US-1, P1) strings localized, privacy label unchanged — verify by: xcstrings diff covers all new keys (26 locales); App Store Connect privacy section review — ✅ 2026-07-10: 6 keys × 26 locales via the i18n pipeline (regen-stable); Phase 1 adds no data collection, label untouched. ✅ 2026-07-12 Phase 2: 2 UI strings × 26 locales in `Localizable.xcstrings` + `NSMicrophoneUsageDescription` × 26 (+en) in new `InfoPlist.xcstrings` — **verified compiled into the built bundle** (base plist + per-locale `InfoPlist.strings`/`Localizable.strings` inspected). Privacy label "Data Not Collected" unchanged (mic audio classified in-memory, never stored/sent); ASC label review still owed at submission

## UI coverage

XCTest UI tests: settings section appears (plan task 3.5); feature-off parity (AC4). Everything else is engine-level unit tests by design (pure state machine, injected clock — no UI needed to verify timing).

## Data model — schema verification

- [x] Log record matches the pinned field table — verify by: SessionLog encode/decode round-trip test — ✅ 2026-07-10 `SessionLogTests.recordRoundTripsThroughDisk`
- [ ] Invariants hold (relative offset, ±10 clamp, ≥ 5 gate, ~20 window, on-device only) — verify by: calibration unit tests; no networking code in `SleepTip/`

## Automated checks

- [x] Test suite green per phase PR (`xcodebuild test`; simulated-clock determinism — no wall-clock waits) — ✅ 2026-07-10 Phase 1: unit + UI suites
- [x] No new dependencies — Apple frameworks only (SoundAnalysis, AVFoundation are system-provided); anything else re-opens Decisions — ✅ 2026-07-10 Phase 1 imports only Foundation/SwiftUI

## Manual QA

- [x] App boots clean with feature off (parity with shipped build) — ✅ 2026-07-10 sim screenshot: full-bleed light, toggle off, section collapsed
- [x] QA-G (sim) — goal demo, simulated clock — ✅ 2026-07-10 via the engine-test harness (steps 1–6 map to `SleepTipEngineTests`/`SettlingSessionLifecycleTests`) + sim screenshots of the section (off/on)
- [x] QA-1 (sim) — interruption semantics — ✅ 2026-07-10 simulated-clock lifecycle tests incl. logged endReason
- [ ] QA-2 (sim) — cry anchor + debounce (scripted events)
- [ ] QA-3 (device) — mic-permission denial fallback
- [ ] QA-4 (sim) — calibration math + reset
- [ ] QA-5 (nursery) — real settling session: glow visible at near-zero hardware brightness, white-noise machine running, orange dot acknowledged

## Non-regression

- [x] Existing flows still work: double-tap opens controls, drag adjusts brightness, auto-off timer; first-run tutorial (TipKit, `Tips.swift` — its step-2 tip anchors on the timer text) and rating-prompt gating (`LightViewModel.maybeRequestReview()`) untouched — ✅ 2026-07-10 pre-existing UI suite green; `Tips.swift` + rating logic zero-diff
- [x] Diff stayed within **Edit surface & blast radius**; overflow surfaced as a separate ticket — ✅ 2026-07-10 `git status` matches the listed surface exactly
- [x] Feature off → zero behavioral delta (AC4 is the regression gate) — ✅ 2026-07-10 `sessionStart` nil ⇒ byte-identical tick path; UI parity test

## Touched feature folders

- [x] README + changelog updated in the same PR as the behaviour change (requirements → Touches features): feed-timer, light-screen, controls-overlay, auto-off-timer, first-run-tutorial (per phase, as touched) — ✅ 2026-07-10 Phase 1 (first-run-tutorial behaviour unchanged → no update owed)
- [x] Constitution amendments landed with the code that motivates them: `specs/patterns.md` §4 SessionLog file exception (Phase 1) — ✅ 2026-07-10 owner-instructed, applied together with the tech-stack.md persistence line; `specs/tech-stack.md` frameworks (SoundAnalysis/AVFoundation) + `specs/patterns.md` §8 off-main audio-callback note (Phase 2) — ✅ 2026-07-12 owner-approved and applied with the CryDetector code
- [x] `specs/features/deep-sleep-tip/` seeded after Phase-1 ship (README + metadata + changelog from this folder) — ✅ 2026-07-11 via `/spec-reverse-engineer`; updated for Phase 2 (CryDetector, `sleepTipMicEnabled`)

## Field dogfood

- [ ] Per-phase TestFlight build out; ≥ 3 real-nursery sessions logged before the next phase starts — TestFlight 28 out 2026-07-10; round-1 feedback folded back 2026-07-11 (see qa.md → Dogfood); sessions still accruing

## Release readiness

- [ ] Each phase = own branch + PR into `main` with unit tests + TestFlight build
- [ ] App Store: privacy label stays "Data Not Collected"; mic purpose string is the only new privacy surface (Phase 2)
- [x] No `<...>` placeholders or `TODO:` markers remain in the spec files — ✅ 2026-07-10 grep clean
