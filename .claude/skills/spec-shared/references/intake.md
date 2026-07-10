# Work intake (description-based — this repo has no ticket tracker)

This repo has no Jira. The "ticket" is whatever the user describes — in `$ARGUMENTS`, in the
conversation so far, or in a file/notes they point at.

1. `$ARGUMENTS` should be a short description of the feature (for `/spec-ticket`) or the defect (for
   `/spec-bug`). If it's empty and the conversation doesn't already describe the work, ask for a
   one-paragraph description before continuing.
2. From the description + chat, extract (and echo back so the user can correct):
   - **Summary / working title** — one line.
   - **Motivation** — why this, in the user's words.
   - **Acceptance criteria** — if the user stated observable outcomes, capture them verbatim as
     AC candidates. If not, draft 2–5 candidate ACs from the description and **have the user confirm
     or correct them** — the discovery dialogue (spec-ticket Step 3c) is where they get sharpened.
   - **Constraints** — anything the user ruled in/out explicitly.
3. **For bugs, additionally** establish: **reproduction steps** (exact taps/gestures + app state);
   **expected vs actual**; **environment** (device or simulator, iOS/watchOS version, app version,
   TestFlight/App Store/debug build, locale if relevant); **frequency**; **evidence** the user can
   supply (screenshots, screen recordings, crash logs). If reproduction is unclear, flag it under
   **Open questions** — do not invent steps.
4. **Evidence handling:** reference user-supplied screenshots/videos/logs by a one-line factual
   description each in the spec's **Evidence** (bug) or **Design** (feature) section. If the user
   provides reference files worth keeping, save them under `specs/<spec-folder>/references/` — never
   paste binary content or commit large media.
5. If acceptance criteria or reproduction remain ambiguous after one round of questions, record the
   gap under **Open questions** rather than guessing.

**Type redirect:** confirm the work type matches the skill before proceeding.
- Something is broken relative to intended behaviour → use `/spec-bug`, not `/spec-ticket`.
- New/changed behaviour → use `/spec-ticket`, not `/spec-bug`.
If they mismatch, stop and suggest the right one.
