---
name: spec-ticket
description: Turn a described feature into a spec folder (requirements, plan, validation) under specs/. Writes only the three spec files — never app code.
when_to_use: Use when the user explicitly wants to spec out a feature — phrasings like "/spec-ticket <description>", "spec out <feature>", "write the spec for X", "create requirements/plan/validation for X". Do NOT fire just because a feature is mentioned in passing — only on an explicit ask to spec it. If something is broken (a defect), use /spec-bug instead.
argument-hint: <short description of the feature>
---

You are preparing a **feature spec** for the Baby Night Light repo from a described piece of work.
You do **not** write app code in this skill — only the three spec files described below.

Work description: $ARGUMENTS

> **Local deltas.** Each step that names a `../spec-shared/references/` file means *read and follow it*.
> This skill's own: the discovery dialogue (Step 3c) and the three spec templates in
> [`references/spec-file-templates.md`](references/spec-file-templates.md).

## Step 0 — Constitution check

Read and follow [`../spec-shared/references/constitution-check.md`](../spec-shared/references/constitution-check.md).

## Step 1 — Intake the work

Read and follow [`../spec-shared/references/intake.md`](../spec-shared/references/intake.md)
(feature path — redirect to `/spec-bug` if the work is actually a defect). Echo the extracted
summary / motivation / AC candidates back to the user for correction before proceeding.

## Step 2 — Derive the folder name

Read and follow [`../spec-shared/references/slug-derivation.md`](../spec-shared/references/slug-derivation.md).
The target directory is finalised after Step 3 (touched-features confirmation).

## Step 3 — Explore the codebase + propose touched feature folders

Read and follow [`../spec-shared/references/codebase-exploration.md`](../spec-shared/references/codebase-exploration.md) —
the light survey and the **Touches features** confirmation (wait for the user). Record the confirmed
list under `requirements.md` → **Touches features**.

## Step 3c — Discovery dialogue (the why, then the use cases)

Read and follow [`references/discovery-dialogue.md`](references/discovery-dialogue.md) — **tiered**:
the **fuller** why + use-case pass when the work touches a user-facing surface (in this app that is
almost everything: the light screen, controls, tutorial, watch app); **lightweight** (a one-line why
+ who-benefits/how-verified) for tooling/infra (CI, `AppStore/` kit) or a thin, crisp request.
Outputs land under **Why this, why now** and (fuller tier) **Users and use cases** in
`requirements.md`, with each AC citing the `US-N` it verifies. Never skip the confirm pass; never
paper over real ambiguity with `[NEEDS CONFIRMATION]` — explore with the user instead.

## Step 4 — Write the three files

Resolve the target directory now (Step 2 decision tree): a confirmed touched feature →
`specs/features/<primary-feature-slug>/<slug>/`; a confirmed tooling/infra "none" → `specs/<slug>/`;
anything ambiguous → confirm the path with the user in one sentence first.

Read and follow [`references/spec-file-templates.md`](references/spec-file-templates.md) — create
exactly `requirements.md`, `plan.md`, `validation.md` inside the resolved directory. No extras, no
README. Fill every section, replace every `<...>` placeholder, and delete any section that genuinely
does not apply (noting why in one line).

## Step 5 — Report

After writing the three files, respond with:

- The folder you created (`specs/features/<feature>/<slug>/` or `specs/<slug>/`).
- One-line summary of the goal.
- Any unresolved open questions copied from `requirements.md` — these are the user's next action.
- **Do not** start implementation. This skill produces a spec only; the user runs `/spec-implement`
  once open questions are resolved.

## Guardrails

- **Never** edit `specs/mission.md`, `specs/tech-stack.md`, or `specs/patterns.md` — the constitution
  is amended by humans.
- **Never** write app code or open a PR from this skill — spec files only.
- If the work conflicts with the constitution (e.g. wants a dependency, analytics, or bright UI over
  the light), flag it under **Open questions**; do not silently deviate.
