# Standard merge gate (shared)

The invariant checks every spec's `validation.md` inherits, so each one doesn't re-list them. A
generated `validation.md` references this file and writes out **only** spec-specific checks plus any
item here that is N/A for that work (one line why). `/spec-verify` walks both.

## Automated

- [ ] Unit tests pass (`xcodebuild test … -only-testing:"Baby Night LightTests"` — see [`test-layers.md`](test-layers.md))
- [ ] UI tests pass when the diff touches UI (`Baby Night LightUITests`)
- [ ] New tests cover the change — unit for view-model/pure logic, UI for user flows an AC describes end-to-end
- [ ] Watch target still builds if the watch app or shared behaviour (palette, timer formatting) changed

## Localization & strings

- [ ] Every new/changed user-facing string exists in the affected target's `Localizable.xcstrings` with all 26 locales translated (iOS and watch catalogs are separate)
- [ ] Dynamic model-provided strings go through `LocalizedStringKey(...)` (patterns.md §6)

## Manual QA — only the surfaces this diff touches

- [ ] Runs on an iOS 26.2+ simulator; spot-check on a real device for anything involving screen brightness, idle timer, TipKit, or StoreKit (simulators lie about these)
- [ ] The dark-is-sacred invariant holds: nothing new brightens the screen or surfaces bright UI over the light (patterns.md §1)
- [ ] Watch flow spot-checked on a watch simulator (watch changes only)

## Non-regression

- [ ] No `UserDefaults` key renamed, no accessibility identifier renamed/removed (patterns.md §1, §4)
- [ ] No new dependency (no `Package.swift` / `Package.resolved` / Pods appear anywhere)
- [ ] No `<…>` template placeholders or `TODO:` markers left in the spec or the diff

## Release readiness

- [ ] Branch (`feature/…`, `bugfix/…`, or `claude/…`) targets `main`; PR links the spec folder + pastes the AC checklist
- [ ] If user-visible UI changed: note whether App Store screenshots (`AppStore/make_screenshots.py`) and/or store metadata (`AppStore/i18n/`) are owed an update — flag it in the PR, don't let it silently drift
- [ ] Every touched feature folder (`requirements.md` → Touches features) had its `README.md` updated (if behaviour changed) and its `changelog.md` appended, in the same PR
