# Light screen

## What it is

The app's core surface: a single full-screen block of sleep-friendly color that fills every pixel of the iPhone display and acts as a night light. Parents drag up/down to change brightness, double-tap to show or hide the controls, and the screen never auto-locks while the light is on.

## Where it lives

- [ContentView.swift](../../../Baby%20Light/ContentView.swift) — the light surface itself: full-bleed color, gestures, idle-timer handling, scene-phase wiring.
- [Baby_LightApp.swift](../../../Baby%20Light/Baby_LightApp.swift) — app entry point plus `StatusBarHiddenView` / `StatusBarHiddenHostingController`, the UIKit layer that suppresses the status bar and safe areas.
- [LightViewModel.swift](../../../Baby%20Light/LightViewModel.swift) — the single app view model; for this feature: `currentColor`, `brightness`, `controlsVisible`, the `activeScreen` resolver, and the lifecycle brightness handlers.
- [LightColor.swift](../../../Baby%20Light/LightColor.swift) — the color presets the surface renders, plus the `Color(hex:)` and `lightened(by:)` helpers.
- [GlowPulse.swift](../../../Baby%20Light/GlowPulse.swift) — the deep-sleep tip's cue: an overlay on the color layer that pulses the current color `lightened(by: 0.12)` 3 × ~1.5 s per glow round (`2026-07-10-deep-sleep-tip`; engine and settings live in `Baby Light/SleepTip/`).

## Key entry points

**Rendering.** `ContentView.body` draws `viewModel.currentColor.color` with `.ignoresSafeArea()` as the base of a `ZStack` (ContentView.swift:36–39). Full-bleed is enforced twice over: SwiftUI-side via `.ignoresSafeArea()` at every level plus `.persistentSystemOverlays(.hidden)` (ContentView.swift:120–121), and UIKit-side via `StatusBarHiddenHostingController`, which returns `prefersStatusBarHidden` / `prefersHomeIndicatorAutoHidden` = true (Baby_LightApp.swift:53–54), sets `safeAreaRegions = []` (iOS 16.4+ API, Baby_LightApp.swift:67), and paints both the controller view and the window black so nothing white bleeds through (Baby_LightApp.swift:68, 74).

**Colors.** `LightColor.presets` is the palette — four warm presets (deep red default, amber, candle, warm white) built from hex strings (LightColor.swift:25–30). `Color(hex:)` falls back to pure red for non-6-digit input (LightColor.swift:61–63). `Color.lightened(by:)` nudges RGB channels toward white and is used for on-light text (LightColor.swift:38–48).

**Gestures** (all attached to the main `ZStack`, ContentView.swift:91–142):
- Double-tap (`TapGesture(count: 2)`) calls `viewModel.toggleControls()` (ContentView.swift:93–97). Note: it is a *double* tap, not single tap. `toggleControls()` also triggers the rating-prompt gate when opening.
- Vertical drag (`minimumDistance: 20`) adjusts brightness — **only while controls are hidden** (guard at ContentView.swift:103). Delta is `(dragStartY − y) × 0.002` per change event. A `simultaneousGesture` zero-distance drag seeds `dragStartY` with the touch's start position, using `dragStartY == 0` as the "unset" sentinel (ContentView.swift:114–121).
- Deep-sleep tip (`2026-07-10-deep-sleep-tip`, both via `simultaneousGesture` so the double-tap keeps zero recognition delay): a single `TapGesture` acknowledges a pulsing glow (the engine rejects the tap at any other time, so it is inert otherwise — ContentView.swift:125–133), and a `LongPressGesture(minimumDuration: 0.6)` resets the settling session (guarded off in the view model while the feature is disabled — ContentView.swift:134–142).
- The elapsed-timer text layer has `.allowsHitTesting(false)` so these gestures reach the surface through it (ContentView.swift:65).

**Brightness.** `LightViewModel.adjustBrightness(delta:)` clamps to 0.0…1.0 (true zero allowed for the darkest screen) and writes to `activeScreen?.brightness` (LightViewModel.swift:263–266). `activeScreen` resolves the screen through the connected-scene hierarchy because `UIScreen.main` is deprecated in iOS 26 (LightViewModel.swift:90–94).

**Keep-awake.** `onAppear` sets `UIApplication.shared.isIdleTimerDisabled = true`; `onDisappear` restores `false` (ContentView.swift:122–124, 141–144).

**Lifecycle brightness (scene phase)**, ContentView.swift:145–162:
- `.active` → `handleAppDidBecomeActive()`: restarts the elapsed counter and, if `brightenOnOpen`, sets brightness to 1.0 (LightViewModel.swift:137–143).
- `.inactive where oldPhase == .active` → `handleAppWillResignActive()`: if `dimOnClose`, writes `activeScreen?.brightness = 0.0` (LightViewModel.swift:155–159). The `oldPhase == .active` guard prevents dimming on the background → inactive → active return path (ContentView.swift:150–155).
- `.background` → `handleAppDidEnterBackground()`: re-applies the dim as a fallback (LightViewModel.swift:163–167).

