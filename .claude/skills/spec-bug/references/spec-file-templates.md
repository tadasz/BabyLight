# Defect spec templates (bug)

Create exactly `requirements.md`, `plan.md`, `validation.md` in the resolved directory. Fill every
section; delete any that genuinely don't apply with a one-line `N/A — <why>`.

## Conciseness contract (applies to all three files)

A bloated spec stops getting read — reviewers skim it and the quality work is wasted. Be tight.

- **Soft budgets** (over → you're restating, not adding): requirements ≤ 150 lines, plan ≤ 120,
  validation ≤ 80. One idea per bullet; prose in ≤3-sentence chunks.
- **Say each fact once**, in one file, referenced (not re-pasted) elsewhere: AC *text* → requirements;
  file paths → Blast radius; root cause / mechanism → requirements; Out of scope → requirements.
- **Cite ACs by id** (`AC1`, `AC2`…) in plan and validation — never repeat the AC sentence.
- **State the root cause once** and never re-derive it; cite each `file:line` at most once per file.
- **Open questions: unresolved/blocking only.** When one resolves, fold the answer into Decisions and
  delete the question — no struck-through list; reference elsewhere as `(OQ2)`.

## `requirements.md`

```markdown
# <Short bug name>

**Spec:** <YYYY-MM-DD-slug> · **Type:** Bug · **Severity:** <user-visible impact in one word or two>
**Reported on:** <app version, e.g. 1.2 (build 22)> · **Build type(s):** <debug / TestFlight / App Store / simulator>

## Summary

<1–2 sentences in the user's words: what they see vs what they expected.>

## Reproduction steps

1. <Exact step — taps/gestures + app state>
2. <Exact step>
3. Expected: …
4. Actual: …

<If steps are unclear, write "Not reproducible with the info so far — see Open questions" and do not fabricate steps.>

## Environment & impact

- Device(s) / OS: <models + iOS/watchOS versions, or simulator> · Locale(s): <if relevant> · Preconditions: <first launch vs returning, controls visible/hidden, timer running, foreground/background transition>
- Frequency: <always / sometimes / rare> · Failure mode: <crash / broken feature / visual / copy / brightness misbehaviour>
- User impact: <who is blocked from doing what — remember the 3 AM context; a bright flash is a severe bug here>

## Evidence

- <Screenshots / recording / crash log top frame — one factual line each; files saved under this folder's references/ if supplied>

## Suspected root cause

<One paragraph (≤4 sentences): the mechanism + the key call site(s), each `file:line` cited once, written as a claim a reviewer can reject. Don't re-derive it elsewhere.>

**Alternatives considered:** <Alt — ruled out because <fact>; Alt — still possible, see (OQ1)> (one line each)

## Blast radius

<Everything the fix could touch or regress — the **edit surface** `/spec-verify`'s Git-Diff gate checks against. Name real paths; every changed code file must be covered here. One line each.>

- Files: <`Baby Light/…`, `Baby Light Watch App/…`> · User flows: <list — e.g. dim-on-close, wake from screen-off, first-run tutorial> · Targets: <iOS / watch / both> · Persisted state that could shift: <UserDefaults keys or none>

## Touches features

<Confirmed with the human in Step 3a. `/spec-implement` reads each README before touching code; `/spec-verify` checks each was updated. `(new)` if a new folder is warranted.>

- `features/<slug>` — <one-line why> · or "none — does not map onto a feature folder"

## Acceptance criteria

<ACs restate the correct behaviour, not the investigation. Derive from "expected". This is the only place AC text lives.>

- [ ] AC1 — <expected behaviour in the reproduction scenario>
- [ ] AC2 — <expected behaviour in a related edge case sharing the root cause>
- [ ] AC3 — no regression in the listed blast-radius flows

## In scope

- Fix for the root cause above
- Regression test(s) that would have caught this bug

## Out of scope

- <adjacent bug or cleanup a reviewer might expect but we're not fixing — one-line reason>

## Decisions

<Non-trivial decisions already made — one line each, rationale tied to mission/tech-stack/patterns.>

- <decision> — because <reason>

## Open questions

<Unresolved/blocking only — each answerable by the owner.>

- <question>
```

## `plan.md`

```markdown
# <Short bug name> — Fix plan

Reference: `<spec-dir>/requirements.md`. Constitution: `specs/{mission,tech-stack,patterns}.md`.

Bugs land in this order: **reproduce → add a failing test → fix → prove the test now passes → guard
the blast radius**. Do not skip "failing test first" unless `requirements.md` says the bug is
untestable with the current harness (brightness, idle timer, and TipKit behaviour often are —
simulators lie about them; say so explicitly and fall back to manual repro).

## 1. Reproduce

Purpose: trigger the bug deterministically before changing anything.

1.1 <Minimal reproduction — failing unit test, UI test, or explicit manual steps on simulator/device <model/OS>, with the exact app state (launch args like `-hasLaunchedBefore NO` where useful).>

Exit criteria: the path reliably exposes the bug on a clean `main` checkout.

## 2. Add the failing test

Purpose: encode the bug as a test that currently fails.

2.1 <Target test file + concrete case name, e.g. `Baby LightTests/Baby_LightTests.swift` → `@Test func timerSurvivesControlCenterInterruption()`>

Exit criteria: the test fails for the right reason (not a compile/unrelated failure) and maps 1:1 to the root cause.

## 3. Fix the root cause

Purpose: minimum diff that makes the failing test pass.

3.1 <Concrete edit — file/symbol + the action; mechanism lives in requirements, don't re-explain it>

Exit criteria: the group-2 test passes; no other tests regress; the unit-test gate in `../spec-shared/references/test-layers.md` is green.

## 4. Guard the blast radius

Purpose: prove the adjacent flows in `requirements.md` → Blast radius didn't break.

4.1 <Per blast-radius flow: reference an existing test or add a smoke test; list manual walkthroughs (device for brightness/idle-timer behaviour).>

Exit criteria: every blast-radius flow has an automated test or an explicit manual check in `validation.md`.

## 5. <Optional — hardening>

Only if the root cause suggests a structurally-preventable class of bugs. If included, note why in
`requirements.md` → Decisions.
```

Guidelines: if the harness genuinely can't express the failing case, say so in Decisions and proceed
with manual repro + verification — never silently. Keep the fix group tiny; if it grows past a file
or two, the hypothesis is probably wrong — stop and re-investigate.

## `validation.md`

```markdown
# <Short bug name> — Validation (merge gate)

## Regression test

- [ ] The group-2 test exists, passes now, and fails if the group-3 fix is reverted (verify by reverting locally, running, re-applying)
- [ ] Test name: `<test function name>` <or "untestable in harness — manual repro per Decisions">

## Acceptance criteria — verification

<Cite each AC by id; do NOT re-paste the text — it lives in requirements.md.>

- [ ] AC1 — verify by: <unit test / UI test / manual simulator or device step with exact state>
- [ ] AC2 — verify by: <…>
- [ ] AC3 (no regression) — verify by: <tests covering the blast radius>

## Reproduction no longer reproduces

- [ ] `requirements.md` → Reproduction steps on <device/OS the bug was reported on> no longer exhibit the bug
- [ ] Tested on a **real device** (not just simulator) if the bug involves screen brightness, the idle timer, TipKit display rules, StoreKit, or scene-phase transitions

## Blast-radius walkthrough

<One checkbox per flow in `requirements.md` → Blast radius. Specific, not generic.>

- [ ] <Flow 1> still works — verified by <test or manual step>

## Standard merge gate

All of [`../../../.claude/skills/spec-shared/references/standard-merge-gate.md`](../../../.claude/skills/spec-shared/references/standard-merge-gate.md) applies (adjust the relative path to the spec folder's depth). List below ONLY bug-specific checks or any standard item that is **N/A** (one line why).
```
