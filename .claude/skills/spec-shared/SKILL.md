---
name: spec-shared
description: Shared reference snippets for the spec-* skills (spec-ticket, spec-bug, spec-implement, spec-verify). Not directly invocable — it only holds the common building blocks (constitution check, work intake, slug derivation + two-layout resolution, codebase exploration, test gates, standard merge gate) that those skills read on demand.
user-invocable: false
disable-model-invocation: true
---

# spec-shared

This skill is a **passive container**. It is never invoked on its own — `user-invocable: false`
hides it from the `/` menu and `disable-model-invocation: true` stops it loading automatically.

The reusable building blocks the spec-* skills share live under [`references/`](references/). Each
spec skill reads the ones it needs at the step where they apply, e.g. *"Read and follow
`../spec-shared/references/constitution-check.md`."*

| File | Used by | What it covers |
|---|---|---|
| `references/constitution-check.md` | all | Read mission / tech-stack / patterns / CLAUDE.md before writing |
| `references/intake.md` | spec-ticket, spec-bug | Parse the described work from `$ARGUMENTS` + chat, interview for gaps, handle user-supplied evidence, feature↔defect redirect |
| `references/slug-derivation.md` | spec-ticket, spec-bug, spec-implement, spec-verify | Derive the dated slug and resolve the two-layout spec folder (`specs/features/<f>/<slug>/` vs `specs/<slug>/`) |
| `references/codebase-exploration.md` | spec-ticket, spec-bug | Light codebase survey + the touched-feature-folders confirmation |
| `references/test-layers.md` | spec-implement, spec-verify | The common test / quality gates (xcodebuild test, watch build check) |
| `references/standard-merge-gate.md` | all validation.md files | The invariant merge-gate checklist every spec inherits |

When a calling skill needs a variant of one of these, it reads the shared file and then states its
own delta inline — the shared file holds the common core, the skill keeps what's unique to it.
