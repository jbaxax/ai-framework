---
name: grilling
description: "Trigger: grill me, interrogame, stress-test this plan, cuestioname, ayudame a entender antes de implementar, plan de implementacion, no tengo claro que hacer, revisar este diseño, rehacer esto que quedo mal. Interview the requester round by round until nothing is silently assumed, then hand the result to requirements."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "1.0"
---

## Activation Contract

Apply when work is about to start and the shape of it is not settled — a plan, a
redesign, a rework, a feature described in prose. Apply it *before*
`../requirements/`, which needs decisions this session produces.

Do not apply it to a bug. A bug is not an unsettled decision, it is an unknown
fact — `../diagnosis/` finds it.

## The one rule that makes this work

> **Facts are mine to find. Decisions are yours to make.**

Never ask what can be looked up. The file, the current behaviour, the existing
component, what the endpoint returns, who else calls it — all of that is work,
not a question, and asking it hands the requester homework in exchange for
nothing.

Ask only what cannot be discovered: what should happen, who it is for, what
matters more than what, what is acceptable to lose.

A session that opens with *"where is the invoice module?"* has already failed.

## Rounds and the frontier

Map the work as a **design tree**: each decision branches into the decisions
that hang off it.

The **frontier** is every decision whose prerequisites are already settled — the
questions answerable *now*, without guessing at answers not yet heard. Ask the
whole frontier in one round:

```
❓ **Q1 — <title>**: <the question, with the real options>

➡️ <your recommendation, and why>

---

❓ **Q2 — <title>**: <the question>

➡️ <your recommendation, and why>
```

Then **stop and wait.** Each answer reshapes the tree: settled decisions push the
frontier outward and unblock what depended on them. Recompute, ask the next
round.

A question whose answer depends on another still open in this round belongs to a
**later** round. Asking it now produces an answer given under a wrong assumption,
which is worse than not asking.

**Always give your recommendation.** A bare question makes the requester do the
thinking twice — once to understand the question, again to invent the options. A
recommendation is faster to correct than a blank to fill.

### Why this suspends the one-question rule

`CLAUDE.md` says ask at most one question at a time, then stop. That rule exists
to stop option menus leaking into ordinary work.

Inside an invoked grilling session it is suspended, deliberately: the frontier is
asked as a numbered round, because questions that could have been answered
together but were asked one by one cost the requester the same thinking spread
over more interruptions.

**The suspension ends when the session ends.** It never applies to an ordinary
reply, and it is never a licence to open a menu outside this skill.

## Where the tree roots — start from the right question

The exit is always the same: decisions settled, nothing silently assumed. The
**entry** is not, and starting from the wrong root wastes a whole round.

| What you are handed | What is actually unknown | Root the tree at |
|---|---|---|
| Backend documentation | Whether the documentation is **true** | Verify it before planning on it — `../../templates/contract-verification/`. A plan built on a doc that drifted is rework with extra steps |
| **No documentation at all** | The contract itself | Discovery. What does the endpoint really return, for a real record and an empty one? Write the contract yourself from the responses — it becomes the doc you were not given |
| "Change the design" | Whether behaviour changes with it | Which behaviours move. Repainting a button and reordering a flow are not the same job, and only one of them needs criteria |
| An implementation that turned out badly | Whether to repair or replace, and what it would cost | Blast radius first — `graphify affected "<file>"`. The dependents decide it, not taste |
| A feature described in chat | The unstated half | `../requirements/` already lists what chat omits. Bring those to round one instead of rediscovering them |

When the entry is not on this list, name it out loud before round one and say
what you are treating as unknown. A stated wrong root is correctable; an
unstated one is not.

## Before the session can close

The frontier being empty is not sufficient. These four are visited in every
session, whatever the entry, because they are the ones a requester under
deadline pressure will not raise and will still be judged on:

| Axis | The question that must be settled |
|---|---|
| **Effective** | What problem does this solve for whoever asked? If the answer is a feature name rather than an outcome, keep asking |
| **Secure** | What must this never expose or allow? Who is allowed to do it? |
| **Scalable** | What breaks at 10× the data or the users? If the answer is "nothing", say what number was assumed |
| **Usable** | What does the user see while it loads, when it is empty, and when it fails? Name the alert or message, not "handle the error" |

The last one is not polish. A flow with no failure state ships as a spinner that
never stops, and the requester finds out from a customer.

If an axis genuinely does not apply, say so and why — in one line. Silence is
not an answer to it.

## Execution Steps

1. **Name the entry** from the table above, and say what you are treating as
   unknown.
2. **Find the facts first.** Read the code, run the contract, build the graph.
   Do not spend a round on anything discoverable.
3. **Ask round one** — the whole frontier, numbered, each with a recommendation.
   Then stop.
4. **Recompute and repeat** until the frontier is empty and the four axes are
   visited.
5. **Summarise the settled decisions** in a list the requester can correct in one
   pass — every one of them, including the ones they answered with "as you
   prefer", which are now yours and must be stated as assumptions.
6. **Confirm before acting.** A grilling session ends in shared understanding,
   not in code.
7. **Hand it to `../requirements/`** to become acceptance criteria, and to
   `../backlog/` to be filed as Ready or Blocked.

## Output Contract

When the session closes, report:

1. The entry case, and the root the tree was built from
2. Every settled decision, in one correctable list
3. The four axes, each with its answer or its stated reason for not applying
4. What is still blocked on someone else, and the exact question — this goes
   straight to `../backlog/` as a Blocked item with today's date
5. The assumptions now carried, each with its blast radius

## References

- `../requirements/SKILL.md` — turns the settled decisions into EARS criteria
- `../backlog/SKILL.md` — the Definition of Ready this session is feeding
- `../epic/SKILL.md` — a decision that spans several changes belongs there, not here
- `../diagnosis/SKILL.md` — when the unknown is a fact, not a decision
- `../../templates/contract-verification/` — how a backend doc is verified before it is planned on

The design tree, the frontier, and the numbered round with a recommendation are
adapted from the `grilling` skill in
[mattpocock/skills](https://github.com/mattpocock/skills) (MIT). The entry-case
router and the four closing axes are this framework's own.
