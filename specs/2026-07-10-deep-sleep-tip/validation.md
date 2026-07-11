# 2026-07-10-deep-sleep-tip — Validation

Merge gate per phase PR: every box relevant to the phase ticked = ready for `main`.

## Success outcome — did this actually work?

- [ ] Outcome restated: first glow lands inside the successful-transfer window in most real-nursery sessions; glow-timed put-downs beat pre-feature guessing.
- [ ] Measurement plan: on-device session log (outcome field) + parent-reported nursery protocol — owner: Tadas, due: ~3 weeks after Phase-1 TestFlight.

## Acceptance criteria — verification

- [ ] AC1 (US-1, P1) glow at age window ± fine-tune — verify by: engine unit tests (simulated clock, all four buckets)
- [ ] AC2 (US-1, P1) repeat 5 min × ≤ 4, acknowledge only while pulsing — verify by: engine unit tests + manual QA-G
- [ ] AC3 (US-1, P1) session survives < 3 min interruptions — verify by: session unit tests + QA-1
- [ ] AC4 (US-1, P1) feature-off parity — verify by: UI test (XCTest) feature-off behavior parity
- [ ] AC5 (US-1, P1) one log record per session — verify by: SessionLog unit tests (shape + ring cap) + QA-G step 6
- [ ] AC6 (US-2, P2) cry-cessation re-anchor; grunts never move anchor — verify by: bout-debounce unit tests (scripted classifier events) + QA-2
- [ ] AC7 (US-2, P2) new bout clears tip, re-arms — verify by: engine unit tests + QA-2
- [ ] AC8 (US-2, P2) mic-denied fallback + orange-dot disclosure — verify by: unit test (permission state) + QA-3
- [ ] AC9 (US-3, P3) calibration shift, ±10 clamp, ≥ 5 gate, reset control — verify by: calibration unit tests + QA-4
- [ ] AC10 (US-1, P1) strings localized, privacy label unchanged — verify by: xcstrings diff covers all new keys (26 locales); App Store Connect privacy section review

## UI coverage

XCTest UI tests: settings section appears (plan task 3.5); feature-off parity (AC4). Everything else is engine-level unit tests by design (pure state machine, injected clock — no UI needed to verify timing).

## Data model — schema verification

- [ ] Log record matches the pinned field table — verify by: SessionLog encode/decode round-trip test
- [ ] Invariants hold (relative offset, ±10 clamp, ≥ 5 gate, ~20 window, on-device only) — verify by: calibration unit tests; no networking code in `SleepTip/`

## Automated checks

- [ ] Test suite green per phase PR (`xcodebuild test`; simulated-clock determinism — no wall-clock waits)
- [ ] No new dependencies — Apple frameworks only (SoundAnalysis, AVFoundation are system-provided); anything else re-opens Decisions

## Manual QA

- [ ] App boots clean with feature off (parity with shipped build)
- [ ] QA-G (sim) — goal demo, simulated clock
- [ ] QA-1 (sim) — interruption semantics
- [ ] QA-2 (sim) — cry anchor + debounce (scripted events)
- [ ] QA-3 (device) — mic-permission denial fallback
- [ ] QA-4 (sim) — calibration math + reset
- [ ] QA-5 (nursery) — real settling session: glow visible at near-zero hardware brightness, white-noise machine running, orange dot acknowledged

## Non-regression

- [ ] Existing flows still work: double-tap opens controls, drag adjusts brightness, auto-off timer; first-run tutorial (TipKit, `Tips.swift` — its step-2 tip anchors on the timer text) and rating-prompt gating (`LightViewModel.maybeRequestReview()`) untouched
- [ ] Diff stayed within **Edit surface & blast radius**; overflow surfaced as a separate ticket
- [ ] Feature off → zero behavioral delta (AC4 is the regression gate)

## Touched feature folders

- [ ] README + changelog updated in the same PR as the behaviour change (requirements → Touches features): feed-timer, light-screen, controls-overlay, auto-off-timer, first-run-tutorial (per phase, as touched)
- [ ] Constitution amendments landed with the code that motivates them: `specs/patterns.md` §4 SessionLog file exception (Phase 1); `specs/tech-stack.md` frameworks + patterns §8 concurrency (Phase 2)
- [ ] `specs/features/deep-sleep-tip/` seeded after Phase-1 ship (README + metadata + changelog from this folder)

## Field dogfood

- [ ] Per-phase TestFlight build out; ≥ 3 real-nursery sessions logged before the next phase starts

## Release readiness

- [ ] Each phase = own branch + PR into `main` with unit tests + TestFlight build
- [ ] App Store: privacy label stays "Data Not Collected"; mic purpose string is the only new privacy surface (Phase 2)
- [ ] No `<...>` placeholders or `TODO:` markers remain in the spec files
