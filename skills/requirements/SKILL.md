---
name: requirements
description: "Trigger: user story, requirement, acceptance criteria, feature request, bug report, WhatsApp message, verbal spec, 'el cliente pidió', 'me dijeron que'. Turn informal requests into testable criteria before writing code."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "1.0"
---

## Activation Contract

Apply **before implementing** whenever the request arrives as prose: a user
story, a chat message, a transcribed conversation, a screenshot of a bug, or a
backend `.md`. Skip only when the user hands over criteria already in the shape
below.

This skill produces no code. Its output is a short criteria block the user can
approve — or forward to whoever gave the requirement.

## Why this exists

Most requirements arrive verbally or over chat, never as a document. Prose hides
the gaps: "el usuario debe poder filtrar" says nothing about what happens with
zero results, who may filter, or whether the filter survives a reload.

Implementing prose means inventing those answers silently. Restating it in a
fixed shape makes every missing answer **visible as an empty slot** — and an
empty slot is a question worth asking, not an assumption worth making.

## Hard Rules

- **Never invent an acceptance criterion.** A missing answer is listed as a gap,
  never filled with a plausible default.
- Restate the request before implementing it. If the restatement is wrong, that
  is cheap to fix; wrong code is not.
- Criteria describe **observable behavior**, never implementation. "The system
  shall store the token in Redis" is a design decision wearing a requirement's
  clothes.
- One criterion, one behavior. Two `shall`s joined by "and" are two criteria.
- Keep the requester's vocabulary. If they say "comprobante", the criteria say
  comprobante — the translation to English happens in the code, not here.
- **Criteria are the source for tests; they are not tests.** Approved criteria
  count as a test request — see the Mode Resolution gate in `../testing/SKILL.md`
  for when that turns into tests written first. Writing criteria is not writing
  tests: finish the criteria, get them approved, then let the gate decide.

## The shape

Every criterion fits one canonical sentence (EARS — Easy Approach to
Requirements Syntax, Mavin et al.):

```
WHILE <optional state>, WHEN <optional trigger>, the <system> SHALL <response>
```

Four patterns cover almost everything:

| Pattern | Shape | Example |
|---|---|---|
| Ubiquitous | The system shall … | The invoice list shall show 20 rows per page |
| Event-driven | **When** ‹trigger›, the system shall … | When the user submits valid credentials, the system shall create a session |
| State-driven | **While** ‹state›, the system shall … | While the account is locked, the system shall reject every login attempt |
| Unwanted behavior | **If** ‹condition›, **then** the system shall … | If the password is wrong 5 times, then the system shall lock the account for 15 minutes |

The value is not the grammar. It is that each slot is either filled or visibly
empty. "It should validate the email" has no trigger and no response — that is
the gap, and the shape exposes it.

## Execution Steps — new feature

1. **Restate** the request as a user story: *As a ‹role›, I want ‹capability›, so
   that ‹outcome›.* If the role or the outcome is unknown, say so — do not guess.
   The outcome is what lets you reject a bad solution later.
2. **Write the criteria** using the four patterns above. Aim for the happy path,
   the empty state, the failure, and the permission rule.
3. **List the gaps** as direct questions, ordered by how much rework a wrong
   guess would cost. Send this list back over chat — a question needs an answer
   from a person, and a file cannot ask one. The *criteria* still get written to
   disk; see **Where this lives** below.
4. **Mark assumptions** you must make to proceed at all, each with its blast
   radius: *"Assuming the filter resets on reload — if it must persist, the state
   moves to the URL and the list component changes."*
5. **Wait for approval** on the criteria before writing code, unless the user
   said to proceed.
6. After implementing, **map each criterion to where it lives** — file and
   function. A criterion with no home was not implemented.

## Execution Steps — bug report

A bug report over chat is almost never a bug report. It is a symptom plus a
guess at the cause. Separate them.

1. **Report** — restate three things, and only three:
   - **Observed**: what actually happened, quoted from the reporter
   - **Expected**: what should have happened *and where that expectation comes
     from* — a criterion, a spec, or the reporter's assumption
   - **Reproduce**: the exact steps, data, and role
2. If **Expected** cannot be filled from an existing criterion, that is the real
   finding: the behavior was never specified. Ask before "fixing" it — you would
   be writing a new requirement, not repairing a defect.
3. **Analyze** — find the root cause and name it. State which layer it lives in.
   A fix in the wrong layer moves the symptom instead of removing it.
4. **Fix** — smallest change that removes the cause. Do not refactor around it;
   propose that separately.
5. **Verify** — reproduce the original steps and show the actual output. "Should
   work now" is not verification.
6. **Write the missing criterion.** A bug that reached production usually means a
   behavior nobody stated. Add it so the next change does not undo the fix.

## When the requirement comes from a person, not a document

Voice and chat lose information that a document would have carried. Recover it
explicitly instead of assuming it survived:

| What chat usually omits | Ask |
|---|---|
| The role | Who does this — every user, or one permission level? |
| The empty state | What shows when there is no data? |
| The failure state | What does the user see when the server rejects it? |
| The scope of "all" | Does this change existing records, or only new ones? |
| The urgency of "rápido" | Is this a deadline, or a performance requirement? |

Ask **one at a time** and pick the one whose wrong answer costs the most rework.
A message with five questions gets one answer.

## Where this lives

A user story delivered only as a chat message is not delivered. It cannot be
reread next week, diffed, linked from a criterion, or handed to the verifier that
has to prove it. Chat is a transport, not a place.

Write it to disk under `.fw/product/`, which is covered by the global gitignore —
nothing here reaches the project's history:

```bash
fw product init                 # once per project
fw product epic checkout        # the boundary across slices
fw product hu checkout "Split payment between two cards"
```

That creates `.fw/product/criteria/checkout-01.md` with this file's Output
Contract already laid out, and appends the slice row to the epic's table. Fill
the file; do not paste the story into chat and move on.

| Situation | Where it goes |
|---|---|
| Acceptance criteria, story, assumptions, evidence map | `.fw/product/criteria/<epic>-NN.md` |
| Gaps, as questions for a person | Chat — they need an answer, not a file |
| A decision that binds future slices | The epic's Standing decisions table |

**This applies to maintenance as much as to new work.** On a new project the
context is still in your head; on a codebase you inherited, that context is
precisely what is missing, which is what makes writing it down worth more there,
not less.

## Output Contract

Report, in this order:

1. The user story (or `Observed / Expected / Reproduce` for a bug)
2. Numbered acceptance criteria in EARS shape
3. Gaps, as questions — or `None` if the request was complete
4. Assumptions made to proceed, each with its blast radius
5. After implementation: criterion → file mapping

Keep it under a page. If the criteria list passes ~10 items, the request is more
than one feature — say so and propose the split. That split is recorded in
`../epic/`, which holds the boundary across slices and the decisions each slice
must respect. Do not carry it in your head between changes; that is exactly the
information that does not survive a week.

## References

- `../../CLAUDE.md` §1.1 — ask before assuming
- `../epic/SKILL.md` — the boundary and standing decisions across several slices
- `../../docs/product-artifacts.md` — `fw product`, and why the layout is flat
- `../testing/SKILL.md` — an acceptance criterion **is** a test request; Mode Resolution decides what proves it
- `../grilling/SKILL.md` — settles the decisions this file turns into criteria; run it first when the request is not yet shaped
- `../api-client/SKILL.md` — verifying a backend `.md` against the real response
- EARS: Mavin et al., <https://alistairmavin.com/ears/>
