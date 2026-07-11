# 2026-07-10-deep-sleep-tip — QA script

Tiers (adapted for BabyLight — no local/develop/staging envs exist there): `sim` (Xcode simulator / unit-test harness with simulated clock + scripted classifier events; ≈ `local`) · `device` (TestFlight build on a physical iPhone; ≈ `develop`) · `nursery` (real settling session, dark room, white-noise machine; ≈ `staging-only` — real-world audio + a real baby can't be simulated pre-merge).

## QA-G — Goal demo (P1) — cites: Success outcome, US-1 — tier: sim

Preconditions: feature toggled on; birthday set to a 6–12 mo age; fine-tune 0; simulated clock injected (engine test harness or a debug time-scale flag — plan task 2.1's injected clock is the recipe).

1. Activate the app → expect: settling session starts; on-screen timer counts from session start.
2. Advance clock 24 min → expect: no glow yet (window is 25 min for 6–12 mo from `appOpen`).
3. Advance to 25 min → expect: background pulses 3 × ~1.5 s, ~+12 % lightness, hue unchanged; no sound.
4. Ignore it; advance 5 min → expect: re-glow (round 2 of max 4).
5. Single-tap the light while pulsing (anywhere — the timer text doesn't hit-test) → expect: pulsing stops; tapping again (not pulsing) does nothing.
6. End the session (background > 3 min, simulated) → expect: one new record in the session log with `anchorKind=appOpen`, non-empty `glowTimes`, `acknowledgeTime` set, `endReason=background` — inspect via the harness assertion (sim) or the app container's Application Support JSON (`xcrun simctl get_app_container` on simulator).

## QA-1 — Interruption semantics — cites: AC3 (US-1) — tier: sim

Preconditions: as QA-G, session running at ~10 min.

1. Resign active for 2 min, reactivate → expect: timer shows ~12 min, estimate un-reset.
2. Resign active for 4 min, reactivate → expect: previous session ended (logged), fresh session started at 0.
3. Long-press the light 0.6 s → expect: fresh session; previous one logged with `endReason=manualReset`.

## QA-2 — Cry-anchored timing — cites: AC6, AC7 (US-2) — tier: sim

Preconditions: QA-G setup + mic toggle on; scripted classifier events fed to the detector (plan task 4.6's scripted-events recipe — no real audio needed).

1. Script a sustained bout (≥ 3 windows ≥ 0.6 confidence within 10 s) at minute 5, silence from minute 8 → expect: bout ends at minute 10 (120 s gap); countdown re-anchors — glow due ~minute 20 (10 min cry-cessation window for 6–12 mo), not minute 25.
2. Script one isolated positive window ("squawk") at minute 12 → expect: anchor unchanged.
3. Let the glow fire, then script a new sustained bout → expect: pulsing stops, tip cleared, engine re-armed from the new bout's end.

## QA-3 — Mic denied fallback — cites: AC8 (US-2) — tier: device

Preconditions: TestFlight build; iOS Settings → Privacy → Microphone → Baby Light off (or deny at first prompt).

1. Enable the mic toggle in the app → expect: settings copy discloses the orange indicator dot; no crash, no re-prompt loop.
2. Run a session → expect: glow fires from the `appOpen` anchor at the full age window; everything else behaves as QA-G.

## QA-4 — Calibration — cites: AC9 (US-3) — tier: sim

Preconditions: seeded session log with 5 `success` outcomes clustered ~4 min earlier than the age default, same (night × cryCessation) bucket (unit-test fixture — plan task 5.3's recipe).

1. Run a session in that bucket → expect: glow shifts toward the observed times, never > 10 min from the age default.
2. Seed a 6th outcome `tooEarly` → expect: next glow nudges later (EMA, not a jump).
3. Open settings → expect: learned caption ("~N min … learned from 6 nights"); tap reset-learning → expect: offset back to 0, caption cleared.
4. With only 4 outcomes in a fresh bucket → expect: no deviation from the age default (≥ 5 gate).

## QA-5 — Nursery reality check — cites: Success outcome, AC4, AC10 — tier: nursery

Preconditions: Phase-1 (later Phase-2) TestFlight on the nightstand phone; hardware brightness near zero; white-noise machine on; real settling session.

1. Settle as usual with the feature on → expect: glow is noticeable to a glancing adult, doesn't visibly disturb the baby.
2. (Phase 2) Baby fusses then quiets → expect: glow lands ~cry-cessation window after quiet; white noise alone never confirms a bout.
3. Toggle the feature off next session → expect: app indistinguishable from the shipped build (AC4).
4. After ≥ 3 sessions → expect: log records match what actually happened (outcomes plausible) — the Success-outcome evidence stream is real.

Dry-run: 2026-07-10 — 2 findings folded into spec (AC5's log-inspection path had no recipe → added to QA-G step 6 + preconditions now name the injected-clock/scripted-events harness recipes from plan tasks 2.1/4.6/5.3; journey step 8's "learned from N nights" observation is Phase-3-only → journey re-scoped to the log record itself, learned caption moved to QA-4).

Dogfood round 2: 2026-07-11 (TestFlight 28/29, iOS 26.5) — birthday picker + fine-tune stepper were dead to taps on 26.5 while every other control worked. Root cause: a zero-distance drag `simultaneousGesture` on the light surface (present since v1.0, to seed the swipe-brightness origin) won touch-down against the two UIKit-backed controls on 26.5. Fix: removed the seeder; the brightness drag reads its origin from `value.startLocation`. Verified by real single-tap UI tests on an erased 26.5 simulator + full suite on 26.2. (The double-tap-to-open XCUITest path is separately flaky on the 26.5 simulator — a harness quirk, not an app bug; the pre-existing `testDoubleTapHidesControlsOverlay` fails there too.)

Dogfood: 2026-07-11 (TestFlight 28) — picker/stepper taps swallowed by the ancestor long-press → gestures now masked while controls are open (regression UI test added); birth month → birthday; "Fine-tune timing" relabeled + live "glows about N min" caption added so the logic explains itself.

Port review: 2026-07-10 (BabyLight PR #21) — tap/long-press steps retargeted from "the timer" to the light surface: the timer text has `allowsHitTesting(false)` (`ContentView.swift:61`), so gestures land on the light, not the text.
