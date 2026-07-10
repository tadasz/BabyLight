# CLAUDE.md — Baby Night Light agent rulebook

This file is loaded into every Claude Code session for this repository. Follow it. It overrides general instincts when they conflict.

## 1. Constitution

Three files are the source of truth for *what* this project is, *what* it's built with, and *how* we write code here. Read them at the start of any non-trivial task:

- [`specs/mission.md`](specs/mission.md) — product mission, scope of this repo, operating principles.
- [`specs/tech-stack.md`](specs/tech-stack.md) — targets, frameworks, localization, build/test tooling.
- [`specs/patterns.md`](specs/patterns.md) — product invariants, house style, per-layer conventions.

If a request conflicts with any of them, **stop and flag it** — do not silently deviate.

### Feature folders — read these before scoping work

Before scoping or implementing anything, scan [`specs/features/`](specs/features/) — one subfolder per long-lived capability. Each folder's `README.md` describes how that part of the app works today; `metadata.yaml` and `changelog.md` give a quick history. See [`specs/features/README.md`](specs/features/README.md) for the folder shape. (The folder starts empty at bootstrap; subfolders accumulate as specs land.)

- When the task **touches an existing feature folder**, read its `README.md` first — it encodes invariants specs must not break.
- When the task **changes a feature's behaviour**, update its `README.md` and append a line to its `changelog.md` **in the same PR** that changes the code. Letting the folder drift is a bug.
- If a feature folder and a spec folder disagree, the feature folder wins for "how it works now"; the spec folder wins for "how that PR was scoped."

## 2. How work flows here

This repo runs on **spec-driven development**. Every feature or non-trivial bug follows the same three-step loop:

1. **`/spec-ticket <description>`** (or **`/spec-bug <description>`** for a defect) — produces a spec folder with `requirements.md`, `plan.md`, and `validation.md`.
2. **Human review** — the user resolves open questions, refines acceptance criteria, adjusts the plan. Do not skip this.
3. **`/spec-implement <slug>`** — executes `plan.md` group-by-group, gated by the precondition checks and `validation.md` at the end.

Operate in this loop by default. Ad-hoc edits outside a spec are only acceptable for:
- one-line fixes (typo, obvious null-check, dead code),
- translation-only edits in the `.xcstrings` catalogs or `AppStore/i18n/`,
- responding to a direct user instruction that is explicit about not wanting a spec.

When in doubt, ask whether to run `/spec-ticket` first.

## 3. Non-negotiables

### Scope

- **No drive-by refactors or cleanups.** A bug fix does not need surrounding tidy-up. A one-shot change does not need a helper.
- **No speculative abstraction.** Three similar lines beat a premature generic. This app's value is that it stays small.
- **No scope expansion past `requirements.md` → "Out of scope".** If something there genuinely blocks the work, stop and ask.

### Product invariants (see `specs/patterns.md` §1 for the full list)

- **Dark is sacred** — nothing may unexpectedly brighten the screen or present bright UI while the light is in use.
- **Full-bleed color** — never break the status-bar/safe-area suppression.
- Sleep-friendly palette only; the watch corner-clock trick stays; accessibility identifiers are API.

### Tech stack rules

- **Zero third-party dependencies.** No SPM packages, no Pods, no vendored code — ever, without an owner-level decision recorded in a spec.
- **Every user-facing string is localized** — inline English extracted into the target's `Localizable.xcstrings`, all 26 locales filled before release. iOS and watch catalogs are separate.
- **iOS↔watch duplication is deliberate** — shared behaviour (palette, timer formatting) changes in both targets in the same PR; no shared framework.
- No analytics, tracking, networking, or accounts — privacy is a value proposition.
- Persisted `UserDefaults` keys are permanent API — never rename them.

### Code style

- Match neighbouring file style (2-space indent). Read the canonical files before guessing at a pattern.
- Comments explain non-obvious *why* — platform quirks, hidden invariants, workarounds. No narration, and never reference the current task/PR in comments.
- No half-finished implementations, no placeholder `// TODO: wire this up later`.

### Git & release

