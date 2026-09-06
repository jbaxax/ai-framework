---
name: work-units
description: "Trigger: commit, commitear, commitea, commiteá, commite, commits, split the commits, partir en commits, work unit, unidad de trabajo, commit message, mensaje de commit, conventional commit, PR, pull request, stacked PR, review slice, historia de git, git history. Decide what belongs in one commit, and split finished work without losing any of it."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "1.0"
---

## Activation Contract

Apply when a change is finished and has to become history: choosing what goes in
each commit, writing the message, or splitting work that was done in one pass.

## What a work unit is

> **One commit is one decision a reviewer can accept or reject on its own.**

Not one file, not one day, not one feature. The test is whether someone could
revert it alone and be left with a system that still makes sense.

| Belongs together | Because |
|---|---|
| A behaviour and the tests that watch it | A commit that adds behaviour with no test is a claim; the test is the evidence, and evidence separated from its claim is reviewed twice |
| A rule and the place it is written down | A rule that lives only in a commit message is a rule nobody will find |
| A fix and the case that reproduces it | Without it the next person cannot tell a fix from a coincidence |

| Belongs apart | Because |
|---|---|
| A rename or a reformat | It drowns the diff it travels with. Its own commit is boring and instantly reviewable |
| Two features that happen to touch one file | The shared file is not the unit; the decision is |
| A dependency bump | It has its own blast radius and its own reason to be reverted |

## Splitting work that was already done in one pass

The common case, and the one that goes wrong. Work finishes as one dirty tree
where several units are tangled, and shared files — a README, a standards
document — carry edits belonging to three different units at once.

Splitting by hunks is fragile and unverifiable. What works:

1. **Snapshot first.** `fw split start` fingerprints every dirty file. Without a
   baseline there is nothing to compare against afterwards, and a lost file is
   invisible.
2. **Reset the tracked files** to the base commit. New files stay where they are.
3. **Replay the change in stages**, committing between them.
4. **Prove it.** `fw split verify` — the content is identical to the baseline,
   nothing was left uncommitted, and every intermediate commit parses on its own.

Step 3 has a precondition that has to be decided *before* the work, not after:
**keep the edit scripts.** A change applied through a recorded patch can be
replayed in any order; a change typed by hand cannot, and the split then becomes
a manual reconstruction where the only check is care.

A real case: seventeen files, four units, one standards document edited by three
of them. Replaying the recorded patches in order and then comparing all
seventeen files against the snapshot produced a split that was **provably**
correct rather than probably correct.

## The message

Conventional commits: `type(scope): what changed`.

The subject says what changed. The body says **why**, because the diff already
covers what:

- The failure this prevents, named concretely.
- The alternative that was rejected, and what it cost. A message with one option
  in it teaches nothing.
- The evidence, when the claim needs it.

Never a list of files. That is `git show`, and repeating it wastes the one place
where intent can live.

Project conventions win over this document. Attribution and trailers follow
whatever the project has already decided.

## Before it becomes history

- `fw evidence` — a commit that has never been verified is a claim.
- `fw split verify` — when the work was split, prove the split.
- Never commit or push unasked. It leaves the working tree, which is where the
  line for asking sits.

## References

- `../verification-standards/SKILL.md` — what counts as proof before a change ships
- `../../docs/breaking-checks.md` — proving the checks in that evidence can fail
- `../delegation/SKILL.md` — the same idea for topology: what one worker owns
