# Feature spec templates (ticket)

Create exactly `requirements.md`, `plan.md`, `validation.md` in the resolved directory. Fill every
section; delete any that genuinely don't apply with a one-line `N/A — <why>`.

## Conciseness contract (applies to all three files)

A bloated spec stops getting read — reviewers skim it and the quality work is wasted. Be tight.

- **Soft budgets** (over → you're restating, not adding): requirements ≤ 150 lines, plan ≤ 120,
  validation ≤ 80. One idea per bullet; prose in ≤3-sentence chunks.
- **Say each fact once**, in one file, referenced (not re-pasted) elsewhere: AC *text* → requirements;
  file paths → Affected areas; mechanism → requirements; Out of scope → requirements.
- **Cite ACs by id** (`AC1`, `AC2`…) in plan and validation — never repeat the AC sentence.
- **Domain language in requirements, implementation language in the plan** — don't explain the
  mechanism in both.
- **Cite each `file:line` at most once per file**, at first mention.
- **Open questions: unresolved/blocking only.** When one resolves, fold the answer into Decisions and
  delete the question — no struck-through list; reference elsewhere as `(OQ2)`.

## `requirements.md`

```markdown
# <Short feature name>

**Spec:** <YYYY-MM-DD-slug> · **Requested by:** <who asked / where the idea came from>

## Why this, why now

<From discovery (Step 3c). Lightweight tier → first three bullets only.>

- **Problem:** <friction today, not the solution>
- **Evidence:** <how we know it matters now, source-named>
- **Success:** <verifiable signal post-ship — an outcome, not an output>
- **Alternatives:** <incl. doing nothing — option → verdict, one line each>
- **Assumptions:** <1–3 falsifiable, only if load-bearing>

## Users and use cases

<Fuller tier only (user-facing surface); else "N/A — tooling/infra". Each story is the smallest independently-testable slice; each AC below cites its US-N.>

### US-1 — <title> (P1)
When <situation>, the <named actor> wants to <motivation>, so they can <outcome>.
- Given <state>, when <action>, then <expected>.

## Goal

<One verifiable sentence.>

## Acceptance criteria

<The canonical AC list — the ONLY place AC text lives. Confirmed with the user in intake/discovery. Fuller tier: "AC1 (US-1) — …".>

- [ ] AC1 — …
- [ ] AC2 — …

## In scope

<Behaviour/outcome bullets — NO file paths (those live in Affected areas). ≤6 bullets.>

- <change 1>

## Out of scope

- <thing a reviewer might expect that we're not doing — one-line reason>

## Touches features

<Confirmed in Step 3. `/spec-implement` reads each README before touching code; `/spec-verify` checks each was updated. `(new)` if a new folder is warranted.>

- `features/<slug>` — <one-line why> · or "none — does not map onto a feature folder"

## Affected areas of the codebase

<The **edit surface** `/spec-verify`'s Git-Diff gate checks against — the SINGLE home of file paths. Every changed code file must be covered. One line each.>

- iOS app: `Baby Light/<File>.swift` — <what changes>
- Watch app: `Baby Light Watch App/<File>.swift` — <what changes / N/A> (remember patterns.md §3: shared behaviour changes hit both targets)
- Tests: `Baby LightTests/…` / `Baby LightUITests/…` — <what changes>
- Localization: `Localizable.xcstrings` (iOS / watch) — <new keys / N/A> · App Store kit: `AppStore/…` — <what / N/A>

## Design

<No UI → "N/A — no UI". Else, in words + any reference screenshots the user supplied (saved under this folder's references/): layout and placement; visibility rules; how it behaves in the dark-room context (patterns.md §1); copy (exact strings — these become xcstrings keys); edge states (first launch, controls hidden, timer expired, watch).>

## Decisions

<Non-trivial decisions already made — one line each, rationale tied to mission/tech-stack/patterns.>

- <decision> — because <reason>

## Open questions

<Unresolved/blocking only — each answerable by the owner.>

- <question>
```

## `plan.md`

```markdown
# <Short feature name> — Implementation plan

Reference: `<spec-dir>/requirements.md`. Constitution: `specs/{mission,tech-stack,patterns}.md`.

## 1. <Task group title>

Purpose: <one sentence — what this group accomplishes>

1.1 <verb-first task — names a file/symbol + the action; the mechanism/why lives in requirements, don't re-explain it>
1.2 <…>

Exit criteria: <builds / a named test passes / a screen renders>

## 2. <…>

Purpose: <…>

2.1 <…>

Exit criteria: <…>

## Non-goals for this plan

<Plan-specific sequencing boundaries ONLY. Scope non-goals live in requirements → Out of scope; don't restate them.>
```

Guidelines: order by dependency (model/state → view model → view → wiring → localization → tests);
each group lands as one reviewable commit; name real files/symbols, or `TBD — locate <x>` rather
than inventing a path. If behaviour is shared with the watch app, the mirror-update is its own task,
not an afterthought.

## `validation.md`

```markdown
# <Short feature name> — Validation (merge gate)

## Acceptance criteria — verification

<Cite each AC by id; do NOT re-paste the text — it lives in requirements.md.>

- [ ] AC1 — verify by: <unit test / UI test / manual simulator step / screenshot>
- [ ] AC2 — verify by: <…>

## Standard merge gate

All of [`../../../.claude/skills/spec-shared/references/standard-merge-gate.md`](../../../.claude/skills/spec-shared/references/standard-merge-gate.md) applies (adjust the relative path to the spec folder's depth). List below ONLY:

- spec-specific checks beyond the per-AC verify-by above;
- any standard item that is **N/A** for this work (one line why).

## Non-regression

- [ ] Existing flows touched still work — <list only the flows this diff can break>
```
