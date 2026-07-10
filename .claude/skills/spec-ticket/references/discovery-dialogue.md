# Discovery dialogue — surface the why, then the use cases (tiered)

Develop a shared understanding of *why* this work exists and *which use cases* deliver that why,
**before** writing the acceptance criteria. A thin "why" produces ACs that verify implementation
instead of user value — the most common failure mode of a rushed spec.

## Tier selection (do this first)

Pick the depth from the touched-features list (confirmed in the codebase-exploration step):

- **Fuller discovery** — run the full Step A + Step B below when the work touches a **user-facing
  surface**. In this app that is almost everything: the light screen, controls overlay, timers,
  tutorial, rating prompt, or the watch app. This is where "why" is easy to get wrong and expensive
  to fix — the app's value is its simplicity, so every addition must justify itself.
- **Lightweight** — for tooling/infra (CI, `AppStore/` kit, spec skills) or a thin, self-explanatory
  request: write the one-line **why** and a single sentence on **who benefits and how you'd verify
  it**, then move on. Don't interrogate a crisp request; the strawman *is* the work when it's clear.

When unsure, default to lightweight and escalate only if Step A's draft exposes real ambiguity.

## Pattern (both tiers): draft → confirm → explore-if-ambiguous → write

You're a curious collaborator with a draft, not a stenographer with a question list. The strawman is
for efficiency when the request is clear — never a way to skip discovery when it's thin.

## Step A — Surface the why → `requirements.md` → **Why this, why now**

### A.i Draft (no questions yet)

Write a strawman of these layers from the description + chat + any evidence. Each layer ≤3
sentences. Where signal is thin, write `[NEEDS CONFIRMATION: <best guess> — <what's missing>]`
inline — never empty.

1. **Underlying problem** — the friction a parent hits today, not the solution; concrete enough to
   picture the moment of pain (usually: 3 AM, dark nursery, one hand free).
2. **Evidence** — how we know it matters *now*, source-named ("App Store review from <date>",
   "own experience", "support email", "product intuition — no data").
3. **Success outcome** — a verifiable signal post-ship. An outcome, not an output: "X is built" is
   wrong; "rating prompt conversion holds", "no review mentions X anymore", "the owner uses it
   nightly for a week" are right — keep it honest for a solo app; small signals are fine.
4. **Alternatives considered** — including doing nothing (with the cost of inaction explicit) or
   doing less. Propose 1–2 yourself if none were named, tagged `[NEEDS CONFIRMATION]`.
5. **Assumptions** — 1–3 falsifiable claims.

### A.ii Confirm (one batched pass — invite correction, not validation)

Show the strawman with exactly one prose question:

> "Here's what I've drawn from the description — what's wrong, what's missing, and where should this
> be sharper?"

Never ask "is this right?" — that gets nodded through. Over-acceptance is the strawman's only
failure mode; the "what's wrong?" framing is the guard.

### A.iii Explore (only if ambiguity remains — then go deep)

Signals the why is still fuzzy: a vague statement swapped for another; unresolved `[NEEDS
CONFIRMATION]`; a success outcome that's still an output; an underlying problem that restates the
solution. Explore *together*: focused follow-ups on the unclear layer only; alternative framings
("could the real problem be X?"); an offer to narrow ("would the P1 slice alone solve the pain?").
Cap at ~3 follow-ups. If a layer is still fuzzy after exploring, log it as a sharp **Open
question**, flag the spec **provisional pending why-conversation**, and stop — don't press into
Step B with a fuzzy why.

### A.iv Write

Rewrite the layers as final prose under **Why this, why now**. No `[NEEDS CONFIRMATION]` markers
remain — unresolved ones move to **Open questions**.

## Step B — Use cases (fuller tier only) → `requirements.md` → **Users and use cases**

Bridges the why to the what: concrete user scenarios that together deliver the success outcome.
Without it, ACs verify mechanism rather than value. Same draft → confirm → explore → write pattern.

Draft 1–3 user stories — each the smallest *independently testable* slice of value. Default to the
**job story**:

```
### US-1 — <Short title> (P1)
When <situation>, the <actor> wants to <motivation>, so they can <outcome>.
Independent slice: <smallest version that still delivers value>
Acceptance scenarios:
  1. Given <state>, when <action>, then <expected>.
```

Drafting rules: **name the actor** ("parent mid-night-feed with one hand", not "the user"); **P1 =
the slice without which the feature fails** (if everything is P1, split or push P2s out of scope);
**one story per testable slice**. Confirm with: *"Any miscast, missing, or wrongly prioritised?"*
Explore as in A.iii (cap ~3). Each story keeps its `US-N` id so every AC cites the story it
verifies — the why → who → AC chain stays auditable.

When `/spec-client` ran upstream, `specs/<slug>/product_brief.md` is the richest input — read it
before drafting so A/B refine it rather than starting cold.
