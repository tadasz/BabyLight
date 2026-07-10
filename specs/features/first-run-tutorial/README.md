# First-run tutorial

## What it is

On the very first launch the controls panel is shown so a new parent isn't stranded on a bare colored screen, and a two-step TipKit tutorial teaches the app's two undiscoverable gestures: double-tap to toggle the controls, swipe to adjust brightness. After that first session the app opens straight into the clean night light.

## Where it lives

iOS target only — the watch app has no TipKit and no first-run state.

- [`Baby Light/Tips.swift`](../../../Baby%20Light/Tips.swift) — the two tip definitions (`HideControlsTip`, `ShowControlsTip`). This is the file the feature owns outright.
- [`Baby Light/Baby_LightApp.swift`](../../../Baby%20Light/Baby_LightApp.swift) — TipKit bootstrap: `Tips.configure` in the app `init` (`Baby_LightApp.swift:16-19`).
- [`Baby Light/LightViewModel.swift`](../../../Baby%20Light/LightViewModel.swift) — the `hasLaunchedBefore` flag: read in `init()` (`LightViewModel.swift:100`), written in the `controlsVisible` setter (`LightViewModel.swift:52-54`).
- [`Baby Light/ContentView.swift`](../../../Baby%20Light/ContentView.swift) — where the tips attach (`.popoverTip`, `ContentView.swift:59` and `:70`) and where the step-2 rule parameter is kept in sync (`ContentView.swift:126`, `:128-132`).
- [`Baby LightUITests/Baby_LightUITests.swift`](../../../Baby%20LightUITests/Baby_LightUITests.swift) — consumer of the `-hasLaunchedBefore` launch argument (`Baby_LightUITests.swift:18`).

## Key entry points

### The `hasLaunchedBefore` flag and first-launch controls visibility

- `LightViewModel.init()` seeds the private backing field: `_controlsVisible = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")` (`LightViewModel.swift:100`) — controls visible on first launch, hidden on every later launch.
- The flag is **written only when the controls are hidden for the first time**: the `controlsVisible` setter persists `hasLaunchedBefore = true` when the new value is `false` (`LightViewModel.swift:52-54`). Practically it means "has hidden the controls at least once" — a user who launches and quits without double-tapping sees the controls again next launch.
- History note baked into the doc comment (`LightViewModel.swift:44-46`): the getter used to OR in `!hasLaunchedBefore`, which permanently forced controls visible under `-hasLaunchedBefore NO` and broke UI tests. Don't reintroduce that.
- `wakeUp()` sets `_controlsVisible = true` directly, bypassing the setter (`LightViewModel.swift:219`) — deliberate, since only *hiding* should mark the flag.

### Tip 1 — `HideControlsTip` (`Tips.swift:14-30`)

- Teaches: double-tap to hide the controls and get a clean night light.
- Anchoring **is** the trigger: `.popoverTip(hideControlsTip)` sits on `ControlsOverlay`, which is only in the view hierarchy while `viewModel.controlsVisible` is true (`ContentView.swift:65-70`). No TipKit rule needed (`Tips.swift:11-13`) — it naturally appears on first launch (controls visible) and never over the bare light.
- Options: `MaxDisplayCount(1)` (`Tips.swift:27-29`) — shows once, ever.

### Tip 2 — `ShowControlsTip` (`Tips.swift:37-61`)

- Teaches: double-tap to bring the controls back, swipe up/down to adjust brightness. The swipe gesture is mentioned here and not in step 1 because it only takes effect while the controls are hidden (`Tips.swift:32-36`).
- Trigger: a TipKit `@Parameter static var controlsVisible: Bool = true` (`Tips.swift:40`) with the rule `#Rule(Self.$controlsVisible) { $0 == false }` (`Tips.swift:54-56`) — eligible only once the controls are hidden. The default of `true` keeps it ineligible until the app seeds it.
- Wiring: `ContentView` seeds the parameter from `viewModel.controlsVisible` in `.onAppear` (`ContentView.swift:126`) and mirrors every change in `.onChange` (`ContentView.swift:128-132`).
- Anchor: `.popoverTip(showControlsTip)` on the elapsed-timer `Text` at screen center (`ContentView.swift:57-59`), i.e. it appears over the bare light.
- Options: `MaxDisplayCount(1)` (`Tips.swift:58-60`).
- Ordering falls out of the rules, not an explicit sequence: step 1 can only show while controls are visible, step 2 only after they've been hidden — so step 2 naturally follows step 1 (`Tips.swift:38-39`).