- Work on short-lived branches (`feature/<slug>`, `bugfix/<slug>`, or `claude/<worktree-slug>`); PRs target **`main`** via GitHub (`gh`).
- `main` must stay releasable — Xcode Cloud tests PRs and ships TestFlight builds from `main`.
- **Never** run `git commit`, `git push`, `git commit --amend`, `git reset --hard`, or any destructive git operation without an explicit user instruction. Commits are the user's call.
- App Store submissions run through the toolkit in `AppStore/asc/` (see `AppStore/RELEASING.md`) — never submit on your own initiative.

### Build & tools

- Open **`Baby Light.xcodeproj`**. The iOS scheme is **`Baby Night Light`** (not "Baby Light"); the watch scheme is `Baby Light Watch App`.
- Tests: `xcodebuild test -project "Baby Light.xcodeproj" -scheme "Baby Night Light" -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'` (add `-only-testing:"Baby Night LightTests"` for the fast unit loop). Requires an iOS 26.2+ simulator.
- **Simulator gotcha:** raw `xcrun simctl launch` hangs on this machine — use XcodeBuildMCP `launch_app_sim`, then `xcrun simctl io <udid> screenshot`.
- Launch args: `-hasLaunchedBefore NO` shows the first-run controls; `YES` hides them.
- The project uses synchronized folder groups — a `.swift` file dropped into a target's folder auto-compiles; don't hand-edit `project.pbxproj` for file adds.

## 4. Skills

The SDD skills live under `.claude/skills/<name>/SKILL.md` (each a thin spine that reads on-demand `references/*.md`). They share a passive container, **`spec-shared`** — not invocable on its own; it holds the common building blocks (constitution check, work intake, slug derivation, codebase exploration, test gates, standard merge gate).

**Core loop:**

- **`/spec-ticket <description>`** — create a feature spec folder from a described feature. Confirms touched feature folders and runs a tiered discovery dialogue before writing `requirements.md`/`plan.md`/`validation.md`.
- **`/spec-bug <description>`** — same, but tuned for defects (root-cause hypothesis, reproduction, failing test first, fix, guard blast radius).
- **`/spec-implement <slug>`** — execute an approved spec, one plan group at a time, validation-gated. Never commits, pushes, or opens a PR.
- **`/spec-verify <slug>`** — read-only merge gate. Walks `validation.md` against the diff, runs tests, checks localization completeness, dependencies, accessibility identifiers, and the anti-drive-by gate; reports `READY` / `NEEDS WORK` / `NOT READY` with a suggested PR title.

**Supporting:**

- **`/spec-client <concept>`** — product-level scoping (the "why" + use cases) → `product_brief.md`, upstream of `/spec-ticket`.
- **`/spec-audit [<feature> | all]`** — read-only audit of `specs/features/*` against the code; writes `specs/drift-report.md`. Find drift; don't fix it.
- **`/spec-reverse-engineer <capability>`** — backfill a `specs/features/<slug>/` folder for an existing, undocumented capability by reading the shipped code, file-cited.

Check `.claude/skills/` for the authoritative list — do not invent skills that don't exist.

## 5. When you're unsure

- If the task is larger than a one-liner and there is no spec: propose running `/spec-ticket` first.
- If a decision changes something described in `specs/mission.md`, `specs/tech-stack.md`, or `specs/patterns.md`: stop and ask — the constitution is amended by humans, not by agents.
- If `requirements.md` and `validation.md` disagree: treat `requirements.md` as authoritative and flag the mismatch.
- If you're about to do something destructive, visible to others, or hard to reverse (push, force-push, close a PR, submit to App Store, drop data): confirm first.

## 6. Environment quick-reference

- Xcode project: `Baby Light.xcodeproj` · schemes `Baby Night Light` (iOS 26.2) / `Baby Light Watch App` (watchOS 11).
- Unit tests: Swift Testing in `Baby LightTests/`. UI tests: XCUITest in `Baby LightUITests/` (identifier-driven).
- CI: Xcode Cloud (`ci_scripts/`, `XCODE_CLOUD_TESTFLIGHT.md`).
- App Store kit: `AppStore/` (screenshots `make_screenshots.py`, metadata `i18n/`, ASC API `asc/`, guides `README.md`/`RELEASING.md`).
