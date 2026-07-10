# Controls overlay

## What it is

The semi-transparent settings panel that floats over the iOS night light. It's where a parent picks the light color, sets the auto-off timer, tunes the auto-brightness behaviour and the elapsed-timer readout — and it gets out of the way with a double-tap so the screen becomes a bare light.

## Where it lives

- [`Baby Light/ControlsOverlay.swift`](../../../Baby%20Light/ControlsOverlay.swift) — the panel itself: layout, section headings, `ColorButton` and `TimerButton` subviews.
- [`Baby Light/ContentView.swift`](../../../Baby%20Light/ContentView.swift) — hosts the overlay conditionally and owns the show/hide gesture (`ContentView.swift:65-93`).
- [`Baby Light/LightViewModel.swift`](../../../Baby%20Light/LightViewModel.swift) — `controlsVisible` state, first-launch seeding, and the settings the overlay binds to.
- Data the overlay renders: [`Baby Light/LightColor.swift`](../../../Baby%20Light/LightColor.swift) (`LightColor.presets`, 4 colors) and [`Baby Light/TimerOption.swift`](../../../Baby%20Light/TimerOption.swift) (`TimerOption.options`, 5 options).

## What the panel contains (top to bottom)

All in `ControlsOverlay.swift`, a single `VStack` on a black 60%-opacity rounded card capped at 380 pt wide (`ControlsOverlay.swift:126-132`):

1. **Title** — "Baby Light" (`ControlsOverlay.swift:15`).
2. **LIGHT COLOR** — one round `ColorButton` per `LightColor.presets` entry; tapping sets `viewModel.currentColor` (`ControlsOverlay.swift:27-36`). The selected color's description ("Best for sleep", …) shows beneath, routed through `LocalizedStringKey` so it hits the string catalog (`ControlsOverlay.swift:38`).
3. **AUTO-OFF TIMER** — a capsule `TimerButton` per `TimerOption.options` entry (∞ / 15m / 30m / 1h / 2h); tapping calls `viewModel.setTimer(option)` (`ControlsOverlay.swift:59-68`). While a countdown is running, the remaining time renders inline in the heading, e.g. "AUTO-OFF TIMER (14:32)" (`ControlsOverlay.swift:52-57`).
4. **AUTO BRIGHTNESS** — two toggles bound to the persisted settings `brightenOnOpen` ("Max brightness when opened") and `dimOnClose` ("Dim to minimum when closed") (`ControlsOverlay.swift:79-91`).
5. **ELAPSED TIMER** — a "Brightness" slider bound to `viewModel.timerLightness`, range `0.05...0.45` (`ControlsOverlay.swift:107`), with a live "0:00" preview tinted `currentColor.lightened(by: timerLightness)` so the user sees exactly how the on-light readout will look.
6. **DEEP SLEEP TIP** (`2026-07-10-deep-sleep-tip`, `ControlsOverlay.swift:120-190`) — the glow-cue settings: an on/off toggle ("Glow when baby may be deeply asleep") with an always-visible explainer caption; enabling reveals a compact birth-month `DatePicker` (first enable seeds it with today — the newborn bucket glows latest, the conservative default), a −10…+10 min fine-tune `Stepper` whose value renders as a numeric abbreviation ("+3m", not a catalog entry, like the timer capsules), and the gesture hint "Tap the glow to dismiss • Hold the light to restart timing".
7. **Hint** — "Double-tap to hide • Swipe to adjust brightness".

There is **no feed-timer start/stop button**: the elapsed (feed) timer counts up automatically from every app-open (`LightViewModel.swift:125-131`); the overlay's only control over it is the readout-brightness slider above. The auto-off countdown readout in the heading is the overlay's only countdown display — the big on-light readout is the elapsed timer, owned by the light screen.

## Show / hide behaviour

- **Rendering** — `ContentView` inserts the overlay into the ZStack only while `viewModel.controlsVisible` is true, with an opacity + scale transition (`ContentView.swift:65-77`) and a 0.2 s ease-in-out animation (`ContentView.swift:86`).
- **Toggle** — double-tap anywhere on the light calls `viewModel.toggleControls()` (`ContentView.swift:88-93`, `LightViewModel.swift:224-229`). There is **no auto-hide**: once shown, the panel stays until the user double-taps again.
- **First run** — `_controlsVisible` is seeded from `!hasLaunchedBefore` in `init()`, so controls are visible on first launch and hidden on every later cold start (`LightViewModel.swift:96-100`). The first time the user hides them, the setter writes `hasLaunchedBefore = true` (`LightViewModel.swift:47-56`). UI tests reset this with the `-hasLaunchedBefore NO` launch argument (`Baby LightUITests/Baby_LightUITests.swift:18`). Note the history in the comment at `LightViewModel.swift:44-46`: the getter must *not* OR in `!hasLaunchedBefore`, or the controls can never be hidden under that launch argument.
- **Wake from screen-off** — `wakeUp()` re-shows the controls by setting the private `_controlsVisible = true` directly (`LightViewModel.swift:214-221`).
- **Gesture arbitration** — while the overlay is visible the swipe-brightness drag is suppressed (`ContentView.swift:98-99`); the hint's "Swipe to adjust brightness" describes what works *after* hiding (corroborated by `Tips.swift:34-36`).

