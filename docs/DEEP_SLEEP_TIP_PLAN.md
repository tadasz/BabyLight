# Deep-Sleep Tip — Implementation Plan

**Status:** proposed, for review
**Companion doc:** [DEEP_SLEEP_TIP_RESEARCH.md](DEEP_SLEEP_TIP_RESEARCH.md) (science + option analysis)

## Feature summary

While a parent settles the baby with the app open, the light gently pulses a
few times when the baby has likely reached deep sleep — the cue to try the
put-down (and the limp-limb test). The estimate is anchored to **when the baby
stopped crying** (detected on-device via the microphone) when possible, falls
back to app-open otherwise, is **age-based** via a one-time birth-month
setting, and **calibrates itself per baby** from session outcomes. A new
crying bout moves the anchor forward — which is also the reset.

Design principles, in priority order:
1. Never wake the baby (no sound, no phone haptics, subtle light changes only).
2. Zero required interaction during a settling session.
3. Everything on-device; App Store privacy label stays "Data Not Collected".
4. Honest approximation: the glow means "worth trying now", never "asleep now".

---

## Timing model

```
tip time = anchor + window(ageBucket, anchorKind) + learnedOffset(bucket) + userFineTune
```

- **Anchor** (per session, later events override earlier ones):
  1. `cryCessation` — end of last confirmed crying bout (mic enabled). A new
     bout clears any pending/shown tip and re-arms from its own end.
  2. `appOpen` — session start fallback (mic off/denied, or no crying).
- **Windows** (early edge of researched range; repeats cover the tail):

| Age bucket | from `appOpen` | from `cryCessation` |
|---|---|---|
| 0–3 mo   | 35 min | 20 min |
| 3–6 mo   | 30 min | 15 min |
| 6–12 mo  | 25 min | 10 min |
| 12+ mo   | 20 min | 10 min |

- **Repeat:** re-glow every 5 min, max 4 rounds, until acknowledged / reset /
  new cry bout / app backgrounded.
- **userFineTune:** persistent stepper, −10…+10 min.
- **learnedOffset:** see Calibration below; 0 until enough data.

## Session model

A `SettlingSession` starts when the app becomes active with the feature on.
It **survives interruptions shorter than 3 min** (checking a message must not
restart the estimate — today `elapsedSeconds` resets on every activation).
It ends on: background > 3 min, auto-off timer reaching 0, or manual reset.

The on-screen elapsed timer switches from "time since app open" to "time since
session start" (identical except across short interruptions). Manual reset:
**long-press (0.6 s) on the timer** — starts a fresh session, also the backup
when a cry goes undetected.

Each session appends one local log record (capped ring buffer, ~100 records,
JSON in Application Support): date, age (months), nap/night (by clock hour),
anchor kind + time, glow times, cry bouts, acknowledge time, outcome, session
end reason. This starts in Phase 1 so calibration has history when it ships.

## Cry detection (Phase 2)

- `SNClassifySoundRequest(classifierIdentifier: .version1)` on an
  `AVAudioEngine` mic tap via `SNAudioStreamAnalyzer`; runs only while a
  session is active and the toggle is on. Match `baby_crying` (verify exact
  ids via `knownClassifications` at integration time; treat `crying_sobbing`
  as a match too if present).
- Tunable constants (single config struct): window 1.5 s, 50 % overlap,
  confidence ≥ 0.6; **bout confirmed** = ≥ 3 positive windows within 10 s;
  **bout ended** = 120 s with no positive window (breath pauses and lulls must
  not end a bout).
- Debounce rationale: active sleep is full of grunts/squawks — single noisy
  windows must never move the anchor.
