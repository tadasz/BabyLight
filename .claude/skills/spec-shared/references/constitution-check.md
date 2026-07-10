# Constitution check

Read the project constitution before writing anything, so the output stays consistent with it:

- `specs/mission.md` — product mission, scope of this repo, operating principles
- `specs/tech-stack.md` — targets, frameworks, localization, build/test tooling
- `specs/patterns.md` — product invariants, house style, per-layer conventions
- `CLAUDE.md` (repo root) — the rulebook; it overrides these instructions where it conflicts

Every decision you propose must respect all of them. If the work appears to conflict with any, call
it out explicitly under **Open questions** (when writing a spec) or **Decisions** (with the
rationale) — do not silently deviate.

The constitution files (`mission.md`, `tech-stack.md`, `patterns.md`) are amended by humans, never
from a spec skill. If the work seems to require changing one, stop and tell the user.
