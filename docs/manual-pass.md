# The manual pass over the running app

## Why this has its own document

Across three logged sessions, the three most expensive findings of a day all
came from **looking at the screen**, not from reading code:

- A toggle in *Documentos de Emisión* with no gate, which then exposed five more
  modals excluded because a list was incomplete.
- A `403` on `/api/bank`, which revealed a whole class of bug — read catalogues
  used as filters, demanding write permission — and ended in a report to the
  backend team.
- A sheet that did not close on an outside click, which exposed two different
  implementations of the same thing.

None of the three was detectable with the tools that existed. Two of them
produced new tools; the third unified a component.

> **The script finds what it knows to look for. The person finds what the script
> does not know exists.**

The framework had rules for the code, the tests, the evidence and the review,
and named this nowhere — the single activity with the highest yield.

## The two halves, and only one is yours

The pass serves two purposes at once, and mixing them is what makes it
unrepeatable:

| Purpose | Needs | Produces |
|---|---|---|
| Checking your own work | a list derived from **what changed** | findings |
| Improving the tooling | a record of **what no tool caught** | the retro |

`fw pass` builds the first half from the diff. You never write that part.

```
Manual pass in ~/proyectos/facnet
  ✓ comparing against origin/main
  ✓ 14 file(s) changed

Where to look
    6 file(s)  src/app/features/cobros
    2 file(s)  src/app/features/settings

Only a person can check these
  ! src/app/features/cobros/presentation/collection-list.html

Changed with no colocated test
  ! src/app/features/cobros/application/useCollections.ts

Entry points touched
  ✗ src/app/app.routes.ts
    who reaches what may have moved — skills/gating resolves it before you judge a control
```

Each section is a different reason to look, not a longer list:

- **Only a person can check these** — a template. No unit test sees a layout, an
  empty state, or a control that renders and does nothing.
- **Changed with no colocated test** — the file where a person is the only check
  left.
- **Entry points touched** — a route, menu or guard moved, so who can reach what
  moved with it. That is the claim a single file can never answer;
  `../skills/gating/SKILL.md` resolves it.

## A finding has two halves too

```bash
fw pass note "el toggle de Emisión no está gateado" \
             --missed "audit.py: ciego a p-toggleswitch"
```

The first field is the bug. **The second is the one that compounds**: which
instrument should have caught this and did not. That field is what a retro is
made of, and it is the difference between "we fixed 30 things" and "we know why
we had to find them by hand".

When nothing should have caught it, leave `--missed` out. The entry then reads
`nothing exists — framework gap`, which is not a missing field — it is the
finding. Nothing was watching that class of thing at all.

## Why it is written while looking, not afterwards

The retros that produced this framework were written from memory at the end of
ten-hour days. They are good, and they have a bias that cannot be fixed by
writing them better: **what gets remembered is what was startling, never what was
frequent.** A gate missed once in a way that shocked you is in there; four
searches for something the audit should have shown and did not are in none of
them.

A line written at 11am costs nothing. The same line reconstructed at 9pm costs
the session, and the frequent things are the ones that fall out.

The log lives in `.fw/pass/<date>.md`, invisible to git like everything under
`.fw/`. At the end of the day the retro is assembled from it:

```bash
fw pass log          # today
fw pass log --all    # every day recorded
```

## What this does not do

It does not tell you the app works. It tells you where to look and gives you
somewhere to write what you saw. Whether the screen is right is a judgement
about the product, and no diff has an opinion on that.

It also does not replace `fw evidence`. That answers whether the checks pass;
this answers what the checks were never able to see.

## References

- `../skills/gating/SKILL.md` — resolving who reaches a control before judging it
- `./audit-tools.md` — turning a repeated manual finding into a script with a suite
- `./breaking-checks.md` — and then proving that script can fail