- Permission: `NSMicrophoneUsageDescription` ("listens locally for crying to
  time the sleep tip; nothing is recorded or leaves the device"), localized.
  Denied → anchor falls back to `appOpen`, everything else works.
- Known trade-off: iOS shows the orange mic indicator while listening;
  disclosed in the settings copy.

## Calibration (Phase 3)

- Outcome labels come free from the cry detector: cry bout within 5 min after
  a glow → "too early"; session ends calmly after a glow → "success".
- Buckets: nap vs. night × anchor kind. Per bucket: EMA (α = 0.2) of an
  offset **relative to the age default** (so it stays valid as the baby ages),
  clamped to ±10 min, applied only after ≥ 5 outcomes in that bucket, rolling
  window ~20 outcomes (regressions age out naturally).
- Surfaced in settings: "Your baby: ~16 min after quiet · learned from 12
  nights", with a reset-learning button.

## Components & file layout

| File (new unless noted) | Contents |
|---|---|
| `Baby Light/SleepTip/SleepTipEngine.swift` | Pure state machine: `idle → settling → tipDue(round) → acknowledged`, driven by injected clock ticks + events (`sessionStarted`, `wentInactive/BecameActive`, `cryBoutConfirmed/Ended`, `acknowledged`, `manualReset`). No timers, no UI → unit-testable. |
| `Baby Light/SleepTip/BabyProfile.swift` | Birth month storage, age-bucket + window lookup. |
| `Baby Light/SleepTip/SessionLog.swift` | Session record model + ring-buffer persistence. |
| `Baby Light/SleepTip/CryDetector.swift` | AVAudioEngine + SNAudioStreamAnalyzer wrapper, permission state, bout logic; emits bout events. (Phase 2) |
| `Baby Light/SleepTip/Calibration.swift` | Bucketed EMA offsets from session log. (Phase 3) |
| `Baby Light/GlowPulse.swift` | ViewModifier animating `lightened(by:)` on the light color: 3 pulses × ~1.5 s, +12 % lightness. |
| `LightViewModel.swift` (edit) | Owns engine/detector; scene-phase handlers gain session semantics. |
| `ContentView.swift` (edit) | Glow modifier; tap-to-acknowledge while tipping; long-press reset. |
| `ControlsOverlay.swift` (edit) | New "DEEP SLEEP TIP" section: on/off, birth-month picker, fine-tune stepper, mic toggle, learned-value caption. |
| `Baby LightTests/…` | Engine, bout-logic, and calibration tests (simulated clock). |

Gesture care: single-tap acknowledge is active **only while pulsing** so it
can't fight the double-tap (controls) or drag (brightness) gestures;
long-press coexists with drags via `simultaneousGesture` — verify on device.

## Phases, deliverables, acceptance

**Phase 1 — glow tip, no microphone** (ships alone)
- Birth-month setting, session semantics, engine, glow, long-press reset,
  session logging, settings UI, localization of new strings.
- Accept: opening the app starts a session; glow fires at the age default ±
  fine-tune; re-glows every 5 min ≤ 4×; tap acknowledges; brief app switch
  doesn't reset; feature off → app behaves exactly as today.

**Phase 2 — microphone: sleep-onset anchor + cry reset**
- CryDetector, permission flow, anchor switching, orange-dot disclosure copy.
- Accept: sustained crying → quiet re-anchors the countdown (e.g. 6–12 mo →
  glow ~10 min after quiet); grunts/short squawks don't; new bout cancels a
  shown tip and re-arms; denied permission degrades to Phase 1 behavior.

**Phase 3 — per-baby calibration**
- Calibration.swift, learned-value display, reset-learning control.
- Accept: with ≥ 5 logged outcomes in a bucket the glow shifts toward the
  baby's observed successful times, never beyond ±10 min of the age default.

**Phase 4 — refinements** (separate proposals)
- Watch wrist-tap tip via WatchConnectivity; optional "fell asleep" tap
  anchor; CoreMotion transfer-detection experiment.

Each phase = its own branch + PR into `main`, with unit tests and a TestFlight
build; real-nursery feedback between phases feeds the tunable constants.

## Testing

- Unit: engine timing/rounds/interruption rules; bout confirm/end debounce
  (scripted classifier events); calibration math (cold start, clamps, aging).
- Manual protocol: real settling sessions (that's us); white-noise machine
  running; speech near phone; brightness-at-zero glow visibility check.
- UI tests: settings section appears, feature-off parity with current app.

## Localization & release

- ~10 new strings + mic usage description through the existing 26-locale
  pipeline (`AppStore/LOCALIZATION.md`); release notes + screenshot of the new
  controls section per locale (existing screenshot tooling).
- App Store: privacy label unchanged ("Data Not Collected"); mic purpose
  string is the only new privacy surface.

## Out of scope (explicitly)

- Cloud sync, accounts, analytics on baby data — everything stays on device.
- Medical claims — copy always frames the glow as "a good moment to try".
- Custom ML models — Apple's built-in classifier only.
