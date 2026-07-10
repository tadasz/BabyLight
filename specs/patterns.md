# Patterns

This document is the **house style** for Baby Night Light. `mission.md` says what we build, `tech-stack.md` says what we build with — this file says *how we write the code*.

Every claim cites a real file so you can read the canonical example before copying. This is a small codebase (~13 Swift files); when in doubt, read the whole neighbouring file — it's cheap.

---

## 1. Product invariants (break these and the app is broken)

These are behavioural rules, not style. Any change that violates one is a bug regardless of how clean the code is.

- **Dark is sacred.** Nothing may unexpectedly brighten the screen or present bright UI while the light is in use. The canonical example: the rating prompt is gated so it only fires while the controls overlay is open — an intentional, screen-on moment — never over the dim light ([LightViewModel.swift](../Baby%20Light/LightViewModel.swift) → `maybeRequestReview()`).
- **Full-bleed color.** The light fills every pixel — no status bar, no home indicator, no safe-area gaps. Enforced by `StatusBarHiddenHostingController` (`safeAreaRegions = []`, black window background) in [Baby_LightApp.swift](../Baby%20Light/Baby_LightApp.swift) plus `.ignoresSafeArea()` / `.persistentSystemOverlays(.hidden)` in [ContentView.swift](../Baby%20Light/ContentView.swift).
- **Screen stays awake** while the app is open: `UIApplication.shared.isIdleTimerDisabled = true` on appear, restored on disappear ([ContentView.swift](../Baby%20Light/ContentView.swift)).
- **Brightness writes happen at resign-active, not in background.** iOS silently drops `UIScreen.brightness` writes once the app is no longer frontmost — dim-on-close must run in the `.inactive` scene phase, with `.background` only as a fallback ([LightViewModel.swift](../Baby%20Light/LightViewModel.swift) → `handleAppWillResignActive()`).
- **Sleep-friendly palette.** Colors are red/amber/warm presets chosen for minimal melatonin disruption ([LightColor.swift](../Baby%20Light/LightColor.swift)). Don't add cool/blue/bright presets without an explicit product decision.
- **On watch, the corner clock stays hidden** via the invisible-`VideoPlayer` trick ([WatchContentView.swift](../Baby%20Light%20Watch%20App/WatchContentView.swift) → `TimeHidingOverlay`). There is no public API for this; don't remove it "because it looks unused".
- **UI-test accessibility identifiers are API.** `lightBackground`, `elapsedTimer`, `controlsOverlay`, `mainLightView`, `timerBrightnessSlider` are load-bearing for `Baby LightUITests/`. Renaming or restructuring them breaks the suite — update tests in the same change.

## 2. Architecture — SwiftUI + one observable view model

No MVVM-C, no coordinators, no DI container, no service layer. The app is small and stays that way:

- **One view model per app.** [LightViewModel.swift](../Baby%20Light/LightViewModel.swift) is an `@Observable class` (Observation framework) owning all iOS app state: color, timers, brightness, persisted settings, rating-prompt gating.
- **Views own it with `@State`**, pass it down with `@Bindable` ([ContentView.swift](../Baby%20Light/ContentView.swift) → [ControlsOverlay.swift](../Baby%20Light/ControlsOverlay.swift)).
- **Views stay declarative** — gestures and scene-phase changes call view-model methods; logic lives in the view model.
- The watch app is even simpler: local `@State` in [WatchContentView.swift](../Baby%20Light%20Watch%20App/WatchContentView.swift), no view model. Keep it that way until it genuinely hurts.
- Don't introduce new architecture layers (router, repository, service protocol) for a one-screen app. If a feature seems to need one, that's a spec-level **Decision**, not a default.

## 3. iOS ↔ watch: deliberate duplication, no shared framework

The watch target is **source-independent** from the iOS target. The palette is duplicated on purpose ([WatchLight.swift](../Baby%20Light%20Watch%20App/WatchLight.swift) mirrors [LightColor.swift](../Baby%20Light/LightColor.swift)) so neither target drags in the other's dependencies.

- When changing shared *behaviour* (palette colors, timer formatting), update **both** targets in the same change — the duplication is a sync obligation, not an oversight.
- Do **not** extract a shared framework/package to deduplicate ~40 lines. Revisit only if the duplicated surface grows well past the palette.

## 4. State & persistence

