# Tech Stack

The canonical reference for what this repository is built with. If something here drifts from reality, update this file.

## Platform targets

| Target | Platform | Deployment target | Bundle ID |
|---|---|---|---|
| `Baby Night Light` (main app) | iOS | **26.2** | `com.tadas.Baby-Light` |
| `Baby Light Watch App` | watchOS | **11.0** | `com.tadas.Baby-Light.watchkitapp` |
| `Baby Night LightTests` | iOS (unit) | 26.2 | `com.tadas.Baby-LightTests` |
| `Baby Night LightUITests` | iOS (UI) | 26.2 | `com.tadas.Baby-LightUITests` |

Current marketing version: **1.2** (build 14+; check `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in the pbxproj for the live values).

The watch app is embedded in the iOS app (Embed Watch Content phase) but is **standalone-capable and source-independent** — it deliberately shares no code with the iOS target (see `patterns.md`).

## Languages & runtimes

- **Swift** (project `SWIFT_VERSION = 5.0` mode) — SwiftUI throughout; new code uses modern concurrency and the Observation framework.
- **Python 3** — the App Store kit only (`AppStore/make_screenshots.py`, `AppStore/asc/`). Never ships in the app.

## Frameworks & platform APIs

Apple frameworks only — **zero third-party dependencies** is a hard rule (`mission.md`).

- **SwiftUI** — the entire UI, both targets.
- **Observation** (`@Observable` / `@Bindable`) — view-model state ([LightViewModel.swift](../Baby%20Light/LightViewModel.swift)).
- **UIKit (interop only)** — `StatusBarHiddenHostingController` for status-bar/home-indicator hiding ([Baby_LightApp.swift](../Baby%20Light/Baby_LightApp.swift)), `UIScreen.brightness` control via the scene hierarchy.
- **TipKit** — the two-step first-run tutorial ([Tips.swift](../Baby%20Light/Tips.swift)).
- **StoreKit** — `requestReview` rating prompt only; no purchases.
- **AVKit (watch only)** — the invisible `VideoPlayer` that hides the watchOS corner clock ([WatchContentView.swift](../Baby%20Light%20Watch%20App/WatchContentView.swift)).
- **SoundAnalysis + AVFoundation (iOS only)** — opt-in on-device cry detection for the deep-sleep tip: an `AVAudioEngine` microphone tap feeds `SNAudioStreamAnalyzer` running Apple's built-in `SNClassifySoundRequest(.version1)` ([SleepTip/CryDetector.swift](../Baby%20Light/SleepTip/CryDetector.swift)). Audio is classified in memory and never recorded, persisted, or sent anywhere; guarded by `NSMicrophoneUsageDescription`. The App Store privacy label stays "Data Not Collected" (`specs/2026-07-10-deep-sleep-tip`).
- **UserDefaults** — the persistence layer for all settings. The one sanctioned file on disk is the deep-sleep tip's session log, a capped JSON ring buffer in Application Support ([SleepTip/SessionLog.swift](../Baby%20Light/SleepTip/SessionLog.swift), `specs/2026-07-10-deep-sleep-tip`).

## Dependency management

None. No `Package.swift`, no `Package.resolved`, no Pods. If a change appears to need a dependency, that is a constitution-level decision — stop and ask the owner.

## Backend & third-party services

- **None at runtime.** The app makes no network calls.
- **App Store Connect** — TestFlight + App Store releases; automated via the ASC API toolkit in `AppStore/asc/` (see `AppStore/README.md`, `AppStore/RELEASING.md`).

## Localization

- **String Catalogs** — `Baby Light/Localizable.xcstrings` (iOS) and `Baby Light Watch App/Localizable.xcstrings` (watch), **26 locales**: ar, da, de, el, es, es-MX, fi, fr, hi, id, it, ja, ko, lt, nb, nl, pl, pt-BR, ru, sv, th, tr, uk, vi, zh-Hans, zh-Hant.
- Source language is English, written inline in SwiftUI code; Xcode extracts keys into the catalogs at build time. Translations are edited directly in the `.xcstrings` JSON.
- App Store metadata/screenshot localization lives separately under `AppStore/i18n/` — see `AppStore/LOCALIZATION.md` and `AppStore/ADD_A_LANGUAGE.md`.

## Code signing

- Development teams in the pbxproj: `M9YYU2BH36` / `R69X77ZTQS` (per-target). Signing is automatic via Xcode; no fastlane match.

## Build, test & release tooling

- **Xcode** — open `Baby Light.xcodeproj`; the shared schemes are `Baby Night Light` (iOS) and `Baby Light Watch App` (watchOS). There is **no scheme called "Baby Light"** — the folder name differs from the scheme name.
- **Unit + UI tests** (iOS 26.2+ simulator required, e.g. iPhone 17 Pro Max):

  ```sh
  xcodebuild test -project "Baby Light.xcodeproj" -scheme "Baby Night Light" \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
  ```

  Unit tests only (fast loop): append `-only-testing:"Baby Night LightTests"`.
- **Watch build check**:

  ```sh
  xcodebuild build -project "Baby Light.xcodeproj" -scheme "Baby Light Watch App" \
    -destination 'generic/platform=watchOS Simulator'
  ```

- **Simulator gotcha:** raw `xcrun simctl launch` hangs on this machine — launch via XcodeBuildMCP `launch_app_sim`, then capture with `xcrun simctl io <udid> screenshot`.
- **Xcode Cloud** — CI workflows (tests on PRs, TestFlight on `main`); repo-side hooks in `ci_scripts/`.
- **App Store kit** — `AppStore/Makefile` + `make_screenshots.py` render localized screenshots; `AppStore/asc/` scripts drive App Store Connect (metadata, screenshot upload, submission).

## Testing

- **Unit tests** — **Swift Testing** (`@Test`, `#expect`), `@testable import Baby_Night_Light`, in `Baby LightTests/`.
- **UI tests** — **XCUITest** in `Baby LightUITests/`, driven by accessibility identifiers (`lightBackground`, `elapsedTimer`, `controlsOverlay`, `mainLightView`, `timerBrightnessSlider`) and launch arguments (`-hasLaunchedBefore NO` resets first-launch state).
- The watch app currently has no test target — a compile check is its gate.

## Project files to know

| File | Role |
|---|---|
| `Baby Light.xcodeproj` | The project — open this. Uses synchronized folder groups (objectVersion 77): dropping a `.swift` file into a target's folder auto-compiles it. |
| `Baby Light/` | iOS app sources. |
| `Baby Light Watch App/` | watchOS app sources (self-contained). |
| `Baby LightTests/`, `Baby LightUITests/` | Unit / UI tests. |
| `ci_scripts/` | Xcode Cloud hooks. |
| `XCODE_CLOUD_TESTFLIGHT.md` | CI + TestFlight setup guide. |
| `AppStore/` | Screenshot rendering, localized store metadata, ASC API tooling. |
