---
name: backlog
description: "Trigger: backlog, what should I work on, qué sigo, next task, pending work, blocked, waiting on the client, definition of ready, is this ready to start, priorizar, pendientes. Decide what can be started now and what is still waiting on someone."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "1.0"
---

## Activation Contract

Apply when choosing what to work on next, when adding pending work, when a
request arrives that cannot start yet, or when deciding whether an item has
enough information to begin.

## The problem this solves

Not "I forget what is pending" — that is a list, and any list solves it.

The real cost is **starting something that stops halfway**. Work begins, a
decision surfaces that only the requester can make, the question goes out over
chat, and the work sits half-finished for two days. The context is lost, the
branch goes stale, and restarting costs more than the remaining work.

That is not a discipline problem. It is a **missing gate**: nothing checked
whether the item could be finished before it was started.

## Ordered by readiness, not priority

Priority answers *what matters most*. Readiness answers *what can I actually
start right now*. When a third of the list is waiting on someone else, the second
question is the one worth asking every morning — and the first one you usually
already know.

Three buckets. An item lives in exactly one.

```markdown
# Backlog

## Ready
- [erp] Filter invoices by date range — criteria 1-4, no blocking gaps
- [acme] Export the report to Excel — criteria 1-3, columns confirmed 2026-08-28

## Blocked
- [acme] Bulk price update — waiting: does it apply to existing orders? (asked 2026-08-24)
- [erp] Void an issued invoice — waiting: who is allowed to? (asked 2026-08-29)

## Not ready
- [personal] NestJS profile — no criteria yet
- [erp] Rework the client search — reported over chat, not restated yet
```

| Bucket | Meaning | What moves it out |
|---|---|---|
| Ready | Passes the Definition of Ready. Can be finished without asking anyone | You start it |
| Blocked | Cannot finish without an answer that is not yours to give | The answer arrives |
| Not ready | No criteria yet, or gaps not identified | Run `../grilling/` if the decisions are unsettled, then `../requirements/` |

**Blocked is not low priority.** It may be the most important item on the list.
It is simply not startable, and mixing the two axes is what produces a sorted
list you cannot act on.

## Definition of Ready

An item is Ready when all of these hold:

- [ ] It has a user story — who wants it and what outcome they expect
- [ ] It has acceptance criteria in EARS shape (`../requirements/`)
- [ ] Every **blocking** gap is answered
- [ ] Non-blocking gaps are recorded as stated assumptions, with their blast radius
- [ ] It belongs to an epic, or is small enough not to need one (`../epic/`)
- [ ] Nothing in it falls inside that epic's *Not in*

### Which gaps block, and which do not

This is the whole judgment, and `../requirements/` already produces the input:
it lists gaps **ordered by how much rework a wrong guess would cost**. The
Definition of Ready draws the line on that list.

| A gap blocks when | A gap does not block when |
|---|---|
| A wrong guess means rewriting work, not adjusting it | A wrong guess means changing a value, a label, or a copy string |
| It decides a data shape, a permission rule, or a contract | It decides a default that is cheap to flip |
| It changes which layer the logic lives in | It changes only presentation |
| Only the requester can answer it | You can answer it and confirm later |

A non-blocking gap does **not** hold the item. Record the assumption, state its
blast radius, and start — that is exactly what `CLAUDE.md` §1.1 asks for when
asking is impossible.

**Never move an item to Ready by guessing at a blocking gap.** That is the whole
failure this gate exists to prevent, wearing the disguise of momentum.

## Order within Ready

Apply in order, stop at the first that decides it:

1. **Someone else is blocked on it.** Their idle time costs more than your
   context switch.
2. **It has a committed date.** A date you gave is a promise, not a preference.
3. **It is cheap and unblocks others.** Small items that release later work go
   before large items that release nothing.
4. **Everything else.**

Story points do not appear here. Sizing is produced where it is useful —
`../requirements/` flags a request past ten criteria, `sdd-tasks` forecasts
changed lines — and for one developer the number that matters is how much can be
reviewed in one sitting.

## Chasing what is blocked

A blocked item carries the date the question went out. That date is the point of
the bucket: an unanswered question is not a pause, it is work you are silently
carrying.

Run `fw backlog` to see what is ready and how long each blocked item has waited.
Anything past a few days needs a follow-up, and the follow-up is one question —
the one whose wrong answer costs the most, per `../requirements/`.

In consulting this is not administrative overhead. An item blocked for two weeks
with no visible trail becomes *"¿y por qué no has avanzado?"*, and the dated line
is the answer.

## Execution Steps

1. **A request arrives** → run `../requirements/` on it first. Until it has a
   story and criteria, it goes to *Not ready*.
2. **Sort its gaps** into blocking and non-blocking using the table above.
3. **File it**: blocking gaps outstanding → *Blocked*, with the question and the
   date it was asked. Otherwise → *Ready*, with the assumptions recorded.
4. **Choosing work** → take from *Ready* using the order above. Never start from
   *Blocked* hoping the answer arrives in time.
5. **An answer arrives** → move the item to *Ready*, and add the answer to the
   criteria rather than to your memory.
6. **An item finishes** → remove it. A backlog that only grows stops being read,
   and a list nobody reads is worse than no list, because it looks like control.

## Output Contract

When asked what to work on, report:

1. The chosen item and which ordering rule selected it
2. Why it is Ready — the assumptions carried, if any
3. Blocked items waiting longest, with their age and the pending question
4. Anything in *Not ready* that would become Ready with one round of criteria

## References

- `../requirements/SKILL.md` — produces the story, the criteria, and the gaps
- `../epic/SKILL.md` — the boundary an item must sit inside
- `../../CLAUDE.md` §1.1 — an assumption is stated with its blast radius, never buried
- `../../bin/fw` — `fw backlog` reads the file and reports readiness and waiting time
