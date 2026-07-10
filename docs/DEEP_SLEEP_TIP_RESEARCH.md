# Deep-Sleep Tip — Research & Proposed Design

**Status:** research / pre-implementation
**Implementation plan:** [DEEP_SLEEP_TIP_PLAN.md](DEEP_SLEEP_TIP_PLAN.md)
**Feature idea:** while a parent settles the baby in their arms with the app open,
the light should *gently glow a few times* when the baby has probably reached deep
sleep — the cue to try putting them down. If the baby cries, the estimate resets.

Everything here is deliberately approximate. The goal is a better-than-guessing
nudge, not a medical device.

---

## 1. What the app already gives us

- `LightViewModel.elapsedSeconds` already counts up from the moment the app
  becomes active, and is rendered as the big on-screen timer. This *is* the
  settling timer — parents open the app when they start rocking/feeding.
- `Color.lightened(by:)` (used for the timer text) gives us a ready-made way to
  pulse the background subtly without touching hardware brightness.
- The app keeps the screen on (`isIdleTimerDisabled = true`) and stays
  foreground for the whole settling session — which is exactly the window where
  live microphone classification is allowed to run.

One catch: `handleAppDidBecomeActive()` resets `elapsedSeconds` on **every**
re-activation, so briefly checking a notification would restart the estimate.
The feature needs a slightly smarter "session" (see §5).

## 2. Sleep science: when can you put a baby down?

### Newborns (0–3 months)
- Newborns fall asleep into **active (REM) sleep** — twitching, grunting,
  irregular breathing — and only transition to **quiet (deep) sleep about
  20–30 minutes after sleep onset**. Sleep cycles are ~50–60 min, split roughly
  evenly between active and quiet sleep.
- This is why the classic advice is: **wait at least 20 minutes after they fall
  asleep** before attempting the transfer, then confirm with the **"limp-limb"
  test** (lift an arm — if it drops floppy, they're in deep sleep; resistance
  means light sleep).
- Transfers attempted during active sleep usually fail — the baby is easily
  roused.

### The 3–4 month transition
- Around 3–4 months sleep architecture matures into adult-like stages
  (N1/N2/N3 + REM). Sleep onsets are mostly REM until ~3 months, then
  progressively shift until they are **predominantly NREM from ~6 months on**.
- Practically: the window from falling asleep to "transferable" deep sleep
  **shrinks** as the baby ages.

### Older babies (6+ months)
- They enter sleep through NREM like adults and reach deep slow-wave sleep
  within roughly **10–15 minutes** of sleep onset.

### Sleep-onset latency (falling asleep itself)
- Typical time to fall asleep once settling starts is **10–20 minutes**
  (under ~10 min often means overtired; over ~30 min under/overtired).

### Putting it together — tip time measured from app open

Without the microphone the app can't know the moment of sleep onset, only the
moment settling started (app open). So the mic-less default tip time = settle
latency + onset→deep-sleep time (with the mic, cry cessation gives a much
tighter anchor — see §4):

| Baby age | Falling asleep | Sleep onset → deep sleep | **Default glow tip (from app open)** |
|---|---|---|---|
| 0–3 mo  | ~10–20 min | ~20–25 min | **~35 min** |
| 3–6 mo  | ~10–15 min | ~15–20 min | **~30 min** |
| 6–12 mo | ~10–15 min | ~10–15 min | **~25 min** |
| 12+ mo  | ~10–15 min | ~10 min    | **~20 min** |

Caveats to design around:
- Variance between babies (and between nights) is large. The number must be
  **user-adjustable** (e.g. ±5 min steps) and the glow should **repeat every
  ~5 min** a few times, because the first cue lands mid-range, not at a
  guaranteed moment.
- Real-world data point (our own 6-month-old): successful transfers often land
  **7–12 min after sleep onset** — right at the fast edge of the 6-month range,
  and consistent with the "20-minute rule" being a *newborn* rule that stops
  applying once sleep onset shifts to NREM. Two design consequences: the first
  glow should fire at the **early edge** of the age window (repeats cover the
  tail), and per-baby calibration (§7) matters more than nailing the population
  average.
- The descent into deep sleep is a probability curve, not a switch. Night-to-
  night shifts come from sleep pressure (bedtime after an active day → faster,
  deeper descent; a low-pressure nap → shallower), overtiredness, teething/
  illness/regressions, and the transfer itself (the tilt toward the mattress
  can trigger an arousal from lighter stages).
