# Deep-sleep tip

## What it is

An **optional, off-by-default** helper for the put-down. When a parent enables it, the app runs a
"settling session" from the moment the light opens, and at the age-appropriate moment when the baby
is likely to have reached deep sleep the **light itself briefly breathes brighter** — a gentle glow
that says "this is a good moment to try laying the baby down." A single tap on the light dismisses
the glow; holding the light restarts the timing if the put-down failed. Nothing plays a sound or
buzzes, and the glow returns the screen to the exact previous darkness.

Phase 1 (the app-open timing, the glow cue, the settings, and an on-device session log) is shipped.
Phase 2 (mic-driven cry detection that re-anchors the timing to the end of a crying bout) and
Phase 3 (per-baby calibration that nudges the glow toward the times that actually worked) are both
**built and unit-tested**. Phase 2 awaits on-device verification; Phase 3's constants await tuning
against real nursery data. See [Open debts](#open-debts).

## Where it lives

Own files (this feature only):

- [`Baby Light/SleepTip/BabyProfile.swift`](../../../Baby%20Light/SleepTip/BabyProfile.swift) —
  age buckets, the deep-sleep window lookup table, birth-month persistence. All pure static
  functions.
- [`Baby Light/SleepTip/SleepTipEngine.swift`](../../../Baby%20Light/SleepTip/SleepTipEngine.swift)
  — the pure, clock-driven state machine (`idle → settling → tipDue → acknowledged`) that decides
  *when to glow*, *when to re-arm*, and remembers what happened. No timers, no UI.
- [`Baby Light/SleepTip/SessionLog.swift`](../../../Baby%20Light/SleepTip/SessionLog.swift) — the
  `SessionRecord` value type and its ring-buffer JSON persistence.
- [`Baby Light/SleepTip/CryDetector.swift`](../../../Baby%20Light/SleepTip/CryDetector.swift) — the
  pure `CryBoutTracker` debounce core plus the `AVAudioEngine`/`SoundAnalysis` mic wrapper (Phase 2).
- [`Baby Light/SleepTip/Calibration.swift`](../../../Baby%20Light/SleepTip/Calibration.swift) — the
  pure per-baby learned-offset math: outcome labelling from cry timing, bucketed EMA, clamp/gate/window
  (Phase 3).
- [`Baby Light/GlowPulse.swift`](../../../Baby%20Light/GlowPulse.swift) — the visual cue: a
  `ViewModifier` that plays three ease-in-out pulses of the current color lightened toward white.

Shared files (this feature is wired in alongside the rest of the app):

- [`Baby Light/LightViewModel.swift`](../../../Baby%20Light/LightViewModel.swift) → the
  `// MARK: - Deep Sleep Tip` section: settings, session lifecycle, the per-tick engine drive
  inside `startElapsedTimer()`, and outcome labeling.
- [`Baby Light/ContentView.swift`](../../../Baby%20Light/ContentView.swift) → the `GlowPulse`
  modifier on the light background plus the tap-to-acknowledge and long-press-to-reset gestures.
- [`Baby Light/ControlsOverlay.swift`](../../../Baby%20Light/ControlsOverlay.swift) → the
  "DEEP SLEEP TIP" settings section and the `FineTuneStepper`.

## Key entry points

A new spec touching this feature is most likely to work through the view model:

- `beginSettlingSession(at:)` / `endSettlingSession(reason:)` — session start/stop; the latter
  writes one `SessionRecord` ([LightViewModel.swift:288, :300](../../../Baby%20Light/LightViewModel.swift)).
- `applySettlingSessionActivation(now:)` + `settlingSessionAction(now:sessionStart:resignedAt:)` —
  what a foreground activation does (start / resume / restart), the interruption rule
  ([LightViewModel.swift:279, :354](../../../Baby%20Light/LightViewModel.swift)).
- `startElapsedTimer()` — the 1 Hz tick that both drives the elapsed readout from `sessionStart`
  and advances the engine, bumping `glowCount` when a round fires
  ([LightViewModel.swift:143](../../../Baby%20Light/LightViewModel.swift)).
- `acknowledgeSleepTip(at:)`, `resetSettlingSession(at:)`, `adjustFineTune(by:now:)` — the three
  user actions ([LightViewModel.swift:246, :322, :225](../../../Baby%20Light/LightViewModel.swift)).
- `SleepTipEngine.nextGlowTime` / `tick(now:)` / `acknowledge(at:)` — the timing math itself
  ([SleepTipEngine.swift:60, :92, :107](../../../Baby%20Light/SleepTip/SleepTipEngine.swift)).
- `BabyProfile.windowMinutes(for:anchor:)` — the age-window table
  ([BabyProfile.swift:42](../../../Baby%20Light/SleepTip/BabyProfile.swift)).

## State & persistence

Persisted `UserDefaults` keys (all permanent API — never rename, `specs/patterns.md` §4):

| Key | Type | Meaning |
|---|---|---|
| `sleepTipEnabled` | Bool | Feature on/off (default off) |
| `sleepTipMicEnabled` | Bool | Cry-listening on/off (Phase 2, default off) |
| `sleepTipFineTune` | Int | Parent's −10…+10 minute offset |
| `sleepTipBirthMonth` | Date | Baby's birth month (via `BabyProfile`, [BabyProfile.swift:70](../../../Baby%20Light/SleepTip/BabyProfile.swift)) |
| `sleepTipLearningResetDate` | Date | Calibration cutoff — sessions before it are ignored (Phase 3, unset by default) |

One file on disk — an **owner-approved deviation** from the app's no-files rule
(`specs/patterns.md` §4, `specs/tech-stack.md` → UserDefaults):
`Application Support/DeepSleepTip/sessions.json`, a JSON **ring buffer capped at 100 records**,
owned by `SessionLog` ([SessionLog.swift:61](../../../Baby%20Light/SleepTip/SessionLog.swift)).
Writes are best-effort: failures are swallowed so a full disk can never take the night light down
([SessionLog.swift:89](../../../Baby%20Light/SleepTip/SessionLog.swift)). Records never leave the
device.

## Dependencies

- **Relies on** the [light-screen](../light-screen/) (the glow overlays its color; the elapsed
  timer readout derives from `sessionStart` while a session runs), the
  [controls-overlay](../controls-overlay/) (hosts the settings), and the
  [auto-off-timer](../auto-off-timer/) (auto-off reaching zero ends the session with
  `endReason: .autoOff`, [LightViewModel.swift:450](../../../Baby%20Light/LightViewModel.swift)).
- **Interacts with** the [feed-timer](../feed-timer/) elapsed readout — with a session running the
  readout counts from `sessionStart` rather than by ticks, so it stays correct across short
  interruptions.

## Invariants

Future specs must not break these (see also `specs/patterns.md` §1):

- **Off = zero behavioral delta (AC4).** With `sleepTipEnabled` false, `sessionStart` stays nil and
  the elapsed timer counts ticks exactly as before — every code path of this feature is inert
  ([LightViewModel.swift:161](../../../Baby%20Light/LightViewModel.swift)).
- **The glow is rendering-only brightening**, via `Color.lightened(by:)`, never
  `UIScreen.brightness` — so it is visible with hardware brightness near zero, stays out of the
  lifecycle brightness handling, and honors "Dark is sacred"
  ([GlowPulse.swift:8](../../../Baby%20Light/GlowPulse.swift)). No sound, no haptics; the cue ends
  at the exact previous darkness.
- **A single tap acknowledges only while a glow is pulsing** (`pulseDuration` ≈ 4.5 s); the rest of
  the time the tap gesture is inert and never interferes with the double-tap controls toggle
  ([SleepTipEngine.swift:107](../../../Baby%20Light/SleepTip/SleepTipEngine.swift),
  [ContentView.swift:120](../../../Baby%20Light/ContentView.swift)).
- **Conservative-by-default timing.** The window table is the *early edge* of the researched
  deep-sleep ranges, with repeat rounds covering the tail
  ([BabyProfile.swift:42](../../../Baby%20Light/SleepTip/BabyProfile.swift)); an unset birthday
  seeds the newborn bucket (longest window), so the app errs toward glowing *later*, never earlier
  ([LightViewModel.swift:184](../../../Baby%20Light/LightViewModel.swift)).
- **One tick advances at most one glow round**, so a long suspension can never burst several glows
  at once ([SleepTipEngine.swift:92](../../../Baby%20Light/SleepTip/SleepTipEngine.swift)).
- **The engine is pure and clock-fed.** All timing rules take an injected `now`, so they are
  unit-tested with simulated dates — keep new timing logic in the engine, not the view model.
- **The 0.6 s toggle-suppression window** (`controlToggleSuppressWindow`): a double-tap-to-hide
  arriving right after a fine-tune −/+ tap is ignored, so rapid stepper taps aren't mis-read as the
  toggle gesture ([LightViewModel.swift:221, :481](../../../Baby%20Light/LightViewModel.swift)).
- **Accessibility identifiers are API** for `Baby LightUITests/`: `sleepTipToggle`,
  `sleepTipBirthMonthPicker`, `sleepTipFineTuneMinus`, `sleepTipFineTunePlus`, `deepSleepTipSection`
  ([ControlsOverlay.swift](../../../Baby%20Light/ControlsOverlay.swift)).
- **The session log is best-effort evidence**, never load-bearing — nothing in the light path may
  depend on a successful write.

## Testing

Extensive unit coverage in
[`Baby LightTests/SleepTipTests.swift`](../../../Baby%20LightTests/SleepTipTests.swift): the age
buckets and window table (`BabyProfileTests`), the interruption rule and session lifecycle
(`SettlingSessionRuleTests`, `SettlingSessionLifecycleTests`), the timing state machine
(`SleepTipEngineTests` — glow timing, repeat rounds, acknowledge, cry-anchor re-arming), the ring
buffer (`SessionLogTests`), and outcome labeling (`SessionOutcomeTests`). The cry-anchor tests
(`cryBoutOverridesAnchor`, `newBoutClearsShownTipAndReArms`) already pass against dormant code.

## Open debts

- **Phase 2 — CryDetector (built; on-device verification pending).**
  [`CryDetector.swift`](../../../Baby%20Light/SleepTip/CryDetector.swift) now feeds the engine's
  cry-anchor path: an `AVAudioEngine` mic tap → `SNAudioStreamAnalyzer` →
  `SNClassifySoundRequest(.version1)`, with all debounce logic in a pure, unit-tested
  `CryBoutTracker` (≥ 3 positive windows in 10 s confirms a bout; 120 s of quiet ends it). It runs
  only while a session is active and `sleepTipMicEnabled` is on; permission denial is a silent
  fallback to the app-open anchor; confirmed bouts are logged to `SessionRecord.cryBouts`. The new
  strings are localized into all 26 locales (`InfoPlist.xcstrings` for the mic permission), and the
  constitution edits (SoundAnalysis/AVFoundation in `specs/tech-stack.md`, off-main callbacks in
  `specs/patterns.md` §8) are applied. **Still open before Phase-2 ships:** on-device verification
  of the live mic (exact `knownClassifications` labels, gesture/audio coexistence, permission-denied
  fallback — QA-3), and re-confirming the "Data Not Collected" privacy label at ASC submission
  (`PrivacyInfo.xcprivacy` assessed as not newly required).
- **Phase 3 — calibration (built; constants un-tuned).**
  [`Calibration.swift`](../../../Baby%20Light/SleepTip/Calibration.swift) reads the session log and
  produces a per-baby learned offset (bucketed by nap/night × anchorKind, EMA α=0.2 relative to the
  age default, ±10 clamp, ≥5-outcome gate, ~20 rolling window). The view model applies it at session
  start (app-open bucket) and swaps to the cry-cessation bucket when the anchor switches; the settings
  section shows a "learned from N nights" caption with a non-destructive **Reset**
  (`sleepTipLearningResetDate` — the raw log is kept for the success measurement). **Still open:** the
  constants (α, gate, window, the too-early nudge) and the outcome-labelling thresholds are set from
  the research doc and want tuning against real nursery data before they can be trusted; the
  learned-value caption's live appearance is gated behind ≥5 real logged nights.
- **`sessionOutcome(...)` is a mic-less projection**: a glow then a calm background end reads as
  `success`, a glow then a manual reset as `tooEarly`, everything else honest `unknown` — a
  placeholder for the Phase-3 calibration signal
  ([LightViewModel.swift:333](../../../Baby%20Light/LightViewModel.swift)).
- **`SessionRecord.cryBouts` is always `[]`** in Phase 1 (no detector to populate it,
  [LightViewModel.swift:309](../../../Baby%20Light/LightViewModel.swift)).

> **This README was reverse-engineered from the shipped code** and is a strong draft, not ground
> truth — the owner should confirm it against their own knowledge of the feature. Run
> `/spec-audit deep-sleep-tip` as the ongoing drift guard.