**Settings state.** `dimOnClose`, `brightenOnOpen` (both default true) persist to `UserDefaults` in `didSet` (LightViewModel.swift:25–32) and are read back in `init()` guarded by `object(forKey:) != nil` (LightViewModel.swift:103–108). `controlsVisible` is seeded from `hasLaunchedBefore` — shown on first launch, hidden thereafter — and hiding it writes `hasLaunchedBefore = true` (LightViewModel.swift:47–57, 100).

## Dependencies

This surface is the host: most other iOS features render on or through it.

- **controls-overlay** — `ContentView` conditionally mounts `ControlsOverlay` when `controlsVisible` (ContentView.swift:65–77); the overlay is where the user picks the color and toggles `dimOnClose`/`brightenOnOpen`, which this feature then acts on.
- **auto-off-timer** — when the countdown hits zero, `isScreenOff` (computed from `timeRemaining == 0`, LightViewModel.swift:60–62) replaces the light with a black tap-to-wake screen (ContentView.swift:23–29).
- **feed-timer** — the elapsed-time readout is drawn centered on this surface, colored with the light's own hue lightened by `timerLightness` (ContentView.swift:46–60); `handleAppDidBecomeActive()` restarts it.
- **first-run-tutorial** — both TipKit tooltips anchor to elements of this screen (ContentView.swift:59, 70) and are driven by `controlsVisible` changes (ContentView.swift:125–132).
- **rating-prompt** — `ContentView` observes `shouldRequestReview` and fires the StoreKit prompt (ContentView.swift:133–140); the view model only raises it while controls are open.
- **watch-app** — mirrors this feature's palette by deliberate duplication (`WatchLight.swift`); palette changes here must land in both targets in the same PR (`specs/patterns.md` §3).

## Known constraints / invariants

The first four product invariants in [`specs/patterns.md` §1](../../patterns.md) — *dark is sacred*, *full-bleed color*, *screen stays awake*, *brightness writes at resign-active* — all live in this feature. Do not restate-and-drift; read §1. Feature-specific specifics on top of that:

- **Never weaken `StatusBarHiddenHostingController` or the safe-area suppression** (`safeAreaRegions = []`, black window background, Baby_LightApp.swift:64–75). White edges at 3 AM are the app's original sin (`specs/patterns.md` §12).
- **Brightness writes must happen while frontmost.** iOS silently drops `UIScreen.brightness` writes once the app is no longer key — the dim runs at `.inactive` (with `.background` only as a fallback), and the `oldPhase == .active` guard must stay (ContentView.swift:150–158, LightViewModel.swift:149–159).
- **The brightness drag only works with controls hidden** (ContentView.swift:99) — the overlay owns touch input when visible.
- **Palette changes go into `LightColor.presets` only**, stay in the warm/sleep-friendly range, and must be mirrored in the watch target (`specs/patterns.md` §1, §3, §7).
- **`UserDefaults` keys `dimOnClose`, `brightenOnOpen`, `hasLaunchedBefore` are permanent API** — never rename (`specs/patterns.md` §4).
- **Accessibility identifiers are API** (used by `Baby LightUITests/Baby_LightUITests.swift`). This feature declares in ContentView.swift:
  - `lightBackground` — the full-bleed color layer (ContentView.swift:38)
  - `mainLightView` — the containing `ZStack` (ContentView.swift:85)
  - it also hosts the attach points for `elapsedTimer` (ContentView.swift:55, feed-timer's readout) and `controlsOverlay` (ContentView.swift:76, the overlay container).
- **Keep the `.accessibilityElement(children: .contain)` on the `ZStack` and on the overlay** — without it, the container identifier propagates to every child and clobbers `lightBackground`/`elapsedTimer`/`controlsOverlay` (ContentView.swift:73–76, 80–85).
- The double-tap toggle and the drag gesture coexist deliberately (`gesture` + `simultaneousGesture` stack, ContentView.swift:91–142); reordering or merging them changes which gesture wins. The deep-sleep tip's tap-acknowledge and long-press-reset joined the stack as `simultaneousGesture`s for the same reason — converting either to a plain `.gesture` would add double-tap latency.
- **The glow pulse is the one sanctioned rendering-side brightening** (owner-approved, `specs/2026-07-10-deep-sleep-tip` → Decisions): opt-in, hue-preserving, ≤ ~+12 % lightness for ~4.5 s, rendering-only (`lightened(by:)`, never `UIScreen.brightness`). Anything brighter, longer, or unprompted still breaks *dark is sacred*.
- **"Dim on close" is dim-to-zero by design** (owner-confirmed 2026-07-10). The app deliberately does not record or restore the pre-launch system brightness: resign-active writes 0.0, and reopening (with `brightenOnOpen`) writes 1.0 (LightViewModel.swift:155–159, 137–143). Don't "fix" this by saving/restoring brightness.

## Open debts

- **The view-model `brightness` can drift from the real screen brightness.** It's read once in `init()` (LightViewModel.swift:98) and only re-synced by the brighten-to-1.0 path; if the user changes brightness in Control Center (or `brightenOnOpen` is off), the first drag jumps from the stale stored value (LightViewModel.swift:263–266).
- The `dragStartY == 0` sentinel means a touch starting at exactly y = 0 never seeds the drag origin (ContentView.swift:113); practically unreachable (topmost pixel), noted for completeness.
