---
name: testing
description: "Trigger: test, unit test, spec file, vitest, coverage, mock, assertion. Apply this framework's testing rules — tests are written on request only."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "1.0"
---

## Activation Contract

Apply when writing, modifying, or reviewing tests — and when implementing logic
that a test would normally accompany.

## Hard Rules

- **Do not write tests unless they are explicitly requested.** Implementing a
  feature is not a request for tests. Do not add them "for completeness".
- When pure logic ships without tests, state it in one line at the end:
  *"Untested pure logic: `calculateTotal`, `applyDiscount`."* One line, no lecture.
- **Never write a test that cannot fail.** `expect(component).toBeTruthy()` after
  merely creating it verifies the framework, not the code. Delete CLI-generated
  `should create` specs instead of keeping them.
- Test behavior, never implementation. Assert on returned values and visible
  output, never on internal call counts or private state.
- One runner: **Vitest** — for both Next.js and Angular v22 (`ng test`).
- Colocate: `calories.ts` → `calories.test.ts` beside it.
- No conditional logic (`if`, loops) inside a test. Use separate cases or `it.each`.
- Do not mock what you own. Mock only true external boundaries — network, clock, randomness.
- Never chase a coverage percentage. Coverage measures execution, not correctness.

## Decision Gates

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

## Execution Steps

1. Confirm tests were requested. If not, implement and report untested logic.
2. Name the case after the behavior: `returns zero when the list is empty` —
   never `should work` or `test 1`.
3. Arrange, act, assert — in that order, visibly separated.
4. Write edge cases first: `null`, `undefined`, zero, negative, empty array,
   boundary values. The happy path rarely holds the bug.
5. One behavior per test. Multiple unrelated assertions mean multiple tests.
6. Keep tests deterministic: inject the clock and randomness, never call
   `Date.now()` or `Math.random()` directly in the code under test.
7. Run the suite and report actual output. Never describe unverified tests as passing.

## Output Contract

Report: whether tests were requested, which behaviors are covered, the real runner
output, and any pure logic left untested.

## References

- `../../CLAUDE.md` — layer contracts; `domain/` is the primary test target
- `../api-client/SKILL.md` — validating backend responses at the boundary
