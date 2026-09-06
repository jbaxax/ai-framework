---
name: delegation
description: "Trigger: delegate, subagent, sub-agent, spawn an agent, explore the codebase, map the module, audit the project, find every usage, how does this work in the project, delegar, subagente, explorá el proyecto, revisá todo el módulo, buscá dónde se usa, mapeá, auditá, cómo funciona esto en el proyecto. Decide whether to hand work to another agent by what it costs to verify the answer, not by how many files it touches."
---

# Delegation

## The rule

> **The cost of delegating is the cost of verifying what comes back.**

Not the number of files. Not the size of the task. What decides is whether the
thing that returns can be checked cheaply, because an unverified answer from a
subagent is not work you received — it is work you now owe.

## Why the file count is the wrong test

A count is a signal that a task is large. It says nothing about whether handing
it off will pay, and the same day produced both outcomes:

| Delegated | Outcome |
|---|---|
| Sixteen modals, an edit already understood, repeated per file | Clean. Bounded context, good result, the agent even made a sound call of its own |
| Five pages, a claim about which ones lacked a template in scope | The claim was **partly false** — one page already had it transitively. Verifying it, failing to close it with any reliable instrument, and deciding to discard it cost more than making the change inline |

Both crossed the same threshold. One paid and one did not, and the file count
could not tell them apart.

## The table that does

Read the row for **what the agent hands back**, not for what it had to read:

| What comes back | How you check it | Verdict |
|---|---|---|
| Code | It compiles, the suite runs, a mutant dies | Cheap — delegate freely |
| Locations: where a symbol is used, which files match | Open two and look | Cheap — delegate |
| A claim about *your* code's behavior | Read that code, or run it | Moderate — delegate, demand `file:line` |
| A claim about a **library's** behavior | Needs an experiment you do not have | Expensive — do it inline |
| A claim about a system you do not deploy | Needs a probe — `../../docs/foreign-systems.md` | Expensive — measure, never delegate the conclusion |

The bottom two rows are the same failure as reading a foreign controller, one
level further out: **a subagent's report is a hypothesis wearing the clothes of a
finding.** It arrives with confidence, a structure, and no way to tell a measured
claim from a plausible one.

## A cold agent over-asserts

An agent that starts with no context justifies its existence with a big finding.
That is not dishonesty, it is the shape of the incentive, and it means the
request decides the quality of the answer:

| Ask for | Because |
|---|---|
| "Where is `removeCollection` called from?" | A list of locations, each one checkable in seconds |
| "Which pages are missing the gate?" | Invites a confident wrong answer that costs hours to disprove |

Ask for evidence and locations. Draw the conclusion yourself — that is the part
you cannot delegate, because you are the one who will act on it.

## What the handoff must carry

Every claim comes back with a `file:line`. A claim with no location is not
checkable, so it is not a finding; it is a rumour with a citation style.

Before acting on any of it, spot-check two claims. If either is wrong, discard
the report — a cold agent that got one wrong has no reason to be right about the
rest, and repairing a report costs more than redoing the work.

## Relation to the file-count rule

The orchestrator rules in `~/.claude/CLAUDE.md` make delegation mandatory past
four files to read or two non-trivial files to write. Read that count as **stop
and decide**, not as *delegate*:

- Mechanical and already understood — the same edit applied per file — stays
  inline no matter how many files it touches. Delegating it buys nothing and
  costs a handoff.
- Analytical or discovery work delegates even at two files, but scoped to
  **locations and evidence**, never to a verdict.

The threshold is right about when to think. It is wrong as an answer.

## References

- `../verification-standards/SKILL.md` — an unverified claim is `UNVERIFIED`,
  not a warning
- `../../docs/foreign-systems.md` — the same rule applied to another system's
  source
- `../../rules/foreign-source.md` — hypothesis versus evidence, loaded by path
