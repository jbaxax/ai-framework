# Workflow — from a request to merged code

Where this framework sits in the software lifecycle, and how to write the prompt
that starts each phase.

## The five phases

```
Requirement  →  Criteria  →  Design  →  Implement  →  Verify
   (them)       (skill)      (ask)      (rules)      (proof)
```

Every AI coding workflow in wide use converges on roughly this shape —
GitHub Spec Kit, Kiro, BMAD, the Claude Code spec workflows. The names differ;
the order does not. The reason is not process for its own sake: an agent that
starts at *Implement* has to invent the first three phases silently, and it will.

This framework used to start at **Implement**. `CLAUDE.md` and the skills answer
*how to build it*. Nothing answered *what exactly are we building*. That is what
`skills/requirements/` covers now.

| Phase | Who owns it | Artifact | Where the rules live |
|---|---|---|---|
| Requirement | Your client, PM, or boss | A message, a call, a story | — |
| Criteria | You + Claude | EARS acceptance criteria | `skills/requirements/` |
| Design | You decide, Claude proposes | Layer plan, contracts | `CLAUDE.md` §1.2, §3 |
| Implement | Claude | Code | `CLAUDE.md`, `skills/` |
| Verify | Claude, proven | Real output | `CLAUDE.md` §5 |

**Do not collapse Criteria into Implement.** That is the whole point. Criteria
are cheap to change while they are still sentences.

## Writing the prompt

### Case 1 — you have a user story

Whether you wrote it or generated it elsewhere, a story is a starting point, not
a spec. Hand it over and ask for the gaps first:

```
Feature: <one line>

User story:
As a <role>, I want <capability>, so that <outcome>.

<paste any acceptance criteria you already have>

Backend: <the .md, the endpoint, or "not built yet">

Turn this into EARS acceptance criteria and list what's missing.
Don't write code yet.
```

An AI-generated story reads complete and usually is not — it fills the gaps with
plausible defaults, which is exactly the failure this phase exists to catch.
Getting the gaps back as questions is the point of the round trip.

### Case 2 — it came over WhatsApp or in person

Your real case most of the time. Do not clean it up before pasting it —
paraphrasing is where the requirement quietly changes.

```
This came in over chat, unedited:

"<paste it, in the original wording>"

<add whatever context only you have: which screen, which module,
 who asked, what they were doing when they hit it>

Restate it as acceptance criteria and tell me what's missing.
```

The gap list comes back as questions. **Send those questions back over the same
chat.** That is the artifact the project never had — you just wrote the missing
requirements doc as a side effect of asking.

### Case 3 — it's a bug report

```
Bug, reported over chat:

"<paste it>"

Expected behavior: <what should happen, if you know — say so if you don't>
Module: <where>

Follow the bug flow: Report, Analyze, Fix, Verify.
Don't fix anything until the root cause is named.
```

Chat bug reports mix the symptom with a guess at the cause. When **Expected**
cannot be filled from an existing criterion, the behavior was never specified —
that is a new requirement, and it needs approval, not a quick fix.

### Case 4 — implementing approved criteria

```
Implement criteria 1-4 from above.

Backend: <verified response, or "verify it first">
Tests: <"none" | "unit tests for the domain rules">

Report where each criterion ended up.
```

Name the criteria you want. "Implement everything" is how a feature grows a
second feature that nobody asked for.

## Two habits that carry most of the value

**Know which testing mode you are in.** There is no single default —
`skills/testing/` resolves it from context. Approved criteria and bug fixes carry
their own test requirement; ad-hoc work does not. Saying `Tests: none` still
costs four words and still removes the ambiguity when you want it off.

**Ask for the criterion → file mapping at the end.** A criterion with no file is
a criterion that was not implemented. It is the cheapest audit available, and it
catches the item that quietly fell off a list of six.

## What this does not fix

Criteria do not make a bad requirement good. If the person asking has not decided
what they want, the gap list comes back long and the honest answer is to go ask
them — not to pick defaults and build.

That is not the framework failing. That is the framework telling you the
requirement is not ready, at the only moment when finding out is still cheap.

## Next

- `../skills/requirements/SKILL.md` — the EARS patterns and the bug flow
- `../CLAUDE.md` — the rules that govern the Implement phase
- `./setup.md` — installing this framework in a project