- **`UserDefaults.standard` directly, with string keys, written in `didSet`** — the house pattern for persisted settings ([LightViewModel.swift](../Baby%20Light/LightViewModel.swift) → `dimOnClose`, `brightenOnOpen`, `timerLightness`). Read back in `init()` guarded by `object(forKey:) != nil` so coded defaults win on first launch.
- Existing keys (`hasLaunchedBefore`, `dimOnClose`, `brightenOnOpen`, `timerLightness`, `appUseCount`, `hasRequestedReview`) are effectively persistent API — never rename them; migrations aren't worth it here.
- Keys are declared at their point of use. If a key gains a third use site, hoist it to a constant then.
- No `@AppStorage` in the view model (it's a view-layer wrapper); no Core Data, no files on disk.
- **Derive, don't duplicate:** prefer a computed property over a second stored flag — `isScreenOff` is computed from `timeRemaining == 0`, not stored ([LightViewModel.swift](../Baby%20Light/LightViewModel.swift)).

## 5. Testability — pure gating logic as static functions

Decision rules that would otherwise touch `UserDefaults` or UI are extracted as **static, side-effect-free functions** so unit tests can hit them directly. Canonical: `LightViewModel.shouldPromptForReview(useCount:hasRequestedReview:)` ([LightViewModel.swift](../Baby%20Light/LightViewModel.swift)). Follow this shape for any new gating/threshold logic.

## 6. Strings & localization

- User-facing text is written **inline in English** in SwiftUI (`Text("Hide the controls")`); Xcode extracts it into the target's `Localizable.xcstrings`. There is no `L10n`-style generated layer.
- Model-provided display strings pass through `LocalizedStringKey(...)` so they hit the catalog ([ControlsOverlay.swift](../Baby%20Light/ControlsOverlay.swift) → `Text(LocalizedStringKey(viewModel.currentColor.description))`).
- **Every new user-facing string must land in *both* catalogs it appears in (iOS and/or watch) with all 26 locales filled** before release. Untranslated strings are a merge-gate failure, not a follow-up.
- Translations are edited directly in the `.xcstrings` JSON. Match the existing tone: short, calm, parent-to-parent.

## 7. Colors & visual style

- The palette is data: `LightColor.presets` (iOS, hex via the local `Color(hex:)` extension) and `WatchPalette.presets` (watch, RGB literals). New colors go into these arrays — nowhere else.
- On-light text (elapsed timer) uses the **same hue lightened toward white** — `Color.lightened(by:)` / `watchLightened(by:)` — so text stays readable without changing the room's lighting.
- Controls-overlay chrome is white/gray-on-dark with system fonts sized inline ([ControlsOverlay.swift](../Baby%20Light/ControlsOverlay.swift)). There is no design system and no need for one; match the neighbouring modifiers.

## 8. Concurrency & timers

- The app is main-thread only. `Timer.scheduledTimer(withTimeInterval:repeats:)` with `[weak self]` closures drives countdowns ([LightViewModel.swift](../Baby%20Light/LightViewModel.swift)); the watch uses `Timer.publish().autoconnect()` + `.onReceive` ([WatchContentView.swift](../Baby%20Light%20Watch%20App/WatchContentView.swift), needs `import Combine`).
- Always `invalidate()` the old timer before scheduling a replacement (`startElapsedTimer()`, `setTimer(_:)`).
- No `async/await` surface exists yet; introduce it only when an API demands it — don't refactor timers to actors/streams for style points.

## 9. Testing

- **Unit tests: Swift Testing** (`@Test`, `#expect`), one struct, plain functions, `@testable import Baby_Night_Light` — canonical file [Baby_LightTests.swift](../Baby%20LightTests/Baby_LightTests.swift). Target the view model and pure logic; views don't get unit tests.
- **UI tests: XCUITest** ([Baby_LightUITests.swift](../Baby%20LightUITests/Baby_LightUITests.swift)) — reset state with launch arguments (`-hasLaunchedBefore NO`), locate elements by accessibility identifier, `waitForExistence(timeout:)` before asserting.
- **Bug fixes always add a regression test** that would have caught the bug (see `/spec-bug`'s reproduce-first plan).
- The watch target has no tests; its gate is "still compiles" (`tech-stack.md` → watch build check).

## 10. Comments

This codebase is deliberately **comment-rich about platform quirks**: comments explain non-obvious *why* — iOS lifecycle traps (brightness writes at resign-active), API workarounds (the VideoPlayer clock trick, `UIScreen.main` deprecation), tutorial-rule wiring. Keep that standard:

- Comment hidden invariants and workarounds a future reader would otherwise "fix".
- Don't narrate the obvious (`// set timer` above `setTimer`), and never reference the current task/PR in comments.

## 11. Code style

- 2-space indentation (the dominant style — [ContentView.swift](../Baby%20Light/ContentView.swift)); match the file you're in.
- `struct` for views and value types; `class` only for the view model and UIKit subclasses.
- `// MARK: -` sections in files over ~100 lines ([LightViewModel.swift](../Baby%20Light/LightViewModel.swift)).
- `private` for internals; accessibility identifiers on any element a UI test needs.
- Presets/options are `static let` arrays on their type (`LightColor.presets`, `TimerOption.options`, `WatchPalette.presets`).
- No file-header boilerplate beyond the existing `//  <File>.swift / Baby Night Light` stubs; don't add author/date lines to new files.

## 12. What not to do

- Don't add a third-party dependency — ever, without an owner-level decision recorded in a spec (`mission.md` → zero dependencies).
- Don't add analytics, tracking, networking, or accounts — privacy is a value proposition.
- Don't present alerts, sheets, or bright system UI over the light (see §1 — the rating-prompt gating is the template).
- Don't rename `UserDefaults` keys or accessibility identifiers casually (§4, §1).
- Don't extract shared iOS/watch code into a framework (§3).
- Don't leave a new string untranslated in the catalogs (§6).
- Don't refactor neighbouring code "while you're in there" — no drive-by refactors (see `CLAUDE.md`).
- Don't disable or work around `StatusBarHiddenHostingController` / safe-area suppression — white edges at 3 AM are the app's original sin (it's in the git history).
