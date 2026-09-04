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

## What still needs you to ask

**The backlog.** Its moment is *"I just got blocked"*, and no file path or prompt
pattern catches that. Say `fw backlog` or ask for the backlog skill by name. It
is the one piece that depends on discipline, and pretending otherwise would be
dishonest.

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
