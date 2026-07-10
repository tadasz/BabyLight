# specs/

This folder is the **spec-driven development workflow** for Baby Night Light. Every feature and non-trivial bug lands through it. (Ported from the Dogo-iOS reference implementation — see the [setup guide](https://dogo-app.atlassian.net/wiki/spaces/DOG/pages/3684925446) — and adapted: this repo has no Jira, so specs are created from a described feature/bug and folders use dated slugs.)

Three kinds of content live here:

1. **Constitution** — durable, repo-wide: what we build, what we build with, how we write code.
2. **Feature folders** — one per long-lived capability (the light screen, the controls overlay, the watch app, …). Describe *how the app works today*. Updated on every spec that changes the capability.
3. **Spec folders** — one per piece of work. Describe *what this one PR scoped and how we verified it*. Written once, never revisited.

Authority rule: **if a feature folder and a spec folder disagree, the feature folder wins for "how it works now"; the spec folder wins for "how the PR was scoped."** A disagreement means somebody skipped updating the feature folder — fix that, don't work around it.

---

## Constitution

| File | Purpose |
|---|---|
| [`mission.md`](mission.md) | Product mission, audience, scope of this repo, operating principles. Answers *what are we building and why*. |
| [`tech-stack.md`](tech-stack.md) | Targets, frameworks, localization, build/test/release surface. Answers *what is it built with*. |
| [`patterns.md`](patterns.md) | Product invariants, architecture, per-layer conventions, anti-patterns. Answers *how do we write code here*. |

These files change rarely and only by deliberate human decision. Agents read them at the start of any non-trivial task — see [`../CLAUDE.md`](../CLAUDE.md).

---

## Feature folders

One folder per long-lived capability, under [`features/`](features/):

```
specs/features/<slug>/
  README.md       // how this capability works today
  metadata.yaml   // structured facts the spec skills read
  changelog.md    // one line per spec that changed this feature
```

Feature folders are created organically — the first time a capability is significant enough that two specs in a row would benefit from reading the same context, add one. We do **not** backfill every existing capability; they accumulate as work flows through them (or via an explicit `/spec-reverse-engineer`). See [`features/README.md`](features/README.md).

---

## Spec folders

One folder per piece of work. Live at one of two paths:

```
specs/features/<feature>/<YYYY-MM-DD>-<short-slug>/   ← common case
  requirements.md   // scope, decisions, context
  plan.md           // numbered task groups
  validation.md     // merge-gate checklist

specs/<YYYY-MM-DD>-<short-slug>/                       ← tooling / infrastructure only
  …same three files
```

- A spec goes **under a feature folder** when it touches a long-lived user-facing capability (the common case). If it touches more than one, it lives under the primary feature; secondary features still get changelog entries.
- A spec stays **at the top level of `specs/`** only when it's purely tooling or infrastructure (CI, App Store kit, spec skills themselves) and does not map to any user-facing feature folder. No catch-all `dev-tooling/` feature folders.
- `<YYYY-MM-DD>` is the date the spec was written; `<short-slug>` is lowercase, hyphenated, ≤ 60 chars, descriptive of the work (not the fix).
- The folder is committed on the branch that implements the work; after merge, it stays as historical context.

---

## The workflow

```
       ┌─────────────────────────────────────────────────────────────┐
       │                                                             │
       ▼                                                             │
  ┌──────────────┐  ┌──────────────┐   ┌────────────────┐  ┌───────────────┐
  │ /spec-ticket │  │ human review │   │ /spec-implement│  │ /spec-verify  │  re-open scope,
  │ /spec-bug    │─▶│ open Qs,     │──▶│ group-by-group │─▶│ merge gate    │─┘ loop again
  └──────────────┘  │ AC refinement│   └────────────────┘  └───────────────┘
                    └──────────────┘                              │
                                                                  ▼
                                                              open PR
```

| Step | Command | What happens |
|---|---|---|
| **1. Intake** | `/spec-ticket <description>` (feature) or `/spec-bug <description>` (defect) | Interviews you about the described work, scans [`features/`](features/) and **proposes which feature folders it touches** (you confirm), creates the spec folder with the three files pre-filled. |
| **2. Human review** | *(no command)* | You resolve every "Open question" in `requirements.md`, refine acceptance criteria, and adjust `plan.md`. Non-negotiable — `/spec-implement` refuses to run with open questions. |
| **3. Implementation** | `/spec-implement <slug>` | Reads the `README.md` of every feature listed under **Touches features**, then runs `plan.md` one task group at a time, pausing after each for review. Follows [`patterns.md`](patterns.md) strictly. Never commits or pushes. |
| **4. Verification** | `/spec-verify <slug>` | Walks `validation.md` against the branch diff, runs `xcodebuild test`, checks localization completeness and the anti-drive-by gate, flags any touched feature whose `README.md`/`changelog.md` wasn't updated, reports `READY` / `NEEDS WORK` / `NOT READY` with a suggested PR title. Read-only. |
| **5. PR** | *(human, or on request)* | Push the branch, open a PR to `main` with `gh`, paste the suggested title/body. |

Upstream of step 1, `/spec-client <concept>` runs a product-level scoping dialogue and writes a `product_brief.md` — useful when the *why* isn't settled yet.

---

## What goes in each spec file

### `requirements.md`

The contract. What we're doing, why, and how we've decided to scope it: summary, goal, acceptance criteria (the single home of AC text), in/out of scope, **Touches features**, affected areas (the declared edit surface), decisions with reasons, open questions (block `/spec-implement` until answered). For bugs, also: reproduction steps, environment, evidence, suspected root cause (file + line), blast radius.

### `plan.md`

The map. Numbered task groups, each landable as a self-contained commit that leaves `main` releasable. Groups ordered by dependency; concrete tasks naming real files/symbols; an exit criterion per group; a Non-goals list. For bugs the order is enforced: **reproduce → failing test first → fix → guard blast radius.**

### `validation.md`

The merge gate. Each AC cited by id with a concrete "verify by" step; the shared [standard merge gate](../.claude/skills/spec-shared/references/standard-merge-gate.md) referenced (not copied); non-regression checks on the blast-radius flows; feature-folder updates confirmed.

---

## Branching and PR conventions

- Features: `feature/<short-slug>` · Bug fixes: `bugfix/<short-slug>` (Claude-worktree branches `claude/<slug>` are also fine — that's how most work here starts).
- PRs target `main` via GitHub (`gh pr create`). The PR description links the spec folder and pastes the AC checklist from `requirements.md`.
- `main` must stay releasable; Xcode Cloud runs tests on PRs and ships TestFlight builds from `main`.

---

## When to skip the workflow

Ad-hoc edits without a spec are only acceptable for:

- one-line fixes (typo, obvious null check, dead code),
- translation-only edits in the `.xcstrings` catalogs or `AppStore/i18n/`,
- urgent fixes to a broken `main` (write the spec folder afterwards if the fix was non-trivial).

Anything larger — including "quick" refactors and "small" feature additions — goes through `/spec-ticket` first. If in doubt, run `/spec-ticket`.

---

## Index of past specs

Spec folders accumulate as work progresses. Browse `specs/features/*/????-??-??-*` and `specs/????-??-??-*` — they're the best reference for how new specs should read.
