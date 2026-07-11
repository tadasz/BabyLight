# Auto-off timer

## What it is

The auto-off timer lets a parent set the night light to switch itself off after 15 minutes, 30 minutes, 1 hour, or 2 hours (or run forever, the default). When the countdown reaches zero the light is replaced by a plain black "sleep" screen; a single tap wakes it back up.

## Where it lives

iOS target (**Baby Night Light**) only:

- [`Baby Light/TimerOption.swift`](../../../Baby%20Light/TimerOption.swift) — the option model and the five presets (`∞`, `15m`, `30m`, `1h`, `2h`; `TimerOption.swift:17-23`). Owned exclusively by this feature.
- [`Baby Light/LightViewModel.swift`](../../../Baby%20Light/LightViewModel.swift) — countdown state and mechanics: `selectedTimer` / `timeRemaining` (`LightViewModel.swift:14-15`), `setTimer(_:)` (`:172-183`), `startCountdown()` (`:185-197`), `isScreenOff` (`:60-62`), `wakeUp()` (`:214-221`), `formatTime(_:)` (`:200-211`). The file is shared with other features; the `// MARK: - Timer Logic` section is this feature's.
- [`Baby Light/ControlsOverlay.swift`](../../../Baby%20Light/ControlsOverlay.swift) — presentation (owned by the **controls-overlay** feature): the "AUTO-OFF TIMER" section header with the live countdown readout (`ControlsOverlay.swift:46-57`) and the row of `TimerButton` capsules (`:59-68`, `:167-191`).
- [`Baby Light/ContentView.swift`](../../../Baby%20Light/ContentView.swift) — what firing looks like (owned by the **light-screen** feature): when `isScreenOff`, the whole light view is replaced by `Color.black` with a tap-to-`wakeUp()` gesture (`ContentView.swift:23-29`).

**The watch app has no auto-off timer.** [`Baby Light Watch App/WatchContentView.swift`](../../../Baby%20Light%20Watch%20App/WatchContentView.swift) contains only the count-up feed timer (`WatchContentView.swift:31, :37, :76`) and Digital Crown dimming — nothing counts down and nothing turns the watch light off. The usual iOS↔watch duplication rule (`specs/patterns.md` §3: shared behaviour changes in both targets in the same PR, no shared framework) applies here only to **time formatting**: the iOS `formatTime(_:)` (`LightViewModel.swift:200-211`) and the watch's `timeString` (`WatchContentView.swift:87-91`) produce the same `M:SS` / `H:MM:SS` shape and must stay in sync if the format ever changes. A spec that adds an auto-off timer to the watch would extend this feature to the second target.

## Key entry points

- **`LightViewModel.setTimer(_ option: TimerOption)`** (`LightViewModel.swift:172-183`) — the single mutation point. Invalidates any running countdown first, then either starts a fresh countdown (`timeRemaining = minutes * 60`) or clears it (`timeRemaining = nil` for the infinite option).
- **`LightViewModel.startCountdown()`** ([LightViewModel.swift](../../../Baby%20Light/LightViewModel.swift)) — a repeating 1-second `Timer.scheduledTimer` with `[weak self]` that decrements `timeRemaining`; on reaching 0 it invalidates itself and deliberately **keeps the value at 0** so `isScreenOff` stays true. Since `2026-07-10-deep-sleep-tip`, reaching 0 also calls `endSettlingSession()` — the deep-sleep tip *consumes* the auto-off event (a no-op when no session is running); the countdown logic itself is untouched.
- **`LightViewModel.isScreenOff`** (`LightViewModel.swift:60-62`) — computed as `timeRemaining == 0` (nil means "no countdown", so infinite never reads as off).
- **`LightViewModel.wakeUp()`** (`LightViewModel.swift:214-221`) — tap on the black screen: invalidates the timer, resets `selectedTimer` to the infinite option, sets `timeRemaining = nil`, shows the controls, and calls `maybeRequestReview()`.
- **`TimerButton` taps in the overlay** (`ControlsOverlay.swift:59-68`) — the only UI that calls `setTimer(_:)`.
- **Countdown readout** — shown only inside the open controls overlay, next to the "AUTO-OFF TIMER" header, as `(M:SS)` / `(H:MM:SS)` while `timeRemaining > 0` (`ControlsOverlay.swift:52-56`). Nothing on the bare light surface shows the remaining time (the large on-light readout is the count-up feed timer, a separate feature).

## Dependencies

This feature relies on:

