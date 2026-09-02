# {{ID}} — {{NAME}}

Epic: {{EPIC}}
Status: draft
Created: {{DATE}}

## User story

As a ‹role›, I want ‹capability›, so that ‹outcome›.

> If the role or the outcome is unknown, say so here. Do not guess — the outcome
> is what lets you reject a bad solution later.

## Acceptance criteria

EARS shape. Aim for the happy path, the empty state, the failure, and the
permission rule.

| # | Criterion |
|---|---|
| 1 | The system shall … |
| 2 | When ‹trigger›, the system shall … |
| 3 | While ‹state›, the system shall … |
| 4 | If ‹condition›, then the system shall … |

## Gaps

Direct questions, ordered by how much rework a wrong guess would cost. `None` if
the request was complete.

1. {question} — blocks criterion {n}

## Assumptions

Each with its blast radius: what changes if the assumption turns out wrong.

- {assumption} — if wrong, {what has to change}

## Evidence

Filled after implementation. A criterion with no home was not implemented, and a
criterion with no evidence row is unverified.

| Criterion | Lives in | Proven by |
|---|---|---|
| 1 | `path/to/file.ts` | `fw evidence` / `fw mutate` / browser loop |
