# Mission

## Product

**Baby Night Light** turns an iPhone (and Apple Watch) into a sleep-friendly night light for parents settling a baby at night. A full-screen red/amber glow, an auto-off timer, a glanceable count-up "feed timer", and gesture-only brightness control — nothing that lights up the room or wakes anyone.

## Audience

Parents doing night feeds, nappy changes, and check-ins in a dark nursery — usually one-handed, half-asleep, with a phone they already own instead of a dedicated night-light gadget.

## Core value propositions

- **Sleep-science colors** — red and warm amber presets minimize melatonin disruption for baby *and* parent.
- **Dead simple** — one screen; double-tap for controls, swipe to dim. No accounts, no settings maze.
- **Feed timer** — a count-up elapsed timer in the same hue as the light, readable across a dark room.
- **Auto-off timer** — 15m/30m/1h/2h presets that fade the screen to black.
- **Smart brightness** — maximum on open, minimum on close (both optional), so the phone never blinds anyone at 3 AM.
- **Wrist-sized glow** — a standalone Apple Watch app for check-ins without picking up the phone.
- **Private by design** — no analytics, no tracking, no network calls, no third-party code. This is a feature, not an omission.

## Scope of this repository

This repository is the entire product. It ships:

- The **Baby Night Light** iOS app (target `Baby Night Light`, scheme `Baby Night Light`).
- The standalone **Baby Light Watch App** (watchOS), embedded in the iOS app but fully self-contained.
- The **App Store kit** under `AppStore/` — screenshot rendering, localized metadata, and App Store Connect API tooling for submissions across 26 locales.

## What this repository is not

- No backend, no web app, no Android. There is nothing server-side to this product.
- No paid tier, subscriptions, or in-app purchases (the only StoreKit use is the native rating prompt).
- Not a white-noise/sound app — light only.

## Operating principles

How this repo is actually operated today; stay consistent with these unless the owner explicitly decides otherwise.

- **Solo-maintained, agent-heavy.** One human owner (Tadas); most changes are authored with Claude in git worktrees and land as squash-merged GitHub PRs.
- **Releasable `main`.** Work happens on short-lived branches and merges to `main` via PR. `main` must always build and pass tests.
- **CI via Xcode Cloud.** Test and TestFlight workflows run in Xcode Cloud (`ci_scripts/`, see `XCODE_CLOUD_TESTFLIGHT.md`); App Store submissions are driven by the ASC API toolkit in `AppStore/asc/`.
- **Zero dependencies.** No SPM packages, no CocoaPods, no vendored third-party code. Apple frameworks only.
- **Everything localized.** 26 locales via String Catalogs (`Localizable.xcstrings` in each app target). A user-facing string that ships in English only is a bug.
- **Dark is sacred.** Nothing may unexpectedly brighten the screen or surface bright UI while a parent is settling a baby (see `patterns.md` → product invariants).
