# Daily use — what fires by itself, and what you still have to say

`setup.md` installs the framework. `workflow.md` explains the lifecycle. This
file answers the only question that matters once both are done: **what do I
actually have to type?**

## The short answer

> **"Elabora un plan para ..."**

That is the whole trigger. Follow it with anything — a backend `.md`, a
screenshot, a pasted chat message, a bug, "dar mantenimiento al módulo de
roles". The prompt hook recognises the phrase and pushes the agent onto the
right track before it writes a single step.

It also answers to `elaborá`, `hazme`, `hace`, `armá`, `creá`, `prepara`
un plan, and to `make a plan`. It deliberately stays quiet on *"el plan de la
empresa"* and *"planning poker"*.

## What that one phrase sets in motion

The hook injects a decision table. The agent must say, in one line, which row it
is on before proposing anything:

| What you handed it | What the plan opens with |
|---|---|
| A new capability — a document, an image, a pasted case, prose | Acceptance criteria and a user story written to `.fw/product/`, before any step. The steps then cite the criteria by number |
| A bug, a correction, something broken | A reproduction that goes red, before any theory about the cause. No user story |
| Maintenance or a refactor | Read it first. Approval tests before production code is touched |

Then, on every row:

- **Blast radius before steps.** Where `graphify-out/` exists, the agent asks the
  graph — `graphify affected "<file>"` — instead of grepping. No graph? It has to
  say so, because an unmeasured blast radius is an assumption.
- **Questions are the exception.** If your document or your prompt already
  answers something, it does not ask. It writes the story and asks whether the
  story is right. It asks only where nothing you gave it answers, one question at
  a time.
- **Interface work goes to `impeccable`** — layout, hierarchy, empty and error
  states, error copy, accessibility. These rules decide where a file goes; they
  say nothing about whether the screen works.
- **The plan closes with proof**, not with the last step of the work:
  `fw evidence`, plus `fw mutate` on the files the criteria depend on.

## What fires with no phrase at all

Path-scoped rules load themselves the moment a matching file is touched. You
type nothing.

| Touching | Loads |
|---|---|
| any `.ts`, `.tsx`, `.html`, `.go` | `conventions` — no comments, named exports, no `any` |
| a `.spec.ts` / `.test.ts` | `testing` — announce the mode, name the seam, never a test that cannot fail |
| `src/app/**`, `*.component.ts`, `angular.json` | `angular` |
| a controller, module, resolver, `prisma/` | `backend` |
| auth, login, session, `*.guard.ts`, `middleware.ts` | `auth` — where a token may never live |
| a service, an interceptor, `api/`, `infrastructure/` | `api-client` — only `infrastructure/` imports the HTTP client |

## Skills name themselves

Rules load by path. Skills used to load only when someone remembered to open
them, and across a full logged session that happened **zero times out of four
while four skills were on topic**. A mandate obeyed none of the time is a
comment, not a mandate.

The prompt hook now reads every prompt, matches it against the `Trigger:` list
each installed skill declares, and names the matches with the path to read:

```
| Skill | Matched on | Read |
|---|---|---|
| testing | "test" | ~/.claude/skills/testing/SKILL.md |
| verification-standards | "evidencia" | ~/.claude/skills/verification-standards/SKILL.md |
```

It fires in Spanish and in English, tolerates accents and plurals, and stays
silent when nothing matches — an ordinary edit request injects nothing. It names
at most four, ranked by how many triggers each one matched, because an injection
that appears on every prompt is scenery.

Being named is not proof the skill applies. Open it and say in one line which
one you used and which you ruled out.

## The pass over the running app

The activity with the highest yield in three logged sessions, and the one the
framework named nowhere until now. `fw pass` builds the list from the diff —
which templates changed, which files have no test beside them, which routes or
guards moved who can reach what. You do not write that half.

```bash
fw pass                                     # where to look, from the diff
fw pass note "<what you saw>" --missed "<what should have caught it>"
fw pass log                                 # what today produced
```

The second field is the one that compounds. Leave it out when nothing should
have caught it: the entry then reads `nothing exists — framework gap`, which is
the finding rather than a missing field.

Written while looking, never reconstructed at the end of the day — what gets
remembered is what was startling, never what was frequent. Detail in
`foreign-systems.md`'s sibling, `manual-pass.md`.

## What still needs you to ask

**The backlog.** Its moment is *"I just got blocked"*. The router now catches the
phrasings that name it — *"qué sigo"*, *"what should I work on"* — but the moment
itself has no file path and no reliable phrase behind it, so `fw backlog` said
out loud is still the reliable route.

Record a blocked item with the date in any language — `(asked 2026-09-03)`,
`(preguntado 2026-09-03)`, or a bare `2026-09-03`. Without a date the wait
cannot be counted, and the wait is the point.

## Setting up a machine

Once per machine:

```bash
git clone <this repo> ~/ai-framework
~/ai-framework/bin/fw link
~/ai-framework/bin/fw doctor
```

Then once per project: `fw install`.

On **Windows**, run these from Git Bash. Two things to know:

1. Registering the hook needs `python3` or `python` on PATH. Check with
   `python3 --version || python --version`. Without one, `fw link` prints the
   stanza to add to `~/.claude/settings.json` by hand — it never pretends it
   worked.
2. The hook is registered as `hooks/plan-guard.cmd` at a `C:/...` path, because
   Claude Code runs hooks through the host shell. That launcher finds Git Bash
   the same way `bin/fw.cmd` does.

`fw doctor` is the check. Two green lines mean it is live:

```
✓ plan hook present: plan-guard.cmd
✓ plan hook registered in settings.json
```

## Proving it actually fires

From Git Bash:

```bash
printf '{"prompt":"elabora un plan para X"}' | ~/ai-framework/hooks/plan-guard.sh
```

From `cmd.exe`:

```
printf '{"prompt":"elabora un plan para X"}' > %TEMP%\p.json
C:\path\to\repo\hooks\plan-guard.cmd < %TEMP%\p.json
```

If the decision table prints, it is working. Silence from the `.cmd` means Git
Bash was not found.

## The honest limits

- The hook **pushes guidance; it does not force obedience.** If the agent ignores
  it, that is visible: it never names the row it is on. Ask it to.
- It matches the phrasing above, not every way to ask for a plan. Worded
  differently, you get no reminder.
- It fires in every project on the machine, including ones with no framework
  installed, where it will cite skills that do not apply there.
- Moving the clone breaks the registered path. `fw doctor` goes red and
  `fw link` repoints it.

## Running the framework's own tests

```bash
bash tests/mutate.test.sh
bash tests/backlog.test.sh
```

Both accept an override — `FW_MUTATE_BIN`, `FW_BACKLOG_BIN` — so they can be
pointed at a deliberately broken copy. That is how their green is earned: a
suite nobody has seen fail is not a suite.
