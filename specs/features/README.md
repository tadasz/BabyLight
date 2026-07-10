# specs/features/

This folder is the **feature layer** of the spec-driven workflow. Each subfolder describes one **long-lived capability** of Baby Night Light — e.g. the light screen, the controls overlay, the auto-off timer, the first-run tutorial, the watch app, the App Store kit. Each feature folder also **hosts the spec folders** that have shaped that capability.

Feature folders and spec folders work together:

- **Spec folders** (`specs/features/<feature>/<YYYY-MM-DD>-<slug>/` for the common case, or `specs/<YYYY-MM-DD>-<slug>/` for tooling/infrastructure work) answer *what changed in this PR and how we verified it*. Written once, never revisited.
- **Feature folders** (`specs/features/<feature>/`) answer *what does this part of the app do today*. Updated every time a spec changes the feature, so a new contributor (or an agent) can read one file and understand the current state.

**If they ever disagree, the feature folder is authoritative for "how it works now"; the spec folder is authoritative for "how that one PR was scoped."** Conflicts mean the feature folder wasn't updated — fix it, don't work around it.

---

## When to create a feature folder

Create a `specs/features/<slug>/` folder the first time a capability is significant enough that two specs in a row would benefit from reading the same context. Signals:

- The capability has its own screen, surface, or persistent flow (the controls overlay, the watch app).
- It owns state that outlives a single interaction (persisted settings, the rating-prompt gating).
- A spec author found themselves explaining the same background twice.

Do **not** create one for:

- Cross-cutting concerns already covered by the constitution (style, localization rules, the zero-dependency rule — those live in `specs/patterns.md` / `specs/tech-stack.md`).
- One-off UI tweaks that won't be revisited.
- Purely internal refactors with no user-visible surface.

When in doubt, skip it. Feature folders accumulate organically as specs land — **we do not backfill** (except deliberately, via `/spec-reverse-engineer`). This folder starts empty at bootstrap; that is correct.

---

## Folder shape

```
specs/features/<slug>/
  README.md                       // how this capability works today
  metadata.yaml                   // structured facts the spec skills read
  changelog.md                    // one line per spec that changed this feature
  <YYYY-MM-DD>-<short-slug>/      // spec folders (zero or more)
    requirements.md
    plan.md
    validation.md
```

### `README.md` — the current state

Plain English for a new contributor, one to three pages max. Cover:

1. **What it is** — 1–2 sentences from the user's perspective.
2. **Where it lives** — files under `Baby Light/` / `Baby Light Watch App/`, with links.
3. **Key entry points** — the views, view-model methods, or scripts a new spec is likely to touch.
4. **Dependencies** — other features this one relies on (and anything relying on it).
5. **Known constraints / invariants** — what future specs must not break (cross-reference `specs/patterns.md` §1 where relevant).
6. **Open debts** — known rough edges not yet worth their own spec.

The README describes **present reality**, not history. If behaviour changes, edit the README in the same PR that changes the code.

### `metadata.yaml` — structured facts

```yaml
name: Controls overlay
status: active          # active | deprecated | experimental
owner: tadas
files:                  # source files this feature owns
  - Baby Light/ControlsOverlay.swift
targets: [Baby Night Light]     # and/or "Baby Light Watch App"
related_features:
  - light-screen
specs:                  # spec folders that shipped meaningful changes
  - 2026-07-15-example-slug
```

Paths must be real — `/spec-audit` checks them.

### `changelog.md` — what changed, when

Append-only, oldest at the top, one line per merged PR that touched this feature:

```
- 2026-07-15 2026-07-15-example-slug — added X, changed Y
```

Never rewrite history — if a change was reverted, add a new line.

---

## How the spec skills interact with this folder

- **`/spec-ticket` / `/spec-bug`** scan `specs/features/` and propose which folders the work touches. You confirm before the spec is written; the confirmed list lands under `requirements.md` → **Touches features**, and the spec folder is created inside the primary feature folder (or at `specs/` top level for tooling work).
- **`/spec-implement`** reads the `README.md` of every touched feature before executing the plan, so implementation respects invariants the spec author may not have repeated. It updates the README + changelog in the same change that alters behaviour.
- **`/spec-verify`** checks every touched feature's `README.md` reflects what the PR did and its `changelog.md` gained an entry. Warnings during rollout; hard blocks once a few features exist.
- **`/spec-audit`** compares each feature folder against the code and writes `specs/drift-report.md`.
- **`/spec-reverse-engineer`** backfills a folder for an existing undocumented capability, from the code, file-cited.