- The limp-limb test stays the ground truth. Tip copy should say "try the arm
  test", not "baby is in deep sleep".
- A future refinement (§7) lets the parent tap once when the baby actually
  falls asleep, anchoring the countdown to sleep onset instead of app open —
  more accurate, one extra interaction.

## 3. The glow tip

Requirements: visible to a parent glancing at the screen in a dark room,
invisible-ish to the baby, silent.

- **Pulse the background color's lightness**, not `UIScreen.brightness`:
  the user may have swiped hardware brightness near zero, and brightness writes
  are what we already fight with in lifecycle code. `lightened(by:)` on the
  current preset keeps the hue (red/amber science intact) and works at any
  hardware brightness.
- Shape: ~3 pulses, each ~1.5 s ease-in-out, raising lightness by ~10–15 %,
  then settle back. Repeat the triplet every ~5 min, max ~4 rounds, until:
  - the user acknowledges (any existing gesture — double-tap, or a light tap on
    the timer), or
  - a cry reset fires, or
  - the app is backgrounded.
- No sound, no phone haptics (the phone is usually lying on a surface; a buzz
  could be audible).
- **Apple Watch follow-up:** a silent wrist tap is the ideal channel for a
  parent holding a baby — the watch app already exists. Phase 3 (§7).

## 4. The microphone: detecting sleep onset + resetting on cries

### Cry cessation as the sleep-onset anchor

Many babies (ours included) cry or fuss right up until they drop off. That
makes **the end of the last crying bout** a much better sleep-onset marker
than app-open — it removes the fuzziest term (settle latency) from the
estimate entirely:

```
glow time = end of last crying bout + onset→deep-sleep window (age-based, §2)
          ≈ quiet + ~10 min for a 6-month-old
```

Mechanics:
- **Bout end** = no confirmed cry for ≥ ~2 min after a bout. The gap threshold
  matters: crying is naturally intermittent (breath pauses, brief lulls), so
  short silences must not end a bout prematurely. Tunable, start at 2 min.
- **Anchor hierarchy:** if the session had crying, anchor at the last bout
  end and use just the onset→deep window (early edge). If the baby settles
  quietly — some nights, some babies — fall back to the app-open anchor with
  the full default from §2. Both paths feed the same `SleepTipEngine`.
- **Reset-on-cry falls out for free:** a new confirmed bout simply moves the
  anchor forward. No separate reset feature needed.
- **Conservative failure direction:** a sleep-cry that survives the debounce
  (baby cries out but stays asleep) pushes the anchor — and the glow — later.
  Annoying but safe; the calibration loop (§6) absorbs it over time.
- Cry-stop isn't *exactly* sleep onset — some babies calm, then drift for a
  few minutes. That residual offset is precisely what per-baby calibration
  learns; with this anchor it's learning a small clean number instead of a
  large noisy one.
- Edge cases: a sibling crying nearby or crying on a TV would move the anchor
  (rare at 2am, acceptable); worth checking `knownClassifications` for usable
  "awake" signals like `baby_laughter` or babbling (parent speech makes the
  generic speech labels unreliable as an awake signal).

### Recommended: Apple's built-in sound classifier (on-device)

