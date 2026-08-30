---
name: testing
description: "Trigger: test, unit test, spec file, vitest, coverage, mock, assertion, TDD. Resolve the testing mode for the current context, then apply this framework's rules on what to test and how to assert."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "2.0"
---

## Activation Contract

Apply when writing, modifying, or reviewing tests — and when implementing logic
that a test would normally accompany.

This skill answers two separate questions. Resolve them in order:

1. **Do tests get written here?** — the Mode Resolution gate below.
2. **What gets tested, and how is it asserted?** — the rest of this file.

Never answer the second question before the first.

## Mode Resolution — resolve this first

An acceptance criterion **is** a test request. A spec scenario **is** a test
request. The rule against unprompted tests exists to stop noise during ad-hoc
work — it was never a rule against testing.

| Context | Tests? | Who governs the cycle |
|---|---|---|
| Task inside an SDD change, Strict TDD active | **Required, test first** | `sdd-apply/strict-tdd.md` |
| Task inside an SDD change, Strict TDD off | Required for every acceptance criterion | This file |
| Bug fix — any context | **Required**: a failing test that reproduces the bug, before the fix | This file |
| Refactor of existing code | **Required**: approval tests before touching production code | `sdd-apply/strict-tdd.md` |
| Observable UI behavior no test can see | **Required**: a browser loop closed against the stated criterion | This file, *Closing the loop in a browser* |
| Ad-hoc edit, spike, exploration, throwaway | Only when explicitly requested | This file |

**When Strict TDD is active, this file never blocks a test.** The cycle belongs
to `strict-tdd.md`; this file supplies the judgment it does not carry — which
layer is worth the cost, what must never be mocked, which assertions are fake.
Both apply at once. They do not compete.

**When no mode is stated and the work is not part of an SDD change**, the last
row applies: implement, then declare untested pure logic in one line.

Announce the resolved row before writing or skipping a test. One line:
*"Testing mode: bug fix — failing test first."* This is what makes the decision
auditable instead of silent.

## The Evidence Gate

Once the mode says a criterion must be proven, the question is **not** "is there
a test". It is:

> What is the cheapest evidence that can actually prove *this* criterion, and
> does that evidence exist?

Both halves matter. Reaching for a more expensive layer than the criterion needs
wastes time and tokens. Reaching for a cheaper one that is blind to the failure
produces a green check that proves nothing — which is worse, because now you
trust it.

| What the criterion is about | Cheapest sufficient evidence | Relative cost |
|---|---|---|
| A domain rule, calculation, or transformation | Unit test on the pure function, executed | lowest |
| A schema or mapper at the `infrastructure/` boundary | Contract verification run against the real endpoint | low |
| A response shape from a backend you do not own | Contract verification — a unit test cannot see their drift | low |
| Observable UI behavior: focus, ordering, disabled state, visibility | A browser loop closed against the stated criterion | medium |
| Config, constants, types, copy | Typecheck and build passing | near zero |
| A refactor that must not change behavior | Approval tests green before and after | low |
| Performance, load, anything that only fails in production | Out of scope — say so rather than faking it | — |

**Never claim a criterion is met without naming its evidence row.** "Implemented"
is not evidence. "Tests pass" is not evidence unless the run is shown.

### Why the cheapest, and not the most

The rule against unprompted tests was never about disliking tests. It was about
cost: work nobody asked for spends time and tokens that the change did not
budget. A gate that demands the maximum everywhere recreates exactly that
problem, and a gate that costs too much gets switched off — at which point it
protects nothing.

So the gate scales. A criterion about a tax calculation is proven by a unit test
that runs in milliseconds. The same criterion proven through the UI costs
hundreds of times more and tells you less about where it broke.

### Evidence must be produced, not asserted

Run the checks and paste what came back:

```bash
fw evidence
```

It executes the project's typecheck, tests, and contracts, and prints a table
with each command, its exit code, and its result. A verification report that
contains a summary of that table instead of the table itself is not a
verification — it is a claim about one.

## Closing the loop in a browser

Some criteria are invisible to every test layer. A modal that does not move
focus to the first unfilled field throws no error, breaks no type, and fails no
unit test. It is only visible to something that looks.

Driving the running app to see the result, fixing, and looking again is the
right tool for exactly those criteria. Two rules make it honest:

**The criterion comes first, in writing.** Before the loop begins, state what
would prove it done:

> *When the modal opens with required fields empty, focus lands on the first
> unfilled required field.*

Without that sentence, an agent iterating "until there are no errors" converges
on *no visible errors*, which is a different and much weaker claim. It will stop
when the screen stops complaining — and the bug you are chasing may never have
complained.

