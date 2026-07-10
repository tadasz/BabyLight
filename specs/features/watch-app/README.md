# Watch app

## What it is

A standalone Apple Watch night light: the whole watch face becomes a wrist-sized red/amber glow for night feeds and check-ins. Tap to cycle colors, turn the Digital Crown to dim, glance at a count-up feed timer — no iPhone required.

## Where it lives

Everything is in the `Baby Light Watch App/` target (watchOS 11, scheme `Baby Light Watch App`):

- [BabyLightWatchApp.swift](../../../Baby%20Light%20Watch%20App/BabyLightWatchApp.swift) — `@main` app entry; a single `WindowGroup` hosting `WatchContentView` (BabyLightWatchApp.swift:12-19).
- [WatchContentView.swift](../../../Baby%20Light%20Watch%20App/WatchContentView.swift) — the entire UI and behaviour: light surface, crown dimming, tap-to-cycle, feed timer, and the corner-clock trick.
- [WatchLight.swift](../../../Baby%20Light%20Watch%20App/WatchLight.swift) — `WatchLightColor` + `WatchPalette.presets`, the watch's self-contained copy of the iOS palette, plus the `watchLightened(by:)` text-color helper.
- [Localizable.xcstrings](../../../Baby%20Light%20Watch%20App/Localizable.xcstrings) — the watch's **own** string catalog (separate from the iOS one): 4 keys (the color names), all 26 locales filled.

There is no view model, no persistence, and no second screen — all state is local `@State` in `WatchContentView` (WatchContentView.swift:26-33), per `specs/patterns.md` §2 ("Keep it that way until it genuinely hurts").

## Key entry points

- **Light surface** — `preset.color.brightness(brightness - 1.0).ignoresSafeArea()` (WatchContentView.swift:45-47). Dimming is done by applying a *negative* `.brightness` modifier that pulls the color toward black; system screen brightness is never touched.
- **Digital Crown = dimmer** — `.digitalCrownRotation($brightness, from: 0.15, through: 1.0, by: 0.02, sensitivity: .medium)` with `@FocusState` grabbing crown focus on appear (WatchContentView.swift:35, 71-75). The 0.15 floor keeps the glow from going fully black.
- **Tap to cycle color** — `.onTapGesture { cycleColor() }` on a full-screen `contentShape` (WatchContentView.swift:68-69); `cycleColor()` advances `colorIndex` modulo the preset count and flashes the color name for 1.4 s (WatchContentView.swift:81-85). The name renders through `LocalizedStringKey(preset.name)` so it hits the catalog (WatchContentView.swift:58).
- **Feed timer (count-up only)** — `Timer.publish(every: 1).autoconnect()` + `.onReceive` increments `elapsed` (WatchContentView.swift:37, 76); `timeString` formats it as `m:ss` / `h:mm:ss` (WatchContentView.swift:87-91). There is **no auto-off timer on the watch** — that feature is iOS-only.
- **Corner-clock trick** — `TimeHidingOverlay` (WatchContentView.swift:14-23), mounted as `.background(TimeHidingOverlay())` behind the color (WatchContentView.swift:48). watchOS has no public API to hide the always-on system clock in the top corner, but the system hides it whenever a `VideoPlayer` is on screen — so an inert `VideoPlayer(player: nil)` is mounted at `.opacity(0)`, `.disabled(true)`, non-focusable, hit-testing off, accessibility-hidden. This is the only reason `AVKit` is imported; there is no actual video playback and no water-lock usage anywhere in the target.

## Dependencies

The watch target is **source-independent** from the iOS target — it deliberately *duplicates* iOS behaviour rather than sharing a framework (`specs/patterns.md` §3). The duplication is a sync obligation: shared behaviour changes in **both targets in the same PR**.

Mirrored behaviours and their iOS counterparts:

- **Palette** — `WatchPalette.presets` (WatchLight.swift:21-30) mirrors `LightColor.presets` ([LightColor.swift](../../../Baby%20Light/LightColor.swift):25-30): same four sleep-friendly colors, same order, same ids and names (unified 2026-07-10; the fourth preset is `warm-white` / "Warm White" on both targets, matching the App Store description). Note the watch uses RGB literals while iOS uses hex strings.
- **On-light text lightening** — `watchLightened(by:)` (WatchLight.swift:36-44) mirrors iOS `lightened(by:)` (LightColor.swift:38-48): same nudge-each-channel-toward-white algorithm, so the timer text stays readable in the light's own hue.
- **Timer formatting** — `timeString` (WatchContentView.swift:87-91) mirrors `LightViewModel.formatTime(_:)` ([LightViewModel.swift](../../../Baby%20Light/LightViewModel.swift):200-211): `m:ss` under an hour, `h:mm:ss` above.

Related feature folders: `light-screen` (the iOS light surface this mirrors), `feed-timer` (the iOS count-up timer). Nothing depends *on* the watch app.

## Known constraints / invariants

- **The corner clock stays hidden** via the invisible-`VideoPlayer` trick — a named product invariant (`specs/patterns.md` §1). There is no public API for this; **don't remove `TimeHidingOverlay` "because it looks unused"** — the overlay is invisible by design.
- **Dark is sacred** (`specs/patterns.md` §1) — nothing may unexpectedly brighten the screen or present bright UI while the light is in use. The only bright-ish element is the brief color-name flash at 55 % white opacity (WatchContentView.swift:57-64).
- **Sleep-friendly palette only** — new colors go into `WatchPalette.presets` (and `LightColor.presets` in the same PR), nowhere else; no cool/blue/bright presets without an explicit product decision (`specs/patterns.md` §1, §7).
- **Full-bleed color** — the glow ignores the safe area (WatchContentView.swift:47); don't reintroduce gaps.
- **Separate string catalog** — every user-facing watch string must land in the watch's own `Localizable.xcstrings` with all 26 locales filled before release (`specs/patterns.md` §6). Currently the only localized strings are the four color names.
- **No persisted state today** — the watch target has zero `UserDefaults` usage; everything resets when the view is recreated. If persistence is ever added, remember persisted `UserDefaults` keys are permanent API (`specs/patterns.md` §4) — choose names carefully.
- **No shared framework** — do not extract the ~40 duplicated lines into a package (`specs/patterns.md` §3).
- **Test gate is compile-only** — the watch target has no unit/UI tests (`specs/patterns.md` §9); the check is `xcodebuild build -scheme "Baby Light Watch App" -destination 'generic/platform=watchOS Simulator'`.

## Open debts

- The doc comment on `elapsed` says "Seconds since the view appeared / was reset" (WatchContentView.swift:30), but no reset gesture exists in code — the timer only resets when the view is recreated (app relaunch). Whether a reset interaction was intended is unclear from code — confirm with owner.
- No tests of any kind for the watch target; acceptable per house rules, but the timer-formatting mirror has no guard against divergence from iOS.
