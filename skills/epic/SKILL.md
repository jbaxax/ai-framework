---
name: epic
description: "Trigger: epic, épica, roadmap, module, 'este proyecto', 'todo el módulo', work spanning more than one change, scope creep, 'eso no estaba incluido', deciding whether a request is one slice or several. Hold the boundary and the standing decisions that individual changes must respect."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "1.0"
---

## Activation Contract

Apply when work spans **more than one change**: a module being built or reworked,
a body of maintenance with a shared goal, anything a requester talks about as one
thing but that ships in slices.

An epic is the only artifact that lives **between** changes. Everything else in
this framework is per-change: criteria describe one request, a proposal scopes
one change, tasks slice one implementation. That leaves a gap — each change can
be locally correct while the set of them drifts apart. The epic closes it.

## When NOT to write one

An epic that is never read is pure cost. Skip it for:

| Situation | Why |
|---|---|
| A single bug fix | The criterion is the whole scope |
| A change that ships in one slice | The proposal already holds its boundary |
| Work you will finish today | Nothing will have drifted by then |
| A module you are only reading | No decisions are being made |

The threshold is honest: **would a second slice, written a week from now, need to
know something decided in the first one?** If no, there is no epic.

## What it holds

Under a page. Four sections, and only one of them is expensive.

```markdown
# Epic: {name}

## Outcome
One sentence: what is true for the requester when this is done.

## Boundary

### In
- {capability}

### Not in
- {capability} — {why it is excluded, or who deferred it}

### Not decided yet
- {question} — blocks {which slice}

## Standing decisions
| Decision | Because | Binds |
|---|---|---|
| {what was settled} | {the reason, briefly} | {which slices must respect it} |

## Slices
| # | Slice | Status | Depends on |
|---|---|---|---|
| 1 | {name} | done / in progress / not started | — |
```

### Standing decisions carry the weight

This is the section that prevents drift, and the one no per-change artifact can
hold. A decision made in slice 1 — *invoices paginate with `page`/`limit`, not a
cursor* — binds slices 2 through 6, which will be written after that reasoning
has left your head.

Record a decision here only when it **constrains a future slice**. A choice that
affects one file is a design note, not a standing decision.

### "Not in" is the half that pays for itself

In consulting work the expensive failure is not a wrong feature. It is a
capability that was never agreed, never quoted, and arrives as *"pero eso ya
estaba incluido, ¿no?"*.

Write the exclusions in the requester's own words and send them the list. An
exclusion nobody saw is not an exclusion — it is a surprise waiting to happen.
When a request arrives that sits in **Not in**, that is not scope creep to
absorb; it is a new epic or a new quote, and the list is what lets you say so
without it becoming an argument about memory.

## Where it lives

`.fw/product/epics/<slug>.md`, next to the stories it holds. `.fw/` is covered by
the global gitignore, so an epic never lands in a client's repository history.

```bash
fw product init                 # once per project
fw product epic checkout        # creates the file with this shape
fw product hu checkout "Split payment between two cards"
```

Stories are **flat**, in `.fw/product/criteria/`, not nested inside a per-epic
directory. The `## Slices` table above is the single source of truth for what
belongs to this epic. Nesting would record that relationship a second time in the
directory tree, and the two copies drift the first time a slice is renamed — the
table gets edited, the folder keeps the old name and quietly goes stale.

`fw product hu` appends the slice row for you. Do not maintain the list by hand.

## Execution Steps

1. **Check whether one exists** before proposing a change. If it does, read it
   first — that is the entire point of having it.
2. **Write the outcome and the boundary** from what the requester actually said.
   Use their vocabulary, the same rule as `../requirements/`. Do not invent
   exclusions; an unstated exclusion goes in *Not decided yet* as a question.
3. **List the slices** you can see, with dependencies. Not tasks — slices. A
   slice is something that could ship on its own.
4. **Leave it alone during implementation.** The epic is not a plan to execute;
   it is a boundary to check against.
5. **Update it after each slice is verified**, not before. Add what got decided,
   move the slice to done, and delete questions that got answered. An epic
   updated at the end of a slice stays true; one written entirely upfront is
   fiction with a table of contents.

## Decision Gates

| Moment | What the epic answers |
|---|---|
| A new request arrives | Does this belong to an existing epic, or is it a new one? |
| Before writing a proposal | Which standing decisions constrain this slice? |
| A request lands in *Not in* | Say so, and treat it as new scope — not as a change |
| Criteria pass ~10 items | This is more than one slice; the epic is where the split is recorded |
| After a slice verifies | What was decided that a later slice must respect? |

## Relationship to the other artifacts

```
Requester's message
   └── user story          ../requirements/  — who wants it, and why
        └── EPIC           this file         — boundary, standing decisions, slices
             └── proposal  sdd-propose       — one slice
                  └── spec, design, tasks    — how that slice is built
```

The epic sits **above** the proposal and **below** the story. It does not replace
either. The story says why someone wants this; the epic says how much of it we
agreed to and what has already been settled; the proposal takes one slice.

Sizing is not a separate artifact. It is already produced where it is useful:
`../requirements/` flags a request that exceeds ~10 criteria, and `sdd-tasks`
forecasts changed lines and suggests work units. Story points are omitted on
purpose — they measure team velocity, and a solo developer has none to measure.
The number that matters is how much can be reviewed in one sitting.

## Output Contract

Report, in this order:

1. Epic name and outcome
2. Which slice the current work belongs to
3. Standing decisions that constrain it — or `None yet`
4. Anything in the request that falls in *Not in*, stated plainly
5. New standing decisions to record, once the slice verifies

## References

- `example.md` — a real epic, filled in, as the reference for the shape
- `../../docs/product-artifacts.md` — `fw product`, and why the layout is flat
- `../requirements/SKILL.md` — the user story and the criteria that feed an epic
- `../../docs/workflow.md` — where this sits in the lifecycle
- `../../CLAUDE.md` §1.1 — an unstated boundary is a gap, never a default
