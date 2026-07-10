---
name: spec-verify
description: Verify a branch against specs/<slug>/validation.md before opening a PR. Read-only — walks each AC against the diff, runs the tests, reports a merge verdict. Does not fix, commit, or push.
when_to_use: Use to run the read-only merge gate on the current branch against its spec — phrasings like "/spec-verify <slug>", "is this branch ready to merge", "run the merge gate", "walk the ACs against the diff". It walks each AC against the diff and runs the test suite, then reports READY / NEEDS WORK / NOT READY. Read-only — it never fixes, commits, or pushes.
argument-hint: <slug | specs/<slug>> (optional — inferred from branch or recent specs if omitted)
---

You are the merge-gate for a feature or fix. Walk the spec's `validation.md` against the current
branch and report what's ready and what's not. **This skill is read-only.** You do not write code,
fix issues, commit, or push. If you find gaps, you report them — the user decides whether to
re-enter `/spec-implement`.

Input: $ARGUMENTS

> **Local deltas.** Each step that names a `../spec-shared/references/` file means *read and follow it*.
> This skill's spine keeps the **repo static-analysis suite** (localization completeness,
> dependency check, accessibility identifiers, project-file flags) and the **report shape**
> ([`references/report-template.md`](references/report-template.md)).

## Step 1 — Resolve the spec

1. If `$ARGUMENTS` is provided (slug / path), match it to a unique folder by searching both layouts
   per [`../spec-shared/references/slug-derivation.md`](../spec-shared/references/slug-derivation.md).
2. Otherwise infer: try the slug embedded in the branch name (`feature/<slug>` / `bugfix/<slug>`),
   then look for a spec folder whose files were touched on this branch's diff.
3. No unique match → stop and ask which spec to verify.

Confirm `requirements.md`, `plan.md`, `validation.md` exist; any missing → stop, nothing to verify
against. Let `<spec-dir>` be the resolved path.

## Step 2 — Load context

Read and follow [`../spec-shared/references/constitution-check.md`](../spec-shared/references/constitution-check.md);
then `<spec-dir>`'s `requirements.md`, `plan.md`, `validation.md`; and for every **Touches features**
entry its `README.md`, `metadata.yaml`, `changelog.md` (for Step 6b).

## Step 3 — Branch & diff survey

Gather via git (no working-tree mutation): current branch (flag if it is `main`); base via
`git merge-base HEAD origin/main` (fallback local `main`); `git diff --name-status <base>..HEAD`;
`git diff --stat <base>..HEAD`; `git log --oneline <base>..HEAD`; `git status --porcelain`
(non-empty → flag; verification runs against committed state). Map changed files to: iOS app
(`Baby Light/`), watch app (`Baby Light Watch App/`), tests, localization catalogs
(`Localizable.xcstrings`), project file (`Baby Light.xcodeproj/`), App Store kit (`AppStore/`),
spec/doc files.

### Git-Diff anti-drive-by gate

Read and follow [`references/git-diff-gate.md`](references/git-diff-gate.md) — cross-check every
code file in the diff against `requirements.md` → **Affected areas of the codebase** (feature) or
**Blast radius** (bug). Any code file not covered by the declared edit surface fails the gate
(report `<path>:<lines>`); enforces CLAUDE.md "no drive-by refactors."

## Step 4 — Walk acceptance criteria

For each AC in `requirements.md`: restate it verbatim; find concrete evidence in the diff or a test
(file+line, test name, UI-test flow, screenshot); classify ✅ **Verified** (evidence + automated/clear
manual check) / ⚠️ **Likely verified** (code matches, nothing covers it) / ❌ **Not verified**. Never
mark an AC verified from the spec alone — the diff must back it up.

## Step 5 — Walk validation.md

Go through every checkbox. Automated → run it or inspect the artifact, report the actual result;
manual → state exactly what the human still needs to do (don't tick on their behalf);
non-regression → grep/read the touched files, claim only what you inspected.

### Common gates (run these)

Run the gates in [`../spec-shared/references/test-layers.md`](../spec-shared/references/test-layers.md) —
unit tests (capture pass/fail), UI tests if the diff touches UI, the watch build check if the watch
target or shared behaviour changed.

### Repo static checks (this skill's own suite — no code execution beyond git/grep/read)

- **Localization completeness** — for every new/changed user-facing string literal in the diff's
  Swift files, confirm a matching key exists in the affected target's `Localizable.xcstrings` **and**
  carries translations for all 26 locales (parse the JSON; count `localizations` per key). Missing
  locales fail the check. Remember the iOS and watch catalogs are separate.
- **iOS↔watch mirror** — if the diff changes shared behaviour (palette, timer formatting) in one
  target only, flag it (patterns.md §3).
- **Dependencies** — if a `Package.swift`, `Package.resolved`, `Podfile`, or any vendored source
  appears anywhere in the diff, fail the check (zero-dependency rule) unless `requirements.md` →
  **Decisions** records an owner-level exception.
- **Accessibility identifiers** — grep `Baby LightUITests/` for every identifier it queries; confirm
  each still exists in the app sources. A removed/renamed identifier fails the check.
- **Project file / entitlements** — if `project.pbxproj`, any `Info.plist`, or `.entitlements`
  changed, flag each hunk for manual review (signing, targets, build settings are owner territory).
- **Placeholders** — grep the diff and the spec folder for `<...>` template leftovers and `TODO:`
  markers introduced by this branch. Any hit in committed code fails; hits in the spec folder are a
  warning.
- **App Store surface** — if user-visible UI or copy changed, check whether the spec/PR notes the
  screenshot/metadata follow-up (`AppStore/`); missing note is a warning.

## Step 6 — Spec hygiene

Check the spec folder: no `<...>` placeholders in the trio; **Open questions** empty or answered;
every `plan.md` task ticked (✅) or explicitly deferred; `validation.md` checkboxes reflect reality.
Report failures — do not edit the spec to "fix" them.

## Step 6b — Feature-folder check

For every **Touches features** entry: confirm the folder exists with its three files; check the diff
touched its `README.md` if behaviour changed; check a `changelog.md` line was appended referencing
this spec; spot-check the README still describes current behaviour. During the rollout these two
items (README updated, changelog appended) are **warnings**, not hard blocks — report them under the
verdict as `⚠️ NEEDS WORK` but do not downgrade an otherwise-`READY` verdict on their own. If
**Touches features** is missing from `requirements.md`, flag it as Step 6 hygiene breakage (means
the touched-features step was skipped).

## Step 7 — Report

Produce the report in the exact shape of
[`references/report-template.md`](references/report-template.md), with concrete paths and line
numbers — no handwaving.

## Guardrails

- **Read-only.** Never edit code, specs, commits, or the working tree. Running `xcodebuild test` is
  allowed; it writes only to derived data.
- **Never push, commit, amend, or open a PR.** The report ends with a *suggested* PR title/body —
  the user creates the PR.
- **Do not mark ACs verified from the spec alone.** Evidence must be in the diff or a passing test.
- **Do not fix problems you find.** Report them precisely so the user can loop back into
  `/spec-implement`. If the user asks you to fix during verification, stop verification and exit.
- If the current branch has no diff against `main`, the report is a one-liner: "No changes on this
  branch — nothing to verify."
