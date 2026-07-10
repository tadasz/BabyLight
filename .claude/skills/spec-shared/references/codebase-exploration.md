# Codebase exploration + touched-feature folders

## Light codebase survey

You are writing a spec, not implementing. Do enough exploration to make the spec concrete. This is
a small codebase (~13 Swift files) — reading whole files is cheap.

1. Identify which surface the work touches: the iOS app (`Baby Light/`), the watch app
   (`Baby Light Watch App/`), the tests (`Baby LightTests/`, `Baby LightUITests/`), or the App Store
   kit (`AppStore/`). Name the real files in the spec.
2. Grep/read for obviously related symbols (view-model methods, presets, UserDefaults keys,
   accessibility identifiers, user-visible text). Reference what you find by file path.
3. Check whether the change hits a **product invariant** (`specs/patterns.md` §1) or the
   iOS↔watch duplication rule (§3) — if so, say so in the spec.
4. If you can't locate a natural home quickly, list it as an open question rather than guessing.
   (For a bug, this is also where you read the neighbouring code to form a root-cause hypothesis
   with file + line references.)

## Propose touched feature folders (confirm before writing the spec)

Feature folders under `specs/features/` describe the long-lived capabilities of the app. Every spec
must declare which ones it touches, so `/spec-implement` can read them and `/spec-verify` can check
they were updated.

1. List every subfolder of `specs/features/` and read each folder's `metadata.yaml` (small — cheap
   to read all of them). Match the work against `name`, `files`, `targets`, `related_features`.
2. Produce a short proposal for the user in chat, in this shape:

   ```
   Touches features:
   - light-screen — confident (changes the elapsed-timer rendering)
   - watch-app — possibly (palette change must be mirrored, patterns.md §3)

   New feature folder needed:
   - (none) | <slug> — because <why this is a new long-lived capability>
   ```

3. **Wait for the user to confirm or correct** — one word is enough ("yes", "drop watch-app",
   "add controls-overlay"). Do not guess.
4. Record the confirmed list under `requirements.md` → **Touches features**. If the work warrants a
   new feature folder, flag it under **Open questions** — the folder itself is created in the PR
   that first populates it, not in this step.

If `specs/features/` is empty (early in the rollout — it starts empty at bootstrap), propose
"none — this does not map onto an existing feature folder" and ask the user whether this spec
should seed the first one.
