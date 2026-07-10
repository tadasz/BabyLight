# Git-Diff anti-drive-by gate

Enforces CLAUDE.md §3 ("No drive-by refactors or cleanups"): every code file in the branch diff must
be accounted for by the spec's declared **edit surface**, so a change can't quietly touch files the
spec never scoped.

## The declared edit surface

The contract lives in `requirements.md`:

- Feature specs: **Affected areas of the codebase** (the iOS/watch/tests/localization bullets).
- Bug specs: **Blast radius** (files + flows that share the suspected code path).

Each names real paths (a file, or a directory from which the changed files are derivable). A vague
edit surface makes this gate unenforceable — in that case, report the edit surface itself as too
vague to gate against, and treat it as spec-hygiene breakage.

## The check

1. From the diff (`git diff --name-only <base>..HEAD`), take the **code** files only — exclude
   `specs/**`, `*.md` docs, `.claude/**`, test files (`Baby LightTests/**`, `Baby LightUITests/**`),
   and the localization catalogs (`**/Localizable.xcstrings` — they change as a side effect of new
   strings).
2. For each remaining code file, confirm it appears in — or is derivable from a directory listed
   in — the declared edit surface.
3. **Verdict impact:** any code file in the diff that is **not** covered fails the gate. Report each
   as `<path>:<+lines/-lines>` so the user can either amend `requirements.md` → edit surface (if the
   file legitimately belongs to the work) or pull the change out of the diff (if it's a drive-by).
4. A listed path with **no** matching diff is a warning, not a failure — note it in the report
   (the spec over-scoped, or the work isn't done).

## Rollout

Hard gate from the start for files clearly outside the declared surface. When the edit surface is
present but ambiguous, downgrade to a warning and say why — don't block on an un-gateable contract.
