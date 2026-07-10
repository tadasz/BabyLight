# Product brief template

Create `specs/<slug>/product_brief.md`. Product-level and tight — readable in under a minute,
graspable from the TL;DR alone. Fill every section; cut anything not decision-relevant.

```markdown
# <Concept name> — Product brief

**Spec:** <YYYY-MM-DD-slug> · **Stakeholder:** <who this was scoped with>

## TL;DR

<2–3 sentences: the concept and who it's for. End with:> **Done when** <the verifiable signal that says this shipped successfully>.

## Why

- **Problem:** <the real parent friction today — not the solution>
- **Evidence:** <reviews / own experience / support email / intuition, source-named>
- **Success:** <verifiable outcome post-ship — doubles as the post-ship verification; honest scale for a solo app>

## Users & use cases

<1–3 job stories. Each the smallest independently-testable slice of value. Product-level ACs — what the parent sees, never the mechanism.>

### US-1 — <title> (P1)
When <situation>, the <named actor> wants to <motivation>, so they can <outcome>.
- AC: <product-level, observable>

<Only scope-changing edge cases get their own AC or an Open question — no exhaustive edge-case list.>

## Design intent (visible surfaces only)

- **Look & feel:** <layout, density, dark-room behaviour, tone — in words. No fonts / hex / file paths.>
- **References:** <existing screens it should feel like; screenshots/inspiration saved under specs/<slug>/references/, or "none">

<Omit this whole section for non-visual work, with a one-line note.>

## Open questions

- <Product decision not yet made — each answerable by the owner>
```

After writing: run `/spec-ticket <concept>` next — this brief becomes the richest input to its
discovery dialogue.
