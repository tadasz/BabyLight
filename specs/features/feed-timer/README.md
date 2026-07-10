# Feed timer

## What it is

A large count-up clock shown over the night light so a parent can glance at how long the current feeding (or settling) session has been going. It starts automatically when the app opens, resets automatically on every re-open, and needs no interaction at all.

Naming note: the iOS code and UI call it the "elapsed timer" (`ELAPSED TIMER` section, `elapsedSeconds`); the watch code calls the same thing the "feed timer" ([WatchContentView.swift:30](../../../Baby%20Light%20Watch%20App/WatchContentView.swift), [BabyLightWatchApp.swift:6-7](../../../Baby%20Light%20Watch%20App/BabyLightWatchApp.swift)). They are the same capability.

## Where it lives

**iOS** (`Baby Night Light` target):

- [Baby Light/LightViewModel.swift](../../../Baby%20Light/LightViewModel.swift) — the counter (`elapsedSeconds`, line 20), the driving timer (`startElapsedTimer()`, lines 125–131), the display formatter (`formatTime(_:)`, lines 200–211), and the persisted text-visibility setting (`timerLightness`, lines 37–39).
- [Baby Light/ContentView.swift](../../../Baby%20Light/ContentView.swift) — the on-light display (lines 46–60) and the scene-phase wiring that resets the counter on activation (lines 147–149).
- [Baby Light/ControlsOverlay.swift](../../../Baby%20Light/ControlsOverlay.swift) — the "ELAPSED TIMER" brightness slider with live preview (lines 95–118).

**watchOS** (`Baby Light Watch App` target) — its **own, deliberately duplicated** implementation (no shared framework, per [specs/patterns.md](../../patterns.md) §3):

- [Baby Light Watch App/WatchContentView.swift](../../../Baby%20Light%20Watch%20App/WatchContentView.swift) — `@State elapsed` (line 31), a `Timer.publish(every: 1)` tick (lines 37, 76), the duplicated formatter `timeString` (lines 87–91), and the 44 pt display (lines 52–55).

## Key entry points

### Start / reset (iOS)

There is **no user-facing start/stop/reset control**. The lifecycle is fully automatic:

- `LightViewModel.startElapsedTimer()` ([LightViewModel.swift:125-131](../../../Baby%20Light/LightViewModel.swift)) invalidates any previous timer, zeroes `elapsedSeconds`, and schedules a 1-second repeating `Timer` with a `[weak self]` closure (house timer pattern, `patterns.md` §8).
- Called from `init()` ([LightViewModel.swift:119](../../../Baby%20Light/LightViewModel.swift)) and from `handleAppDidBecomeActive()` ([LightViewModel.swift:137-143](../../../Baby%20Light/LightViewModel.swift)), which `ContentView` invokes on every `scenePhase == .active` transition ([ContentView.swift:147-149](../../../Baby%20Light/ContentView.swift)). Net effect: the counter restarts from 0:00 every time the app is opened or returned to.
- Nothing ever *stops* the elapsed timer while the app runs — it keeps ticking even in the auto-off "screen off" state; the display simply isn't rendered there because the screen-off branch shows plain black ([ContentView.swift:23-29](../../../Baby%20Light/ContentView.swift)).

### Formatting

- iOS: `formatTime(_:)` ([LightViewModel.swift:200-211](../../../Baby%20Light/LightViewModel.swift)) — `nil` → `""`; under an hour → `M:SS` (`%d:%02d`, no leading zero on minutes); one hour and over → `H:MM:SS` (`%d:%02d:%02d`). This same function also formats the auto-off countdown readout in the overlay ([ControlsOverlay.swift:53](../../../Baby%20Light/ControlsOverlay.swift)), so it is shared surface with the auto-off-timer feature.
- Watch: `timeString` ([WatchContentView.swift:87-91](../../../Baby%20Light%20Watch%20App/WatchContentView.swift)) duplicates exactly the same `M:SS` / `H:MM:SS` logic.

### Display

- iOS ([ContentView.swift:46-60](../../../Baby%20Light/ContentView.swift)): centered via `GeometryReader`, font ≈30% of the smaller screen dimension, `.light` weight, `.rounded` design, `monospacedDigit()`, `lineLimit(1)` + `minimumScaleFactor(0.4)` so `H:MM:SS` stays on one line. Color is the current light color `lightened(by: timerLightness)` (`Color.lightened(by:)`, [LightColor.swift:34-38](../../../Baby%20Light/LightColor.swift)) — same hue as the background, nudged toward white. Hit-testing is disabled ([ContentView.swift:61](../../../Baby%20Light/ContentView.swift)) so gestures pass through to the light. The first-run tutorial's step-2 tip is anchored to this text ([ContentView.swift:59](../../../Baby%20Light/ContentView.swift)).
- Watch ([WatchContentView.swift:52-55](../../../Baby%20Light%20Watch%20App/WatchContentView.swift)): fixed 44 pt, same light/rounded/monospaced styling, hue lightened by a fixed `0.22`, and its opacity tracks the Digital-Crown brightness so the text dims with the glow.

