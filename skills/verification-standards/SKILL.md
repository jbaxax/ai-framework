---
name: verification-standards
description: "Trigger: verify, verification, verification report, validate implementation, prove a change, definition of done, evidence, test evidence, PASS WITH WARNINGS, archive readiness. This project's standard for what counts as proof that a change is complete."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "1.0"
---

## Activation Contract

Apply whenever a change is being verified, a verification report is written, or a
verdict is assigned — including inside an SDD verification phase.

This file **tightens** the verification bar for projects using this framework. It
adds requirements; it removes none. Where a tool's default is more permissive
than what follows, this file governs, because a project may hold a higher
standard than the tool's floor.

## Hard Rules

- **A run is evidence. A description of a run is not.** A report stating that
  tests pass, without the command and its output, is a claim about a
  verification rather than a verification. Paste the table from `fw evidence`.
- **Completion without executed evidence is CRITICAL**, never a warning. When the
  project has a test runner and a task is marked complete with no evidence that
  anything was executed, the verdict is `FAIL`.
- **A missing artifact lowers confidence, never the bar.** Verifying a change
  that has tasks but no specs means claiming less — task completion only, not
  spec correctness. It does not mean requiring less proof of what is claimed.
- `PASS WITH WARNINGS` on completion alone is available **only** when the project
  has no test runner at all, and the report must name that as the reason.
- Every criterion that the Evidence Gate requires proving must name **which row**
  of that gate proved it. See `../testing/SKILL.md`.
- **A green suite proves the tests ran, not that they watch anything.** When a
  criterion is claimed covered by a test this change did not write, that claim is
  unverified until a mutant on the relevant file is killed. Run `fw mutate` and
  paste its table. A `SURVIVED` row is unprotected code with a green check over
  it, and the criterion it was supposed to prove is `UNVERIFIED`.
- Never assign a verdict for work you did not observe. If a check could not run,
  report it as `BLOCKED` with the reason — never as passing, and never as a
  warning that reads like passing.

## Decision Gates

| Condition | Verdict |
|---|---|
| Any check in `fw evidence` exits non-zero | `FAIL` |
| Task marked complete, test runner exists, no executed evidence in the report | `FAIL` — `UNVERIFIED` |
| Report describes a test run without showing its output | `FAIL` — `UNVERIFIED` |
| Criterion about backend response shape, no contract run | `FAIL` — the wrong evidence layer was used |
| Criterion about observable UI behavior, no browser observation reported | `FAIL` — no test layer can see it |
| No test runner in the project at all | `PASS WITH WARNINGS`, stating that as the reason |
| Criterion claimed covered by a pre-existing test, mutant on that file survived | `FAIL` — `UNVERIFIED` |
| Evidence executed, all green, every criterion mapped | `PASS` |

## Execution Steps

1. Run `fw evidence` and keep its output verbatim.
2. For each acceptance criterion, name the Evidence Gate row that applies and
   point at the evidence that satisfies it.
3. List any criterion with no evidence. That list is the finding — do not soften
   it into a suggestion.
4. Assign the verdict from the gates above.
5. Include the evidence table in the report itself, not a summary of it.

## Output Contract

A verification report carries, in this order:

1. The `fw evidence` table, verbatim
2. Criterion → evidence row → where the evidence lives
3. Criteria with no evidence, named
4. Verdict, with the gate row that produced it

## Why this lives here and not in the tool

These rules were briefly patched directly into the installed SDD verification
skill. That file belongs to its author: a reinstall overwrites it silently, the
change has no history, and nothing distinguishes an edit of ours from the
author's own text.

Owning our standards in our own skill removes all three problems at once. The
registry indexes user and project skills, and phase agents load matching skills
by path before doing their work, so a stricter standard reaches the verifier
without anyone editing a file they do not own.

The same principle already governs how this framework installs: symlink what is
ours, copy what is meant to diverge, and never patch what belongs to someone
else.

## References

- `../testing/SKILL.md` — the Evidence Gate that decides which proof a criterion needs
- `../../docs/mutation-testing.md` — `fw mutate`, and how to read a survivor
- `../../CLAUDE.md` §6 — definition of done
- `../../bin/fw` — `fw evidence` produces the table these rules require
