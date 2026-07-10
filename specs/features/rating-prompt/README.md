# Rating prompt

## What it is

The native App Store rating dialog (StoreKit's `requestReview`), asked of returning users at most **once, ever** — and only while the controls overlay is open, so the prompt can never brighten the screen over the dim light at bedtime.

## Where it lives

- [`Baby Light/LightViewModel.swift`](../../../Baby%20Light/LightViewModel.swift) — the gating rule, the persisted counters, and the `shouldRequestReview` signal the view layer observes.
- [`Baby Light/ContentView.swift`](../../../Baby%20Light/ContentView.swift) — observes the signal, fires the StoreKit request, reports back.
- [`Baby LightTests/Baby_LightTests.swift`](../../../Baby%20LightTests/Baby_LightTests.swift) — `ReviewPromptTests` pins the gating rule.

There is no watch-side counterpart; the rating prompt is iOS-only.

## Key entry points

### The gating rule — static, pure, unit-tested

```swift
static func shouldPromptForReview(useCount: Int, hasRequestedReview: Bool) -> Bool {
  !hasRequestedReview && useCount >= 2
}
```

`LightViewModel.swift:236-238`. Exactly two conditions:

1. **`!hasRequestedReview`** — we have never asked before on this install.
2. **`useCount >= 2`** — this is the second use or later (first-time users are never asked).

It is deliberately `static` and side-effect-free — no `UserDefaults`, no UI — so unit tests hit it directly (see [`specs/patterns.md`](../../patterns.md) §5, where this function is the canonical example). Keep it that shape.

### How the prompt is triggered

`maybeRequestReview()` (`LightViewModel.swift:244-249`, private) checks the gate and, if it passes, raises `shouldRequestReview = true` (flag declared at `LightViewModel.swift:81`). It is called from exactly two places — both moments when the controls overlay is visible, i.e. the user is deliberately looking at a bright screen:

- **`toggleControls()`** (`LightViewModel.swift:224-229`) — only on the hidden → visible transition (the `if controlsVisible` guard at line 226), i.e. after the double-tap that opens the controls.
- **`wakeUp()`** (`LightViewModel.swift:214-221`) — when the user taps the black auto-off sleep screen; it shows the controls first (line 219), then checks the gate (line 220).

### The call site and its timing

`ContentView` watches the flag with `.onChange(of: viewModel.shouldRequestReview)` (`ContentView.swift:133-140`). When it flips true, the view invokes SwiftUI's `@Environment(\.requestReview)` action (`ContentView.swift:14`; `import StoreKit` at line 7) and immediately calls `didRequestReview()`.

`didRequestReview()` (`LightViewModel.swift:253-257`) clears the pending flag and permanently latches `hasRequestedReview = true` in memory and in `UserDefaults` (line 256) — the gate can never pass again on this install.

### Use counting

`useCount` (`LightViewModel.swift:69`) is read from `UserDefaults`, incremented, and written back **once per cold start** in `init()` (`LightViewModel.swift:115-116`). A "use" is a process launch (the view model is created once, as `@State` in `ContentView.swift:11`) — returning from background does *not* increment it.

### Tests pinning the behaviour

`ReviewPromptTests` (`Baby LightTests/Baby_LightTests.swift:144-168`):

- `doesNotPromptOnFirstUse` (line 146) — `useCount: 1` → false.
- `promptsOnSecondUse` (line 150) — `useCount: 2` → true.
- `promptsOnLaterUses` (line 154) — `useCount: 7` → true.
- `doesNotPromptOnceAlreadyRequested` (line 158) — `hasRequestedReview: true` → false at any count.
- `didRequestReviewClearsPendingFlag` (line 162) — `didRequestReview()` resets `shouldRequestReview`.

## Dependencies

- **controls-overlay** — the prompt is only allowed to trigger at the moment the overlay becomes visible; its visibility state is the gate's timing signal.
- **auto-off-timer** — the `wakeUp()` trigger path exists because the auto-off timer produces the tap-to-wake black screen.
- **StoreKit** (`requestReview` environment action) — Apple system UI; whether the dialog is actually displayed is ultimately the OS's decision (system throttling), not the app's.
- Nothing else in the app depends on this feature.

## Known constraints / invariants

- **Dark is sacred** ([`specs/patterns.md`](../../patterns.md) §1) — the rating prompt is the canonical example of that invariant: it may only surface while the controls overlay is open (an intentional, screen-on moment), **never** over the dim light or the black sleep screen. Both trigger paths guarantee the controls are visible when the flag is raised; do not add new call sites of `maybeRequestReview()` that break this.
- **Persisted `UserDefaults` keys are permanent API** ([`specs/patterns.md`](../../patterns.md) §4) — never rename:
  - `appUseCount` (Int) — launch counter, incremented in `init()` (`LightViewModel.swift:115-116`).
  - `hasRequestedReview` (Bool) — latched true after the single ask (`LightViewModel.swift:256`).
- **When it can fire:** second-or-later launch, never asked before, and only at the instant controls become visible (double-tap toggle, or the tap that wakes the screen after auto-off).
- **When it cannot fire:** first launch ever; while controls are hidden; over the dim light; over the black sleep screen; and never again after the first request.
- **One ask per install, counted at request time:** `didRequestReview()` latches `hasRequestedReview` immediately after calling `requestReview()`, regardless of whether StoreKit actually presented a dialog (the OS throttles it). The app's single permitted ask can therefore be consumed without the user seeing anything — accepted behaviour today, not a bug.
- **The gating function stays static and pure** ([`specs/patterns.md`](../../patterns.md) §5) so `ReviewPromptTests` keep exercising it without touching `UserDefaults`.

## Open debts

- UI tests can neutralize the tutorial with `-hasLaunchedBefore NO`, but there is no equivalent launch-argument override for `appUseCount` / `hasRequestedReview`. On a simulator whose persisted defaults already satisfy the gate, opening the controls during a UI-test run could surface the system prompt mid-test. Not observed as flaky so far — unclear from code whether it bites in practice; confirm with owner before "fixing".
- `shouldRequestReview` is a publicly settable `var` (`LightViewModel.swift:81`, needed by the `didRequestReviewClearsPendingFlag` test), so nothing structurally prevents raising it outside the gate. Low risk in a one-view app; noted for awareness only.
