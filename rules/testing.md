---
paths:
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/__tests__/**"
  - "vitest.config.*"
---

# Testing rules

Loaded automatically when working with test files. This is the decision core
only — the seam, the layer table, the tautology that survives review and the
full Evidence Gate live in `../skills/testing/SKILL.md`. Read that file before
writing tests for anything non-trivial.

## Announce the mode before the first test

State which row applies, in one line, before writing or skipping a test. This is
what makes the decision auditable instead of silent.

| Context | Tests? |
|---|---|
| Task in an SDD change | Required — one per acceptance criterion |
| Bug fix, any context | Required — a failing test that reproduces it, **first** |
| Refactor of existing code | Required — approval tests before touching production code |
| Modifying a file that has tests | Run them first, record the baseline. A pre-existing failure is reported, never silently fixed |
| Modifying a file with no tests | Test only the behaviour you are changing |
| Ad-hoc edit, spike, throwaway | Only when explicitly requested |

*"Testing mode: bug fix — failing test first."*

## The Evidence Gate

Not "is there a test", but:

> What is the cheapest evidence that can actually prove *this* criterion, and
> does that evidence exist?

Reaching for a layer more expensive than the criterion needs wastes the budget.
Reaching for one that is blind to the failure produces a green check that proves
nothing — worse, because now you trust it.

Never claim a criterion is met without naming its evidence. "Implemented" is not
evidence. "Tests pass" is not evidence unless the run is shown.

## Non-negotiable

- **Name the seam out loud before the first test** — what is observed, and from
  outside what boundary. A test written at an unnamed seam drifts inward and
  starts asserting on private helpers and class names.
- **Never write a test that cannot fail.** Delete CLI-generated `should create`
  specs — but if the stub is the *only* test in the file, record the module as
  untested and replace it, rather than deleting it and calling it covered.
- **An expected value may never be produced by the code under test**, or by
  anything it imports. That tautology passes by construction and survives review.
- Assert on returned values and visible output. Never on call counts, private
  state, or CSS class names.
- **Verify the assertion is on a key that exists.** An assertion against a field
  the fixture never set is vacuously true and passes forever.
- **Make any improvised check fail once before trusting it.** A `grep` over build
  output, an audit script, a `jq` filter — nothing tests these, and a pattern that
  matches nothing is indistinguishable from a clean run. Break what it watches,
  confirm it goes red, then believe it. See `../skills/verification-standards/SKILL.md`.
- No conditional logic inside a test. Mock only true external boundaries.

## Proving it, not claiming it

```bash
fw mutate src/domain/totals.ts   # break the code on purpose; must go red
```

`SURVIVED` is production code you can break with the suite green. `NOT VIABLE`
means the compiler rejected the edit and no test ran — excluded from the score.
Reach for it on any suite you did not write that reports green, and on any claim
that an existing test already covers a criterion.
