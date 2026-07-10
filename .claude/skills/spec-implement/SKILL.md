---
name: spec-implement
description: Implement a previously-written spec under specs/<slug>/ group-by-group, validation-gated. The spec is the contract — does not re-decide scope.
when_to_use: Use when the user explicitly wants to execute an existing spec's plan — phrasings like "/spec-implement <slug>", "implement the spec for <slug>", "build out specs/<slug>". Requires an existing spec folder and pauses for approval between groups. Do NOT fire proactively or start writing code on your own — only on an explicit ask to implement a spec.
argument-hint: <slug | specs/<slug> | specs/features/<f>/<slug>>
---

You are implementing a previously-written spec for the Baby Night Light repo. The spec is the
contract — **you do not re-decide scope here**. If the spec is wrong, stop and tell the user; don't
silently deviate.

Input: $ARGUMENTS

> **Local deltas.** Each step that names a `../spec-shared/references/` file means *read and follow it*.
> This skill's own core: the **precondition gate**, the **group-by-group loop**, the feature-folder
> updates, and the **never-commit-without-instruction** stance.

## Step 1 — Resolve the spec folder

Accept a slug (or fragment) or a `specs/<slug>` / `specs/features/<f>/<slug>` path. Resolve to a
single directory by searching **both layouts** per
[`../spec-shared/references/slug-derivation.md`](../spec-shared/references/slug-derivation.md)
(§Resolve the target directory) — `find specs -type d -name '*<fragment>*'`. Zero or multiple
matches → stop and ask the user to disambiguate.

Verify `requirements.md`, `plan.md`, `validation.md` all exist. If any is missing, tell the user to
run `/spec-ticket` or `/spec-bug` first, and stop. Let `<spec-dir>` be the resolved path.

## Step 2 — Load everything

Read in order and keep in working memory: (1) follow
[`../spec-shared/references/constitution-check.md`](../spec-shared/references/constitution-check.md);
(2–4) `<spec-dir>/requirements.md`, `plan.md`, `validation.md`; (5) for every feature listed in
`requirements.md` → **Touches features**, its `specs/features/<slug>/README.md` + `metadata.yaml` —
they encode invariants the spec author may not have repeated. If **Touches features** is missing or
empty, flag it as a Step 3 precondition failure.

## Step 3 — Precondition gate

Do not start editing code until all hold; if any fails, report what's blocking and stop:

- [ ] **Open questions** empty, or every question answered beneath it.
- [ ] **Acceptance criteria** non-empty and specific (no `<...>` / "TBD").
- [ ] **Touches features** present and deliberate (a list or "none"). Missing → ask, don't guess.
- [ ] `plan.md` has ≥1 numbered group with concrete tasks.
- [ ] You understand which files under `Baby Light/` / `Baby Light Watch App/` / tests / `AppStore/`
      are affected (grep now if not).
- [ ] The branch is not `main`. If it is, **ask the user** before creating
      `feature/<short-slug>` (or `bugfix/<short-slug>` for a bug spec). A `claude/…` worktree branch
      is fine as-is. Do not switch branches silently.

## Step 4 — Execute task groups (one at a time, in order)

### 4a. Confirm the group

Before touching code for group *N*: re-read it; list the files you expect to edit/create (one line +
reason each); list reuses you'll apply (existing presets/extensions like `Color.lightened(by:)`,
existing view-model methods, existing test helpers — minimal new code); list anything in this
group's scope you'll **deliberately not do** if it would exceed the spec. Paste the summary in chat,
then proceed.

### 4b. Implement

- Make the minimum diff the group requires. No drive-by refactors, no speculative abstractions, no
  comments that narrate the obvious. Match neighbouring style — read the canonical files first.
- Honour the constitution (read in Step 2): **zero new dependencies**; every user-facing string into
  the affected target's `Localizable.xcstrings` (both catalogs when both targets change); shared
  iOS↔watch behaviour mirrored in both targets (patterns.md §3); the dark-is-sacred and full-bleed
  invariants (patterns.md §1); accessibility identifiers preserved and added for new testable UI.

### 4c. Build & test

After each group, run the gates in
[`../spec-shared/references/test-layers.md`](../spec-shared/references/test-layers.md) (unit tests;
watch build check when relevant). Fix failures before moving on — do not accumulate broken state
across groups.

### 4d. Tick checkboxes + update touched feature folders

- In `plan.md`, add a ✅ before each completed task line in group *N* (keep the text intact; never
  delete tasks).
- In `validation.md`, tick only items you've actually verified now.
- For every feature in **Touches features** whose behaviour changed this group: edit its
  `specs/features/<slug>/README.md` to reflect the new behaviour and append one line to its
  `changelog.md` (`- YYYY-MM-DD <spec-slug> — <short description>`), **in the same change** as the
  code. If **Touches features** is `none`, skip this step.

### 4e. Pause

After each group completes cleanly, stop and report: what landed (files + one-line summary), reuses
applied, exit criteria now met, anything surprising, the next group name. **Wait for the user to say
"continue" before starting the next group.** Exception: if the user said "implement all groups" up
front, proceed through groups without pausing but still report after each, and always stop on a
genuine blocker.

## Step 5 — Validate

When all groups are complete: walk `<spec-dir>/validation.md` top-to-bottom, verifying each
unchecked item now (run the test, check the simulator via `launch_app_sim`, inspect the diff) and
ticking it, or explaining why it's blocked. Run the full unit-test gate once more even if individual
groups ran tests; run the UI tests if the diff touched UI. Fix any failing automated check before
moving on; this is the merge gate.

## Step 6 — Final report

Summarize: spec implemented (`<spec-dir>`); branch; diff overview (targets touched, rough line
counts); every AC from `requirements.md` marked done + how verified; every `validation.md` item done
or explicitly outstanding with reason; new strings and their catalog/locale status; whether App
Store screenshots/metadata are owed an update; suggested PR title (`<short description>`); PR
description skeleton (spec folder link, AC checklist).

## Guardrails

- **Never** edit `specs/mission.md`, `specs/tech-stack.md`, or `specs/patterns.md` from this skill —
  the constitution. If the spec seems to require it, stop and tell the user.
- **Never** re-open scope that `requirements.md` → **Out of scope** excluded. If something out of
  scope genuinely blocks the work, stop and ask — don't expand silently.
- **Never** skip the Step 3 precondition gate to "save time."
- **Never** run `git commit`, `git push`, `git commit --amend`, or any destructive git operation
  without an explicit user instruction. Do not open a PR — the report ends with a *suggested*
  title/body.
- If `validation.md` and `requirements.md` disagree, treat `requirements.md` as authoritative and
  flag the mismatch.
