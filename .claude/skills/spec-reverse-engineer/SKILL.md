---
name: spec-reverse-engineer
description: Document an existing, already-shipped capability that lacks a specs/features/ folder — read the code and produce the house-format feature folder (README.md, metadata.yaml, changelog.md), file-cited and human-confirmed. Does not change app code.
when_to_use: Use when the user explicitly wants to backfill a feature folder for an existing capability — phrasings like "/spec-reverse-engineer <capability>", "document the light screen as a feature folder", "reverse-engineer a spec for X", "seed the feature folder for X". Read-only on app code; writes only under specs/features/<slug>/. Do NOT fire proactively.
argument-hint: <capability name | file path>
---

# Feature-folder seeder (brownfield)

Take an existing capability that has **no** `specs/features/<slug>/` folder yet and document it in
the house format by **reading the shipped code** — never by guessing. The deliverable is the three
feature-folder files; you do **not** modify app code.

Per `specs/features/README.md`, a feature folder answers *"what does this part of the app do
today"*. This skill produces that from the current implementation, file-cited, for a human to
confirm.

Input: `$ARGUMENTS` — a capability name (e.g. "the controls overlay", "the watch app", "the App
Store kit") or a file path.

## Step 0 — Constitution + contract

Read [`../spec-shared/references/constitution-check.md`](../spec-shared/references/constitution-check.md)
and `specs/features/README.md` (the folder contract: when a folder is warranted, the exact shape,
the authority rule). If the capability does **not** meet the "warrants a folder" bar (no own
screen/surface/persistent flow; a one-off tweak; a pure internal refactor), say so and stop — don't
backfill folders the contract says we shouldn't have.

## Step 1 — Confirm the capability + slug

Restate the capability in one line and propose a slug (`kebab-case`, e.g. `light-screen`,
`controls-overlay`, `watch-app`, `first-run-tutorial`, `app-store-kit`). Check
`specs/features/<slug>/` doesn't already exist (if it does, suggest `/spec-audit <slug>` instead).
Wait for the user to confirm the slug before writing.

## Step 2 — Survey the code (read-only)

This codebase is small (~13 Swift files) — read the relevant files directly; delegate to an
`Explore` subagent only for the `AppStore/` kit or anything genuinely large. Map:

- Entry points (views, view-model methods, scripts), the owning files under `Baby Light/` /
  `Baby Light Watch App/` / `AppStore/`, the state it owns (UserDefaults keys, `@State`), the
  accessibility identifiers it exposes, and any product invariants it enforces
  (`specs/patterns.md` §1).
- Produce a file-cited map (each claim → `file:line`), the **invariants**, the **user-facing
  behaviour**, the **data/state**, and where the code lives. No file dumps.

## Step 3 — Write the three files under `specs/features/<slug>/`

- **`README.md`** — how the capability works *today*: purpose, user-facing behaviour, where the code
  lives, state/persistence, and an **Invariants** section (the rules a future spec must not break —
  cross-reference `patterns.md` §1 instead of re-stating shared invariants). Every non-obvious claim
  cites `file:line`. Prose a new contributor can read in one sitting — not an exhaustive code dump.
- **`metadata.yaml`** — `name`, `status: active`, `owner: tadas`, `files: [...]`,
  `targets: [...]`, `related_features: [...]`, `specs: [...]` (the spec folders you can attribute
  from `git log` / existing `specs/` folders; otherwise `[]`). Paths must be real — `/spec-audit`
  checks them.
- **`changelog.md`** — a single seed line:
  `- <YYYY-MM-DD> NO-SPEC — feature folder seeded by /spec-reverse-engineer from existing code`.

## Step 4 — Report

The folder created, a one-paragraph summary of the capability, the key invariants you captured, and
a note that the human should **confirm the README against their own knowledge** — reverse-engineered
docs are a strong draft, not ground truth, until reviewed. Suggest `/spec-audit <slug>` as the
ongoing drift guard.

## Guardrails

- **Read-only on app code.** The only writes are the three files under `specs/features/<slug>/`.
- **Never invent behaviour** — every claim in the README traces to code you read, cited `file:line`.
  Where the code is ambiguous, say "unclear from code — confirm with the owner" rather than
  guessing.
- Don't `git commit` or stage without an explicit instruction.