Apple's SoundAnalysis framework ships a built-in classifier
(`SNClassifySoundRequest(classifierIdentifier: .version1)`, iOS 15+; we target
iOS 26) that recognizes 300+ sounds **entirely on-device**, including a
dedicated **`baby_crying`** label (there's also `baby_laughter`). This is the
same tech behind iOS's accessibility "Sound Recognition → Crying Baby" feature.

Live-audio pipeline:

```
AVAudioEngine input tap → SNAudioStreamAnalyzer → SNClassifySoundRequest(.version1)
                                                   windowDuration ≈ 1.5–2 s, overlap 50 %
→ per-window results: (identifier, confidence)
→ debounce: cry confirmed only if confidence ≥ ~0.6 in ≥ 3 windows within ~10 s
```

**The debounce is the load-bearing part.** Newborn *active* sleep is full of
grunts, whimpers, and short squawks that do **not** mean "awake" — a single
noisy window must not reset the timer (that would reset constantly and make the
feature useless). Only sustained crying (~5–10 s) resets. Thresholds need
tuning with real-world audio; start conservative.

On confirmed cry:
- reset the deep-sleep countdown to zero (baby roused → estimate restarts),
- keep the visible elapsed timer semantics consistent (probably reset it too —
  it currently represents "this settling attempt").

### Practicalities

- **Permission:** needs `NSMicrophoneUsageDescription` + one-time mic prompt.
  If denied, the feature degrades gracefully: glow tip still works, reset is
  manual only.
- **Privacy:** classification is fully on-device; no audio is recorded, stored,
  or transmitted. App Store privacy label can stay **"Data Not Collected"**.
  Usage string should say exactly that ("listens locally for crying to reset
  the sleep timer; nothing is recorded or leaves the device").
- **The orange mic indicator dot** will show while listening — a small orange
  dot visible in a dark room. System-mandated, can't be hidden. Mitigation:
  only listen while the deep-sleep tip feature is enabled and a session is
  running; mention it in the feature's UI copy so it doesn't surprise anyone.
- **Battery/thermal:** negligible next to the always-on screen. Runs only while
  foreground (which is the app's whole use pattern anyway).
- **False negatives are fine** — a manual reset gesture (e.g. long-press the
  timer) backs it up. False *positives* are the thing to guard against, hence
  the sustained-cry rule and preferring the classifier over any dB threshold.

### Rejected alternative: loudness threshold

Simple audio metering (`AVAudioRecorder` peak power over a dB threshold) needs
no ML but can't tell crying from a white-noise machine, a parent's voice, a
door, or the baby's own active-sleep grunts. In a nursery, white noise is the
common case, not the edge case. Not worth shipping even as v1.

## 5. What the app needs (design sketch)

**Age input.** A one-time "baby's birth month" picker (stored in
`UserDefaults`, local only, optional). A birth date beats an age-bucket picker
because the defaults keep adjusting as the baby grows — set it once at 2 months
and the tip time is still right at 8 months. Bucket boundaries: 0–3, 3–6, 6–12,
12+ months.

**Session semantics.** Introduce a `SettlingSession` concept on top of
`elapsedSeconds`: a session survives brief resign-active gaps (< ~2–3 min, e.g.
checking a message) instead of resetting on every activation like today.
Session ends on long background, cry-reset, or manual reset.

**New components:**

| Component | Responsibility |
|---|---|
| `SleepTipEngine` | Pure state machine: `settling → tipDue → tipping(round n) → acknowledged`; inputs are elapsed time, age bucket, cry events, manual reset. No UI, no timers inside → unit-testable like `shouldPromptForReview`. |
| `CryDetector` | Wraps AVAudioEngine + SNAudioStreamAnalyzer; owns permission state, start/stop with scene phase, sustained-cry debounce and bout-gap tracking; emits `cryBoutStarted` / `cryBoutEnded` events (the latter is the sleep-onset anchor). |
| Glow pulse | A view modifier animating `lightened(by:)` on the background color, driven by `SleepTipEngine` state. |
| Controls UI | New "DEEP SLEEP TIP" section in `ControlsOverlay`: birth-month picker, on/off, tip-time fine-tune (±), cry-reset toggle (with mic permission flow). |

**Localization.** Every new string goes through the existing 26-locale pipeline
(`AppStore/LOCALIZATION.md`) — budget for it; the settings section adds maybe
6–8 strings plus the mic usage description.

## 6. Learning from patterns (per-baby calibration)

The cry detector doubles as a **free outcome label** for every session — no
extra taps needed:

- **"Too early" evidence:** a confirmed cry within ~5 min of a glow window
  (the parent likely attempted the transfer and it failed, or the baby wasn't
  deep yet).
- **"Success" evidence:** the session ends calmly — no cry after the glow, app
  backgrounded/closed later, or auto-off reached.

Per session, log locally (UserDefaults / small JSON, on-device only): baby age
that day, nap vs. night (by clock time), settle duration, glow time(s), cry
events with timestamps, outcome. That's ~30–60 labeled samples/month from
normal use — plenty to tune a single parameter.

Calibration rule (deliberately simple, no ML):

1. Start from the age-based default (§2).
2. Keep a rolling window of the last ~20 outcomes, **bucketed nap vs. night**
   (descent speed differs with sleep pressure) and **by anchor type**
   (cry-cessation vs. app-open, §4 — the two have different baselines).
3. Nudge the glow time with a slow EMA (α ≈ 0.2) toward the earliest
   *successful* attempt times, and later when "too early" outcomes cluster.
4. Bound the learned value to a sane window around the age default (e.g.
   ±10 min) and require ≥5 outcomes in a bucket before deviating at all.
5. Show the learned value in settings ("your baby: ~16 min, learned from 12
   nights") so it stays inspectable and overridable.

Failure modes to respect: cries have causes other than a failed transfer
(hunger, noise) — the EMA and outcome clustering absorb that noise; growth
spurts/regressions temporarily break the pattern — the rolling window ages old
data out naturally; and the age prior keeps drifting underneath as the birth
date advances, so the learned offset should be stored *relative* to the age
default, not as an absolute time.

Explicitly out of scope for now: inferring the exact transfer moment from
device motion (CoreMotion signature of standing up while holding the phone) —
interesting, speculative, revisit after Phase 2 ships real cry data.

## 7. Risks / open questions

- **Timing defaults are heuristics.** Ranges above come from parenting-science
  summaries of sleep-lab findings, not from a validated dataset. Adjustability
  + repeat pulses are the near-term mitigation; per-baby calibration (§6) is
  the durable one.
- **Does a cry mean full restart?** After a brief rousing, babies often return
  to sleep faster than from fully awake. V1 keeps it simple (full reset);
  worth revisiting with real usage.
- **Exact classifier labels** should be confirmed in code via
  `SNClassifySoundRequest(classifierIdentifier: .version1).knownClassifications`
  (expect `baby_crying`; consider also treating `crying_sobbing` as a match if
  present).
- **App Review:** mic + baby apps are common (baby monitors); the on-device,
  nothing-stored story is clean. No expected issues.

## 8. Suggested phasing

1. **Phase 1 — glow tip, no microphone.** Birth-month setting, session
   semantics, `SleepTipEngine`, glow pulses, manual reset gesture. Zero new
   permissions, ships fast, already better than guessing. Start logging
   session records locally from day one so calibration has history to work
   with when it arrives.
2. **Phase 2 — microphone: sleep-onset anchor + cry reset.** `CryDetector`
   with SoundAnalysis, mic permission flow, debounce + bout-gap tuning. Cry
   bout end re-anchors the countdown (§4); a new bout moves it forward, which
   *is* the reset. Cry events flow into the session log.
3. **Phase 3 — per-baby calibration (§6).** Learned glow offsets from session
   outcomes, nap/night buckets, "learned from N nights" display in settings.
4. **Phase 4 — refinements.** Watch wrist-tap tip; optional "baby just fell
   asleep" single tap to anchor the countdown at sleep onset; motion-based
   transfer detection experiment.

## Sources

- [Parenting Science — Baby sleep stages: active vs quiet sleep](https://parentingscience.com/baby-sleep-stages/)
- [Parenting Science — Newborn sleep patterns](https://parentingscience.com/newborn-sleep/)
- [Sleep Foundation — Infant sleep cycles vs adults](https://www.sleepfoundation.org/baby-sleep/baby-sleep-cycle)
- [Karger, Annals of Nutrition & Metabolism — Sleep and Early Brain Development](https://karger.com/anm/article/75/Suppl.%201/44/42656/Sleep-and-Early-Brain-Development)
- [ISSR — Normal sleep architecture in infants and children](https://issr.in/normal-sleep-architecture-in-infants-and-children/)
- [Ask Dr. Sears — 8 infant sleep facts (limp-limb sign, ~20 min to deep sleep)](https://www.askdrsears.com/topics/health-concerns/sleep-problems/8-infant-sleep-facts-every-parent-should-know/)
- [Hey Sleepy Baby — Sleep latency](https://heysleepybaby.com/sleep-latency/)
- [Apple — SoundAnalysis framework](https://developer.apple.com/documentation/soundanalysis/)
- [Apple — SNClassifySoundRequest](https://developer.apple.com/documentation/soundanalysis/snclassifysoundrequest)
- [Apple — Classifying live audio with the built-in sound classifier](https://developer.apple.com/documentation/SoundAnalysis/classifying-live-audio-input-with-a-built-in-sound-classifier)
- [WWDC21 — Discover built-in sound classification in SoundAnalysis](https://developer.apple.com/videos/play/wwdc2021/10036/)
- [Swiftjective-C — the 300-sound built-in model (includes `baby_crying`)](https://www.swiftjectivec.com/sound-analysis-framework-built-in-model/)
- [Apple Support — Sound Recognition accessibility feature (crying baby)](https://support.apple.com/guide/iphone/use-sound-recognition-iphf2dc33312/ios)