### Visibility setting (iOS only)

- `timerLightness` ([LightViewModel.swift:37-39](../../../Baby%20Light/LightViewModel.swift)) — how far the timer text is lightened from the background hue; `0` would be invisible. Default `0.2`, persisted to `UserDefaults` in `didSet`, read back in `init()` guarded by `object(forKey:) != nil` ([LightViewModel.swift:109-111](../../../Baby%20Light/LightViewModel.swift)).
- Adjusted from the controls overlay's "ELAPSED TIMER" section: a `Slider` over `0.05...0.45` (the floor keeps the text from vanishing) with a live `0:00` preview swatch ([ControlsOverlay.swift:95-118](../../../Baby%20Light/ControlsOverlay.swift)).

## Dependencies

- **light-screen** — the timer renders on the full-bleed light surface and derives its color from the current preset.
- **controls-overlay** — hosts the "ELAPSED TIMER" brightness slider; the timer text remains visible behind/around the overlay.
- **auto-off-timer** — shares `formatTime(_:)` on iOS for its countdown readout; the auto-off screen-off state hides the timer display (without stopping the counter).
- **first-run-tutorial** — anchors its step-2 tip (`ShowControlsTip`) on the elapsed-timer text ([ContentView.swift:57-59](../../../Baby%20Light/ContentView.swift)).
- **watch-app** — carries the duplicated watch implementation.

## Known constraints / invariants

- **Dark is sacred** (`patterns.md` §1): the timer text is the same hue as the light, only lightened toward white (`lightened(by:)` / `watchLightened(by:)`), so it stays readable without changing the room's lighting (`patterns.md` §7). Don't switch it to white/system colors.
- **iOS↔watch duplication is a sync obligation** (`patterns.md` §3, which names *timer formatting* explicitly): any change to the elapsed-time format must land in both `LightViewModel.formatTime(_:)` and `WatchContentView.timeString` in the same PR.
- **Persisted UserDefaults keys are permanent API**: this feature owns exactly one — `timerLightness` ([LightViewModel.swift:38](../../../Baby%20Light/LightViewModel.swift)). Never rename it. `elapsedSeconds` itself is deliberately **not persisted** — the counter is a per-session clock that resets on every app activation ([LightViewModel.swift:18-20](../../../Baby%20Light/LightViewModel.swift)), not a feed log.
- **Accessibility identifiers are API** (`patterns.md` §1): `elapsedTimer` ([ContentView.swift:55](../../../Baby%20Light/ContentView.swift)) and `timerBrightnessSlider` ([ControlsOverlay.swift:109](../../../Baby%20Light/ControlsOverlay.swift)). (The current [Baby LightUITests/Baby_LightUITests.swift](../../../Baby%20LightUITests/Baby_LightUITests.swift) doesn't reference them directly, but the constitution declares them load-bearing — treat them as API regardless.)
- **Tests pin the formatting** ([Baby LightTests/Baby_LightTests.swift:71-87](../../../Baby%20LightTests/Baby_LightTests.swift)): `formatTime(nil) == ""`, `90 → "1:30"`, `60 → "1:00"`, `59 → "0:59"`, `3661 → "1:01:01"`, `3600 → "1:00:00"`. Changing the format (e.g. zero-padding minutes) breaks these tests and must be a deliberate, both-targets decision.
- **Reset-on-activation is the product behaviour**: `handleAppDidBecomeActive()` restarts the counter on *every* return to foreground, including brief interruptions that bounce through `.inactive`/`.active`. Specs that add "keep timing across a lock-screen glance" semantics are changing this contract, not fixing a bug.
- The watch target has no tests; its gate is "still compiles" (`patterns.md` §9).

## Open debts

- **Tick-based counting, not wall-clock**: both targets increment a counter once per timer tick ([LightViewModel.swift:128-130](../../../Baby%20Light/LightViewModel.swift), [WatchContentView.swift:76](../../../Baby%20Light%20Watch%20App/WatchContentView.swift)) rather than deriving elapsed time from a start `Date`. If the runloop is suspended (watch wrist-down, iOS interruption that doesn't re-trigger `.active`), displayed time can lag real time. On iOS the reset-on-activation behaviour mostly masks this; on the watch there is no reset path, so long sessions may under-count. Not worth a spec until a user notices.
- **Watch has no reset**: the doc comment on `elapsed` says "since the view appeared / was reset" ([WatchContentView.swift:30](../../../Baby%20Light%20Watch%20App/WatchContentView.swift)), but no code path resets it — the counter only restarts when the view is recreated (app relaunch). Whether an explicit reset was intended is unclear from code — confirm with owner.
- **Watch text lightening is hard-coded** at `0.22` ([WatchContentView.swift:55](../../../Baby%20Light%20Watch%20App/WatchContentView.swift)) — no equivalent of the iOS `timerLightness` setting. Deliberate simplicity (`patterns.md` §2: watch stays view-model-free); noted so nobody "fixes" the asymmetry by accident.