### TipKit configuration and reset

- `Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])` in the app `init` (`Baby_LightApp.swift:16-19`): no minimum spacing between tips, display state stored in the default application datastore.
- **There is no reset path in code** — no call to `Tips.resetDatastore()` or test-mode overrides anywhere in the target. Once a tip has displayed its one time, only deleting/reinstalling the app (or erasing the simulator) brings it back. In particular, `-hasLaunchedBefore NO` does *not* reset TipKit state: it re-shows the controls, not the tips.

### The `-hasLaunchedBefore` launch argument

- Standard `UserDefaults` argument-domain override: passing `-hasLaunchedBefore NO` makes `bool(forKey: "hasLaunchedBefore")` read `false` for that session without touching persisted state (reads keep returning `false` for the whole launch even after the setter writes `true` to the persistent domain).
- UI tests launch with `["-hasLaunchedBefore", "NO"]` for a deterministic first-launch state (`Baby_LightUITests.swift:18`); tests like `testControlsOverlayVisibleOnFirstLaunch` depend on it (`Baby_LightUITests.swift:56-63`). `Baby_LightUITestsLaunchTests` launches without arguments.
- Documented recipe (`CLAUDE.md` §3, `specs/tech-stack.md:79`): `-hasLaunchedBefore NO` shows the first-run controls, `YES` hides them.
- App Store screenshots: [`AppStore/make_screenshots.py`](../../../AppStore/make_screenshots.py) never launches the app — it recreates the screens in PIL, cross-checked against the real simulator captures in `AppStore/raw/` (`make_screenshots.py:12-14`, `AppStore/README.md:13`). The launch argument is what controls whether the overlay is on screen when those raw captures are (re)taken manually.

## Dependencies

- **controls-overlay** — tip 1 is anchored to it and its visibility drives both the persisted flag and tip 2's rule.
- **light-screen** — tip 2 anchors to the elapsed-timer text on the bare light; `ContentView` hosts all the wiring.
- **rating-prompt** — not a code dependency, but the two share the `controlsVisible` state and the same "only during a deliberate, screen-on moment" philosophy (`LightViewModel.swift:75-81`).
- **app-store-kit** — the raw screenshot captures rely on the launch argument to pose the app with/without controls.
- Relied on by: `Baby LightUITests` (launch argument + controls-visible-on-first-launch behavior).

## Known constraints / invariants

- **Persisted UserDefaults key: `hasLaunchedBefore`** — permanent API, never rename (`specs/patterns.md` §4). It is the only key this feature owns.
- **Dark is sacred** (`specs/patterns.md` §1): tips are the one sanctioned piece of UI allowed to appear over the bare light, and only because each is a small system popover shown **once ever** (`MaxDisplayCount(1)`). Any new tip must keep that shape — one-time, minimal, and never a bright full-screen presentation. Tip 1 avoids the issue entirely by anchoring inside the controls panel (a screen-on moment).
- **Accessibility identifiers are API** (`specs/patterns.md` §1): the first-launch UI tests resolve `controlsOverlay` / `mainLightView`; the container wiring in `ContentView.swift:74-76` and `:83-85` exists to make those identifiers resolve — don't restructure it casually.
- The `-hasLaunchedBefore` launch argument is load-bearing for the whole UI-test suite (`Baby_LightUITests.swift:18`) and the screenshot capture recipe — treat it as API too.
- Tip copy is written inline in English per house style (`specs/patterns.md` §6) — but see the open debt below.
- No simulator-specific TipKit caveat is recorded in code comments (checked; the only documented simulator gotcha is the unrelated `simctl launch` hang in `CLAUDE.md` §3).

## Open debts

- **The four tip strings are missing from the localization catalog.** `Hide the controls`, `Tap to show controls`, and both message bodies were added to `Baby Light/Localizable.xcstrings` with the tutorial (commit `309323d`, PR #12) but dropped during the 26-language catalog rewrite (commit `0143ce2`, PR #13) and never restored — the current catalog has none of them, so the tutorial renders in English in all locales. This violates `specs/patterns.md` §6. Unclear from code whether the removal was deliberate — confirm with owner; almost certainly needs a re-localization pass.
- The persisted meaning of `hasLaunchedBefore` is "has hidden the controls at least once", not "has launched before" (`LightViewModel.swift:52-54`). Harmless today, but a future spec touching first-run behavior should be aware the name overpromises.