## Key entry points

- `ControlsOverlay` (view, takes `@Bindable var viewModel: LightViewModel` — `ControlsOverlay.swift:9-10`).
- `LightViewModel.controlsVisible` / `toggleControls()` / `wakeUp()` — the visibility state machine.
- `LightViewModel.setTimer(_:)` — what the timer capsules call.
- `ColorButton` / `TimerButton` — the two private-ish button styles; new controls should match their look (`patterns.md` §7: white/gray-on-dark chrome, system fonts sized inline).

## Dependencies

- **light-screen** — hosts the overlay, owns the double-tap/drag gestures and the `mainLightView` container the tests tap on.
- **auto-off-timer** — the overlay is its only UI (buttons + inline countdown); the engine lives in `LightViewModel` (`setTimer`, `startCountdown`).
- **feed-timer** — the overlay owns the readout-brightness slider and live preview for the elapsed timer; the timer itself and the on-light readout belong to that feature.
- **first-run-tutorial** — step 1 (`HideControlsTip`) is anchored to this panel via `.popoverTip` and only exists while the panel is visible (`ContentView.swift:66-70`); step 2's eligibility rule mirrors `controlsVisible` (`ContentView.swift:126-132`, `Tips.swift:37-56`).
- **rating-prompt** — depends on this feature's visibility: `maybeRequestReview()` fires only when the controls become visible (`toggleControls`/`wakeUp`, `LightViewModel.swift:219-229`), which is what keeps the prompt off the dark light.

## Known constraints / invariants

Shared invariants live in [`specs/patterns.md`](../../patterns.md) §1 — the ones this feature is load-bearing for:

- **Dark is sacred** — the overlay being open is the app's only sanctioned "bright, user-is-looking" moment; the rating prompt is gated on it. Any change that shows the overlay (or bright UI) without an explicit user gesture breaks the invariant.
- **Accessibility identifiers are API** (patterns §1): this feature exposes **`controlsOverlay`** (on the panel, made a container via `.accessibilityElement(children: .contain)` so `otherElements["controlsOverlay"]` resolves) and **`timerBrightnessSlider`** (`ControlsOverlay.swift:109`); since `2026-07-10-deep-sleep-tip` also **`deepSleepTipSection`** (container, `ControlsOverlay.swift:190`), **`sleepTipToggle`** (`:134`), plus `sleepTipBirthMonthPicker` / `sleepTipFineTuneStepper`. `Baby LightUITests/Baby_LightUITests.swift` drives show/hide through `controlsOverlay` + `mainLightView` and asserts the tip section + toggle. Rename these only together with the tests.
- **Persisted keys are permanent** (patterns §4): the overlay writes `dimOnClose`, `brightenOnOpen`, `timerLightness` (via bindings) and `hasLaunchedBefore` (via the `controlsVisible` setter); the deep-sleep tip section adds `sleepTipEnabled`, `sleepTipBirthMonth`, `sleepTipFineTune` (owned by that feature's view-model properties / `BabyProfile`). Never rename any of them.
- **Localization** — every user-facing string is inline English extracted to [`Baby Light/Localizable.xcstrings`](../../../Baby%20Light/Localizable.xcstrings), all 26 locales filled before release (patterns §6). Model-provided strings must pass through `LocalizedStringKey(...)` as the color description does (`ControlsOverlay.swift:38`).
- **First-launch semantics** — controls visible on first launch, hidden thereafter, resettable via `-hasLaunchedBefore NO`. UI tests assume all three (`Baby_LightUITests.swift:56-104`).
- The `timerLightness` slider floor of `0.05` guarantees the elapsed readout is never fully invisible; a spec widening the range should keep a non-zero floor or make invisibility an explicit decision.

## Open debts

- Timer capsule labels (`TimerOption.label`: "∞", "15m", "30m", "1h", "2h") render via the verbatim `Text(option.label)` initializer (`ControlsOverlay.swift:174`), so they bypass the localization catalog. Harmless while they're numeric abbreviations, but any word-based label must be routed through `LocalizedStringKey`.
- All panel typography uses fixed point sizes (`.system(size:)` throughout `ControlsOverlay.swift`), so the overlay doesn't respond to Dynamic Type.
