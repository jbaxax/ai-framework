# Breaking a check before trusting it

## The rule

> **A check you have never seen fail is not a check.**

`rules/testing.md` states it for tests. It is not about tests. It is about every
instrument that reports on your work: a `grep` over build output, a regex audit,
a `jq` filter, a CI step, a probe against a live server, a script's own suite.

The reason is always the same shape. **A pattern that matches nothing and a
clean run print the same thing.** Silence is not evidence of absence; it is
absence of evidence, and the two are indistinguishable from the outside.

## Recipes by kind of check

| The check is | Break it by | Red looks like |
|---|---|---|
| A unit test or spec | Mutating the production line it claims to watch — `fw mutate`, or `--replace` when the edit is semantic | The suite fails, naming that test |
| A regex audit over templates | Two ways, and the second is the one people skip: feed the pattern a line it must match and one it must not; **then** remove a real gate from real files and require the count to move | The finding count changes |
| A probe against a live system | Including an endpoint you already know blocks — the positive control | That row answers 403 while the others do not |
| A tool's own suite | Changing one condition in the tool, not one message | Exactly the case for that condition fails |
| A matcher: router, parser, filter | Its boundaries — accents, plurals, word edges, the envelope it reads from | The case built for that boundary fails |
| An install or config check | Removing the thing it looks for | It reports the absence, and counts it as a problem |

The second row is the one that matters most, and it is the audit-script version
of mutation testing: a unit test on a regex proves the regex does what it says,
never that the script ever calls it. A detector that never fires passes every
unit test it has.

## When the break proves nothing

Three ways a deliberate break comes back green while the check is still broken.
All three happened in one day.

### 1. The mutation never applied

The edit script failed, the pattern matched nothing, a path resolved elsewhere —
and the run used **clean code**. Every green in that run is about the original,
not the mutant, and it reads exactly like a passing verification.

```
AssertionError: MUTATION MATCHED NOTHING
...
32 passed, 0 failed          ← this proves nothing whatsoever
```

Two real causes, one day apart: a shell `&&` chain that was not there, so the
suite ran after the mutation aborted; and copying a suite to another path, where
`FW_ROOT` is derived from `${BASH_SOURCE[0]}` and silently pointed at the wrong
tree — 29 failures that were the harness dying, not a signal.

**Assert that the mutation applied.** Count the occurrences and fail if it is not
exactly what you expected. A break that cannot prove it happened is not a break.

### 2. The mutation changed nothing observable

`bad "..."` was changed to `warn "..."` and the suite stayed green. The test was
not weak: **both print the same text**, and the `exit` was on the next line, so
nothing an assertion could see had moved.

**Break the condition, not the reporting helper.** `if [ -n "$x" ] && [ "$y" = 0 ]`
becomes `if false`. That is the decision; the message is only how it is announced.

### 3. Redundancy absorbed it

One of two date lookups was mutated and the suite stayed green, because a
fallback path found the same date by another pattern. The check was fine; the
tool simply had two ways to the same answer.

**Count how many paths produce the effect before concluding the test is weak.**
`grep -c` on the expression, then mutate all of them. A survivor with a second
path behind it is a different finding from a survivor with nothing behind it.

## Assertions that pass for the wrong reason

An assertion can be green because the thing is right, or because the assertion
cannot tell. These four are the ones that cost real time:

| Trap | Example | Fix |
|---|---|---|
| The needle is a prefix of another value | `Verdict: PASS` also matches `Verdict: PASS WITH WARNINGS` | Anchor with the delimiters: `**Verdict: PASS**` |
| Two messages share a tail | `commit(s) since it was written` and `touched its files since it was written` | Anchor on the half that differs |
| Asserting emptiness with `grep` | `grep -qF -- ""` on empty input returns 1, so the check can never pass | Compare a count: `"$(… | wc -l)"` against `0` |
| Vacuously true | A spec asserting a control is absent, on a screen that rendered nothing | Add the positive assertion first: prove the control appears when it should |

The last one is the same failure as the missing positive control in a probe, and
as a regex that never fires. **Every negative assertion needs a positive one
beside it**, or it passes on an empty page forever.

## What to record

The verification report says what was broken and what it printed when it went
red — not that it was checked.

```markdown
Instrument: .fw/audit/audit.py, filter DESHABILITADO_FIJO
Broken by:  removed the gate on 4 real toggles
Red output: HALLAZGOS: 37 (was 33)
```

A run is evidence. A description of a run is not, and that applies to the
instrument exactly as it applies to the code.

## References

- `../rules/testing.md` — the rule, on the push channel
- `../skills/verification-standards/SKILL.md` — the instrument is part of the evidence
- `./audit-tools.md` — where a repo's audit scripts live and how their suite is shaped
- `./mutation-testing.md` — `fw mutate`, the mechanical form of the same idea
- `./foreign-systems.md` — the positive control, for a probe against a live system