**The loop is throwaway.** It closes the loop on this change and is not kept.
Promote it to a committed browser spec only for a flow whose breakage costs
money — sign-in, payment, issuing a document. Everything else is cheaper to
re-verify by looking again than to maintain forever, and a brittle suite that
gets deleted after three red builds never protected anything.

Report what you observed, not that you observed. *"Opened the modal with two
required fields empty; focus landed on the first."*

## Hard Rules

These hold in every mode, including Strict TDD.

- **Never write a test that cannot fail.** `expect(component).toBeTruthy()`
  after merely creating it verifies the framework, not the code. Delete
  CLI-generated `should create` specs instead of keeping them.
- Test behavior, never implementation. Assert on returned values and visible
  output, never on internal call counts, private state, or CSS class names.
- One runner: **Vitest** — for both Next.js and Angular v22 (`ng test`).
- Colocate: `calories.ts` → `calories.test.ts` beside it.
- No conditional logic (`if`, loops) inside a test. Use separate cases or `it.each`.
- Do not mock what you own. Mock only true external boundaries — network, clock,
  randomness.
- **If a test needs more mocks than assertions, it is at the wrong layer.**
  Extract the logic to a pure function and test that instead.
- Never chase a coverage percentage. Coverage measures execution, not correctness.
- In the ad-hoc row only: when pure logic ships without tests, state it in one
  line at the end — *"Untested pure logic: `calculateTotal`, `applyDiscount`."*
  One line, no lecture.

## Decision Gates

### What to test

Priority order. Stop when cost exceeds value.

| Target | Test it? |
|---|---|
| `domain/` pure logic | **Yes** — highest value, no mocks, fast |
| Zod schemas and response mappers in `infrastructure/` | Yes — this is where backend drift is caught |
| `application/` hooks | Only when the logic is non-trivial |
| Critical interactive flows (login, checkout, payment) | Only these components |
| Presentational components, getters, wrappers | No |
| Third-party libraries, TypeScript-guaranteed types | No |

Component tests are expensive and brittle. Buying confidence in `domain/` costs a
fraction of the same confidence bought through the UI.

Under Strict TDD this table still decides the **layer**, not whether a test
exists. A task whose target lands on a "No" row is implemented against the
highest-value testable seam nearby — usually by extracting the logic into
`domain/` first.

### Existing code without tests

The common case in maintenance work. Do not backfill a suite for a module you
were not asked to change.

| Situation | Action |
|---|---|
| Modifying a file that has tests | Run them first. Record the baseline. A pre-existing failure is reported, never fixed as a side effect |
| Modifying a file with no tests | Test only the behavior you are changing. Leave the rest |
| Refactoring without behavior change | Approval tests first — capture current output, even if it looks wrong |
| Asked only to read or diagnose | No tests |

## Execution Steps

1. **Resolve the mode** and announce the row that applied.
2. If Strict TDD is active, follow `strict-tdd.md` and stop reading here for the
   cycle — return to this file only for layer choice and assertion quality.
3. Name the case after the behavior: `returns zero when the list is empty` —
   never `should work` or `test 1`.
4. Arrange, act, assert — in that order, visibly separated.
5. Write edge cases first: `null`, `undefined`, zero, negative, empty array,
   boundary values. The happy path rarely holds the bug.
6. One behavior per test. Multiple unrelated assertions mean multiple tests.
7. Keep tests deterministic: inject the clock and randomness, never call
   `Date.now()` or `Math.random()` directly in the code under test.
8. Run the suite and report actual output. Never describe unverified tests as
   passing.

## Assertion Quality

An assertion is real only when all three hold:

1. It calls production code.
2. It asserts a specific expected value drawn from the criterion.
3. It would fail if the implementation were wrong.

Banned outright: tautologies (`expect(true).toBe(true)`), bare existence checks
(`toBeDefined`, `not.toBeNull` with nothing else), empty-collection assertions
with no setup explaining the emptiness, assertions inside a loop that may iterate
zero times, and any assertion on a CSS class name.

A test that renders a component and asserts only that it rendered is a smoke
test. It does not count.

## Interaction with SDD

`sdd-init` resolves Strict TDD per project and caches it. It defaults to
**enabled** whenever a test runner exists and no explicit marker overrides it.
That default is intentional and this framework does not fight it.

To disable it for a specific project, set the marker explicitly — never by
weakening this skill:

```yaml
# openspec/config.yaml
strict_tdd: false
```

If a session ever surfaces both "Strict TDD is active" and "tests only on
request", the Mode Resolution table above is the tiebreaker. Report that the
conflict appeared, then continue under the resolved row.
