# Test & quality layers (common gates)

The gates shared by `spec-implement` (after each group and at the end) and `spec-verify`
(read-only). `spec-verify` runs **additional** static checks in its own spine (localization
completeness, dependency check, accessibility-identifier integrity, project-file flags); these here
are only the common core.

- **Unit tests:**

  ```sh
  xcodebuild test -project "Baby Light.xcodeproj" -scheme "Baby Night Light" \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
    -only-testing:"Baby Night LightTests"
  ```

  Requires an iOS 26.2+ simulator (deployment target). Report one line per pass; paste output only
  on failure.
- **UI tests** (slower — run when the change touches UI or the spec's validation demands it): the
  same command without `-only-testing`, or with `-only-testing:"Baby Night LightUITests"`.
- **Watch build check** (whenever the watch target or shared behaviour — palette, timer formatting —
  changed):

  ```sh
  xcodebuild build -project "Baby Light.xcodeproj" -scheme "Baby Light Watch App" \
    -destination 'generic/platform=watchOS Simulator'
  ```

- **Running the app** (when a validation step needs eyes on the simulator): build with the scheme
  above, launch via XcodeBuildMCP `launch_app_sim` (**not** raw `xcrun simctl launch` — it hangs on
  this machine), screenshot with `xcrun simctl io <udid> screenshot`.

Stack rules these gates protect (per `specs/tech-stack.md` / `specs/patterns.md`):

- **Zero third-party dependencies** — a new dependency is a constitution-level decision, not a spec
  decision.
- **Every user-facing string** lands in the target's `Localizable.xcstrings` with all 26 locales
  filled before release.
- **Accessibility identifiers** used by `Baby LightUITests/` keep working — they are API.
