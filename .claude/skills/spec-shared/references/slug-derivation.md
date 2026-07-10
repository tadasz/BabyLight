# Slug derivation + two-layout spec-folder resolution

## Derive the slug

Build a slug of the form `YYYY-MM-DD-short-name`:

- `YYYY-MM-DD` is today's date (the day the spec is written). Get it from the environment — never
  guess it.
- Take the working title, lowercase it, strip punctuation, join with hyphens.
- Keep the whole slug ≤ 60 characters. Drop filler words if needed. Describe the work (or, for a
  bug, the defect) — not the fix.
- Examples:
  - "Add a nap-mode preset with dimmer defaults" → `2026-07-10-nap-mode-preset`
  - "Elapsed timer resets when Control Center is opened" → `2026-07-10-elapsed-timer-resets-on-control-center`
  - "Automate screenshot upload for new locales" → `2026-07-10-screenshot-upload-new-locales`

## Resolve the target directory (two layouts)

The final target directory is decided **after** the touched-features confirmation (see
`codebase-exploration.md`). Two layouts exist:

- `specs/features/<feature-slug>/<slug>/` — when the work touches a long-lived user-facing capability
  (the common case). If it touches multiple, place it under the **primary** feature (the first one in
  the confirmed list).
- `specs/<slug>/` — only when the work is purely tooling/infrastructure (CI, `AppStore/` kit, the
  spec skills themselves) and does **not** map onto any user-facing feature folder. Do not create a
  catch-all feature folder for these.

**Overwrite check (before writing files):** search for an existing folder under either layout —
`find specs -type d -name '*<short-name>*'`. If one exists, stop and ask the user whether to
overwrite, update in place, or pick a different slug.

When the layout is ambiguous (multiple features touched, a brand-new feature folder requested),
confirm the target path with the user in one sentence before writing files.
