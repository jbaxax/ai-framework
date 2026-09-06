# Audit tools the repository owns

## The problem this solves

A project accumulates scripts that answer questions no library answers: which
templates have an ungated destructive control, which routes no menu reaches,
which endpoints a role can actually call.

These scripts are unusual in one way that matters. A test proves one behaviour.
**An audit script decides which behaviours get looked at at all** — so a blind
spot in it does not produce a failure, it produces a silence, and the silence
reads exactly like a clean project.

The case this document was written from: one `audit.py` accumulated **five**
blind spots over two sessions, discovered one at a time, and two of the five were
found by a person looking at the screen rather than by any tool.

| # | Blind spot | Found by |
|---|---|---|
| 1 | Ternary labels in TS — `label: x ? 'A' : 'B'` | the agent, while validating |
| 2 | A gate held in a variable, outside the 14-line window | the agent |
| 3 | A destructive action gated by an `.update` permission | **the user** |
| 4 | Icon-only buttons, with no `label` | a subagent reading the file |
| 5 | Toggles (`p-toggleswitch`), with no `label` | **the user** |

And one underneath all five: the regex `@(if|else if)\s*\(([^)]*)\)` **never
matched** `@if (can('x'))`, because `[^)]*` stops at the call's own parenthesis.
Block tracking had never worked. Nothing said so, because a regex that matches
nothing and a file with nothing to find print the same thing.

## Where they live

The same two locations `fw` already uses for contracts, and for the same reason:

| Path | Meaning |
|---|---|
| `.fw/audit/` | Yours. Invisible to git, like everything else under `.fw/` |
| `audit/` | The team's. Committed, reviewed, and shared |

An audit that decides which security controls get reviewed usually belongs in
the second one. A script only you run is a script only you can be wrong with.

## The suite is not optional

```
audit/
├── audit.py
└── tests/
    └── run.sh      ← executable; exit non-zero when a case fails
```

`fw evidence` runs `tests/run.sh` and reports it as the `audit` row. A directory
with no `tests/run.sh` is a `NOT RUN` row that lowers the verdict to
`PASS WITH WARNINGS`, because an instrument nobody tests is an instrument nobody
can trust.

`run.sh` is a shell script so the language of the audit never has to match the
language of the project. What it runs inside is yours.

### It runs the suite, never the audit

An audit with open findings is a project with work left, not a broken run. If
`fw evidence` failed on the findings, the row would be deleted within a week and
the instrument would go back to having nothing watching it.

The suite answers the only question the evidence table can ask about an
instrument: **does it still detect what it claims to detect?**

## The rule that keeps it honest

> **A new blind spot ships with the case that would have caught it.**

Every one of the five above was a silence, and every one of them is now a test
that fails if the pattern is relaxed. The most dangerous one is the fifth:

```
[disabled]="true"          ← a control genuinely disabled, correctly filtered out
[disabled]="toggling() === row.id"   ← a live control, must NOT be filtered
```

Loosening that filter to `\[disabled\]` drops the finding count from 33 to 15
and **looks like an improvement**. The case that pins it is what makes the
difference between a fix and a regression that reads as progress.

## The finding is not complete without its entry point

An audit script reads one file at a time, so it can only ever see half of a
gating claim. The other half is who reaches the control, and it is not written
anywhere in that file.

Every row it produces gets triaged into four columns before anyone acts on it:

```markdown
| Control | Código | Punto de entrada | Gate del punto de entrada |
|---|---|---|---|
| Eliminar cobro | collection.html:142 | menú Cobros | `can('cobros.view')` |
| Eliminar cobro | collection-list.html:88 | menú Cobros | `can('cobros.view')` |
```

Two rows for one control is the sibling page that would otherwise be missed —
one was fixed and the other called the same method with the same hole, three
hours apart. `../skills/gating/SKILL.md` holds the triage and the four verdicts.

## Writing a case

Two shapes, and the second is the one people skip:

1. **Unit** — feed the pattern a line it must match and a line it must not.
2. **Differential** — take real files, remove a gate on purpose, and require the
   audit's output to change. This is the one that catches a detector that never
   fires at all, which no unit test on a regex can see.

```sh
#!/bin/sh
# audit/tests/run.sh
set -e
python3 tests/patterns_test.py      # unit: each pattern, matching and not
python3 tests/differential_test.py  # remove a gate, require the count to move
```

The differential is the audit-script version of `fw mutate`: break the thing on
purpose and require the instrument to notice. `../rules/testing.md` states the
same rule for improvised checks — this is where it lands for a tool that lives
in the repository.

## References

- `../skills/verification-standards/SKILL.md` — the instrument is part of the evidence
- `../rules/testing.md` — make an improvised check fail once before trusting it
- `./mutation-testing.md` — `fw mutate --replace` validates an audit script directly
