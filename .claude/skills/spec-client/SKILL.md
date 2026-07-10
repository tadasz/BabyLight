---
name: spec-client
description: Scope product requirements and use cases with the owner (research-informed) and write a product-level product_brief.md — the "why" and user-facing use cases before any engineering spec. No technical plan, no code.
when_to_use: Use when the user explicitly wants to scope a product concept / write a product brief before specing it for engineering — phrasings like "/spec-client X", "product brief for X", "start product scoping for X", "let's scope this idea first". Do NOT fire just because a feature idea is mentioned — only on an explicit ask to start product scoping.
argument-hint: <free-form concept>
---

# /spec-client — product scoping & use cases

A collaborative, product-level dialogue with the owner to draft the product "why", success
outcomes, and user-facing use cases. The *process* reads the codebase and feature folders so the
dialogue stays grounded; the *deliverable* — `specs/<slug>/product_brief.md` — is **product-level
only**: no code scaffolding, no implementation tasks (those live downstream in `/spec-ticket` →
`/spec-implement`).

**Design intent is captured in words** (plus any reference screenshots the owner supplies) — this
repo has no Figma handoff. The exact pixels get decided during implementation against
`specs/patterns.md`.

## Step 0 — Constitution check

Read [`../spec-shared/references/constitution-check.md`](../spec-shared/references/constitution-check.md).
If the brief proposes something the constitution forbids (a dependency, analytics, bright UI over
the light, a second screen's worth of complexity), surface it under **Open questions** — never
silently reword the constitution. For this app, "does this addition pay for its complexity?" is
*always* a live question — dead simple is the product.

## Step 1 — Understand the status quo (research-only)

Skim `specs/features/` and the relevant sources under `Baby Light/` / `Baby Light Watch App/` so
the Step 2 dialogue is informed by how the app works today. Research only — the brief stays
product-level; do not write code observations into it.

## Step 2 — Parse input & collaborate

1. **Intake:** parse the raw idea from `$ARGUMENTS` + chat.
2. **Drill on the product why** — five layers: **Underlying problem** (the real parent friction),
   **Evidence** (App Store reviews / own experience / support email / intuition, source-named),
   **Success outcome** (verifiable, honest for a solo app — "used nightly for a week", "review
   complaints about X stop"), **Alternatives** (incl. doing nothing), **Assumptions**.
3. **Map the use cases — happy paths plus only the edge cases that change scope.** Draft
   non-technical user stories (job story by default) with product-level ACs — what the parent sees,
   never the mechanism. Probe realistic alternates in dialogue (first launch / controls hidden /
   timer expired / watch / locale), but only the ones that **change a product decision** enter the
   brief. The exhaustive walk is re-derived in `/spec-ticket`'s discovery — duplicating it here is
   the main brief-bloater.
4. **Capture visual intent (visible surfaces only):** ask what it should **look like** — reference
   existing screens ("like the timer-brightness slider row"), look-&-feel in words (layout, density,
   how it behaves in a dark room). Product level only — no fonts, no hex, no file paths.

## Step 3 — Write the product brief

Create `specs/<slug>/product_brief.md` (slug rules as `/spec-ticket`: `YYYY-MM-DD-<short-name>`)
from [`references/product-brief-template.md`](references/product-brief-template.md). Keep it
product-level **and tight** — readable in under a minute, graspable from the TL;DR alone. Lead with
a TL;DR ending in "**Done when** …"; one line per Why bullet; no standalone edge-case list; cut
anything that isn't decision-relevant.

## Step 4 — Report & hand off

Clickable link to `product_brief.md`; the scoped user stories + any scope-changing edge cases; the
key open questions. Note the hand-off: **run `/spec-ticket` next**, where this brief becomes the
richest input to the discovery dialogue.

## Guardrails

- **Product-level only** — no code, no implementation tasks, no design tokens or file paths. If
  you're writing Swift symbols, you've left the brief's altitude.
- **The only file written is `specs/<slug>/product_brief.md`** (+ saved reference images under
  `specs/<slug>/references/` if the owner supplies any). Never touch app code.
- **Never reword the constitution**; constitution conflicts go under **Open questions**.
- Don't commit without explicit confirmation.
