# Verification report template

Produce a single structured report in this exact shape. Use concrete paths and line numbers — no
handwaving.

```
# Verification report — <spec slug>

**Spec:** <spec-dir>
**Branch:** <branch name>  (base: <detected base>)
**Diff:** <files changed>, <+lines/-lines>
**Working tree clean:** yes | no (<details>)

## Acceptance criteria
- AC1: <verbatim> — ✅ verified by <evidence>
- AC2: <verbatim> — ⚠️ likely verified, missing: <what>
- AC3: <verbatim> — ❌ not verified, because <reason>

## Automated checks
- Unit tests (Baby Night LightTests): <pass|fail>
- UI tests (Baby Night LightUITests): <pass|fail|not run — why>
- Watch build check: <pass|fail|N/A — why>
- Localization completeness (26 locales, per catalog): <complete|list of keys × missing locales>
- iOS↔watch mirror: <in sync|drift — details>
- Dependency changes: <none|list — recorded exception? yes/no>
- Accessibility identifiers: <intact|broken — list>
- Project file / Info.plist / entitlements changes: <none|hunks flagged for manual review>

## Manual checks still owed to the user
- [ ] <item from validation.md that a human must do — device checks for brightness/idle-timer/TipKit especially>
- [ ] <…>

## Spec hygiene
- Placeholders in spec: <none|list>
- Open questions: <none|list>
- Plan tasks not ticked / not deferred: <none|list>
- Touches features listed in requirements.md: <none|list of feature slugs>

## Feature folders (warn-only during rollout)
- README updated for each touched feature: <yes|list of features whose README was not touched>
- Changelog entry appended for each touched feature: <yes|list of features whose changelog did not gain a line>
- README reads as stale (spot-check): <none|list>

## App Store surface
- User-visible UI/copy changed: <no|yes — screenshot/metadata follow-up noted? yes/no>

## Merge verdict
<one of>
  ✅ READY — all ACs verified, automated checks pass, manual checks listed above are the only remaining work.
  ⚠️  NEEDS WORK — <one-line summary of the blocking gap(s)>. Suggested next step: <e.g. "re-run /spec-implement <slug> to close AC2" or "fill the missing de/th translations">.
  ❌ NOT READY — <one-line summary of the blocking failures>.

## Suggested PR
- Title: `<short description from requirements.md>`
- Description skeleton:
  - Spec: <spec-dir>
  - Acceptance criteria checklist pasted from requirements.md
  - <App Store follow-ups, if any>
```
