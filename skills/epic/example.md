# Epic: framework lifecycle build-out

A real epic, kept as the reference for the shape. It is the one governing this
repository's own rework, so it is filled with decisions that actually bind.

## Outcome

The framework covers the whole lifecycle — planning, evidence, delivery — and
installs into an existing project without reaching the people who share it.

## Boundary

### In

- Testing decided by context, and proven by executed evidence
- Verifying a backend that is not ours against its own documentation
- Installing into new and existing projects, per stack
- A boundary artifact that survives between changes
- Backend rules reaching parity with the frontend ones

### Not in

- Anything shared with teammates — this is single-operator tooling, and every
  decision below follows from that
- Story points, sprints, velocity — they measure a team, and there is no team
- Publishing to a package registry — a dependency in `package.json` is committed,
  which defeats the point
- Replacing the SDD phases already installed — this framework supplies standards
  and evidence, not a second pipeline

### Not decided yet

- Whether the browser loop should be driven by a committed helper or ad hoc —
  blocks the E2E slice
- Whether `~/.claude/CLAUDE.md` and `settings.json` should be versioned too —
  they are ours and currently unbacked; blocks the two-machine install guide

## Standing decisions

| Decision | Because | Binds |
|---|---|---|
| Rules and skills are symlinked into the user scope, never copied | A copy is stale the day the source changes, and a copy inside a repo is visible to everyone in it | Every install slice |
| Templates are copied, not linked | Their job is to diverge into project code | Every template slice |
| Anything the framework puts in someone else's repo lives under `.fw/` | One namespace covered by one global ignore rule | Contracts, docs, future tooling |
| Evidence scales to the cheapest proof that can catch the failure | A gate that demands the maximum costs more than the change budgeted, and gets switched off | Testing, verification, E2E |
| Evidence is produced by a command, never asserted in prose | A summary of a run is not a run | Verification, CI |
| The installer has no runtime dependency | It may run on a machine without bun | `bin/fw` |
| Do not fight a framework's imposed structure; map the dependency rule onto it | Already settled once for Angular: the rule lives in the imports, not the folder names | The Nest slice |
| Never edit a file belonging to another author; own the standard in our own skill instead | A patched vendor file is overwritten silently on reinstall, has no history, and cannot be told apart from the author's own text | Anything that would tighten an installed tool's behaviour |

## Slices

| # | Slice | Status | Depends on |
|---|---|---|---|
| 1 | Testing mode resolved by context | done | — |
| 2 | Contract verification against backend docs | done | — |
| 3 | Installer with stack and sharing detection | done | — |
| 4 | Evidence gate scaled by cost, `fw evidence` | done | 1 |
| 5 | Epic — boundary across slices | done | — |
| 6 | Verification standards owned in our own skill | done | 4 |
| 7 | NestJS profile at parity | not started | 3 |
| 8 | Visual design layer | not started | — |
| 9 | Backlog and Definition of Ready | done | 5 |

## Open questions for the requester

None outstanding. The two unresolved items are technical and sit in
*Not decided yet*.
