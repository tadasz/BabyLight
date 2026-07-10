---
name: spec-bug
description: Turn a described defect into a defect spec folder (requirements, plan, validation). Captures what's broken, the suspected root cause, and how we'll know the fix works without regressing. Writes only the three spec files — never app code.
when_to_use: Use when the user explicitly wants to spec a defect — phrasings like "/spec-bug <description>", "spec this bug", "write the bug spec for X". Do NOT fire when asked to just fix something, and NOT on every mention that something is broken — only on an explicit ask to spec the defect. If the work is a new feature, use /spec-ticket instead.
argument-hint: <short description of the defect>
---

You are preparing a **defect spec** for the Baby Night Light repo from a described bug. You do
**not** write app code in this skill — only the three spec files. A bug is not a feature: the spec
must capture *what is broken*, *why it is broken* (suspected root cause), and *how we will know the
fix works without regressing something else*. Do not jump to a fix.

Defect description: $ARGUMENTS

> **Local deltas.** Each step that names a `../spec-shared/references/` file means *read and follow it*.
> This skill's own core: the **root-cause investigation** (Step 3) and the reproduction-first
> templates in [`references/spec-file-templates.md`](references/spec-file-templates.md).

## Step 0 — Constitution check

Read and follow [`../spec-shared/references/constitution-check.md`](../spec-shared/references/constitution-check.md).

## Step 1 — Intake the defect

Read and follow [`../spec-shared/references/intake.md`](../spec-shared/references/intake.md)
(**bug path** — confirm the work is a defect; if it's actually a feature request, stop and suggest
`/spec-ticket`; establish reproduction steps, expected vs actual, environment, frequency, and any
evidence the user can supply). If reproduction is unclear, state so under **Open questions** — do
not invent steps.

## Step 2 — Derive the folder name

Read and follow [`../spec-shared/references/slug-derivation.md`](../spec-shared/references/slug-derivation.md) —
keep the slug descriptive of the **defect**, not the fix. The target directory is finalised after
Step 3a.

## Step 3 — Investigate the suspected root cause

Do enough **read-only** investigation to propose a *hypothesis* for the root cause, with the
files/symbols that likely contain it. Use
[`../spec-shared/references/codebase-exploration.md`](../spec-shared/references/codebase-exploration.md)
for the survey, then:

1. Grep/read for directly relevant symbols — view-model methods, presets, UserDefaults keys, scene-
   phase handlers, the text visible to the user.
2. Read the neighbouring code to understand the current behaviour. Cite file paths + line numbers in
   the spec. Pay special attention to the documented platform quirks (`specs/patterns.md` §1) —
   several "bugs" in this app's history were iOS lifecycle traps (e.g. brightness writes dropped in
   background).
3. If the user supplied a crash log, extract the top symbolicated frame and reference it.
4. Time-box this: if you can't form a plausible hypothesis in ~15 minutes of reading, record it as an
   open question rather than speculate. You may propose **more than one hypothesis** — mark the most
   likely, keep the alternatives (they guide the plan and the regression tests).

## Step 3a — Propose touched feature folders (confirm before writing the spec)

Read and follow [`../spec-shared/references/codebase-exploration.md`](../spec-shared/references/codebase-exploration.md) →
**Propose touched feature folders**. Wait for the user's confirmation and record the list under
`requirements.md` → **Touches features** (required — a missing list fails `/spec-implement`'s
precondition gate).

## Step 4 — Write the three files

Resolve the target directory (Step 2 decision tree): a confirmed touched feature →
`specs/features/<primary-feature-slug>/<slug>/`; a confirmed tooling/infra "none" → `specs/<slug>/`;
anything ambiguous → confirm the path with the user first.

Read and follow [`references/spec-file-templates.md`](references/spec-file-templates.md) — create
exactly `requirements.md`, `plan.md`, `validation.md` inside the resolved directory. Fill every
section, replace every `<...>`, and delete any section that genuinely does not apply (with a
one-line note why). The plan is **reproduction-first**: reproduce → add a failing test → fix →
prove it passes → guard the blast radius.

## Step 5 — Report

After writing the three files, respond with: the folder you created; a one-line restatement of the
defect; the suspected root cause with file + line reference; unresolved open questions copied from
`requirements.md` (the user's next action). **Do not** start implementation — the user runs
`/spec-implement` once open questions are resolved.

## Guardrails

- **Never** edit `specs/mission.md`, `specs/tech-stack.md`, or `specs/patterns.md` — the constitution.
- **Never** write app code or open a PR from this skill — spec files only.
- Keep the fix scope honest: if the suspected fix would grow beyond a file or two, the hypothesis is
  probably wrong — note it and re-investigate rather than expanding scope.
- If the description lacks reproduction, say so under **Open questions** — do not fabricate steps.