- **controls-overlay** — hosts the timer buttons and countdown readout.
- **light-screen** — `ContentView` renders the screen-off black state and the tap-to-wake gesture (`ContentView.swift:23-29`).
- **feed-timer** — shares `formatTime(_:)` on iOS (the same formatter drives both the countdown readout and the elapsed readout).

Relying on this feature:

- **rating-prompt** — `wakeUp()` is one of the two triggers for `maybeRequestReview()` (`LightViewModel.swift:220`), because waking is an intentional, screen-on interaction.

## Known constraints / invariants

Rules a future spec must not break (cross-reference `specs/patterns.md` §1):

- **Dark is sacred** (`patterns.md:13`). The timer firing makes the screen *darker* (full black), never brighter, and never presents UI. Waking is strictly user-initiated (single tap). Any "timer finished" notification, alert, or brightening would violate this.
- **Firing changes rendering only — it never touches hardware brightness.** `startCountdown()` and the screen-off branch do not write `UIScreen.brightness`; hardware dimming lives solely in the lifecycle handlers and swipe gesture (`LightViewModel.swift:137-167, :263-266`).
- **The black screen is a rendered view, not device sleep.** `isIdleTimerDisabled` stays `true` for the whole view including the screen-off state (`ContentView.swift:122-127`), so the device stays awake showing black and tap-to-wake keeps working.
- **`isScreenOff` is derived, not stored** — computed from `timeRemaining == 0` (`LightViewModel.swift:60-62`); the canonical "derive, don't duplicate" example in `patterns.md` §4 (`patterns.md:44`). Don't introduce a second stored flag.
- **Always `invalidate()` before rescheduling** — `setTimer(_:)` is the canonical example cited in `patterns.md` §8 (`patterns.md:66`). Main-thread `Timer.scheduledTimer` with `[weak self]` is the house timer pattern; don't refactor to async/await/actors for style.
- **Persisted UserDefaults keys: none.** The selected timer option is deliberately in-memory only — `selectedTimer` defaults to infinite (`LightViewModel.swift:14`) and `init()` restores nothing timer-related (`:96-120`); it also resets to infinite on `wakeUp()` (`:217`). This feature owns **no** persisted keys, so there is no permanent-API surface here. (The keys that do exist — `hasLaunchedBefore`, `dimOnClose`, `brightenOnOpen`, `timerLightness`, `appUseCount`, `hasRequestedReview` — belong to other features.)
- **Localization.** The "AUTO-OFF TIMER" header is in the iOS `Localizable.xcstrings` with all 26 locales filled. The option labels (`∞`, `15m`, `30m`, `1h`, `2h`) are model data rendered verbatim via `Text(option.label)` (`ControlsOverlay.swift:174`) and are **not** catalog entries — they are symbols/short numerics, not translatable prose. A spec that changes labels to words must route them through the catalog (`patterns.md` §6).
- **Preset shape is data.** Options live in `TimerOption.options` as a `static let` array (`TimerOption.swift:17-23`, per `patterns.md:89`); new durations go there, nowhere else. The comment says the presets match the web app (`TimerOption.swift:16`).
- **Test coverage that pins behaviour** ([`Baby LightTests/Baby_LightTests.swift`](../../../Baby%20LightTests/Baby_LightTests.swift)): initial timer is infinite (`:22-26`), `setTimer` seeds `timeRemaining` (`:44-51`), infinite keeps it nil (`:53-58`), screen off exactly at 0 (`:60-67`), `formatTime` shapes including nil → `""` (`:71-87`), `wakeUp` resets timer and shows controls (`:91-100`), and the five presets with unique ids and `∞` first (`:193-210`). No accessibility identifiers belong to this feature, and the XCUITest suite does not exercise the timer flow (`timerBrightnessSlider` belongs to the feed-timer readout, not this feature).

## Open debts

- **Countdown pauses while the app is suspended.** The countdown is a repeating foreground `Timer` with no absolute end date (`LightViewModel.swift:185-197`), so seconds spent in the background don't count down and the light won't turn off on schedule if the app is backgrounded mid-countdown. Whether this is intentional (the app is designed to stay foreground as the light) is unclear from code — confirm with owner before "fixing".
- **Selection is not persisted** — every cold launch starts at infinite. This reads as a deliberate safety default (the light never turns itself off unless asked this session), but intent is unclear from code — confirm with owner before adding persistence.
- **No UI-test coverage** of selecting a timer or the screen-off/wake flow; behaviour is pinned only at the view-model level.
