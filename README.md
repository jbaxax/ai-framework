# ai-framework

A reusable baseline for building with Claude Code: the stack, the architecture,
and the conventions written down once, so they never have to be re-explained in
a prompt.

Point Claude Code at this repo — or copy `CLAUDE.md` and `skills/` into a
project — and it already knows how you work.

## Install

### Once per machine

```bash
git clone git@github.com:jbaxax/ai-framework.git ~/ai-framework
~/ai-framework/bin/fw link
```

`fw link` symlinks the rules and skills into `~/.claude/`, and adds the personal
files to your global gitignore. Symlinks, not copies: improve a rule here and
every project has it immediately, with no reinstall.

If OpenCode is installed it receives the same skills, symlinked from the same
source. Standards belong wherever code is written — an agent executing without
them produces work that looks finished and meets nothing. `fw doctor` reports
each agent separately and exits non-zero when one of them is missing skills.

Because rules and skills live in your user scope, they are never inside a project
and can never appear in a commit.

### Once per project

```bash
cd <project>
fw install
```

It reads `package.json` to detect the stack, and decides how to install by
counting the distinct commit authors:

| Repository | Detected as | Installs |
|---|---|---|
| Yours alone | personal | `CLAUDE.md` + `docs/`, committed normally |
| Shared with a team | shared | `CLAUDE.local.md` + `.fw/docs/`, invisible to git |

Force either with `--personal` or `--shared`. Use `--dry-run` to see the plan
without writing.

If a `CLAUDE.md` already exists that this framework did not write, `fw install`
**aborts without writing anything** — that file belongs to the project, and a
half install leaves your files in someone else's repository.

### Verify

```bash
fw doctor
```

It confirms the symlinks resolve, the global gitignore is in place, and nothing
personal is visible to git. Run it inside a shared repository before you push;
it also catches the one case a gitignore cannot fix — a personal file that was
already committed, which it tells you to untrack with `git rm --cached`.

For what actually loaded in a session, run `/context` and read under
**Memory files**.

### New project

Scaffold first, install the framework second — the rules describe how to build,
not how to create a repo.

```bash
bun create next-app@latest <name>          # Next.js
bunx @angular/cli@22 new <name>            # Angular
bunx @nestjs/cli new <name>                # NestJS
```

Angular needs three things the CLI does not generate. Do them before the first
feature:

```bash
bunx ng generate environments               # src/environments/ is not created
                                            # add "strict": true to tsconfig.json
                                            # add OnPush to every component
```

Then install the framework as above, and start with the requirement — not the
code. See `docs/workflow.md`.

### Existing project

The framework describes the target, not a mandate to rewrite. Install it the same
way, then:

1. **Apply it to new code only.** The next feature follows it fully.
2. **Do not restructure what works** as a side effect of another task. Moving
   folders produces diffs nobody can review and conflicts for everyone else.
3. **Propose migrations one module at a time**, never silently.
4. In a shared repository your conventions stay yours. `fw install` detects this
   and writes `CLAUDE.local.md` plus `.fw/docs/`, both covered by the global
   gitignore — nothing is imposed on teammates who never agreed to it, and
   nothing reaches a pull request.

Four things are worth fixing immediately, because they are cheap and isolated:
a committed host or IP, an env file required to build but gitignored, tests that
cannot fail, and a response used without validation.

Then ask for a feature. Claude follows the rules instead of guessing.

## What is in here

| Path | Purpose |
|---|---|
| `bin/fw` | Installer and verifier — `link`, `install`, `doctor`, `evidence`, `backlog` |
| `machine/` | The two config files that define this setup, and why `CLAUDE.md` is not one of them |
| `CLAUDE.md` | The rules Claude reads. Loaded every session |
| `rules/angular.md` | Path-scoped rule — copy to `.claude/rules/` in Angular projects |
| `rules/backend.md` | Path-scoped rule — NestJS/Prisma, full-stack projects only |
| `docs/setup.md` | How to install the framework in a project |
| `docs/workflow.md` | Where this sits in the lifecycle, and how to write the prompt |
| `docs/clean-architecture.md` | How the layers work, and where each file goes |
| `docs/conventions.md` | Naming and code rules for both stacks |
| `docs/stack-defaults.md` | The stack, and why each default was chosen |
| `skills/requirements/` | Turning a chat message or user story into testable criteria |
| `skills/epic/` | The boundary and standing decisions that span several slices |
| `skills/backlog/` | What can be started now, and the Definition of Ready that decides it |
| `skills/verification-standards/` | What counts as proof that a change is done |
| `skills/mentor/` | When teaching happens during the work, and what it must contain |
| `skills/auth/` | Sessions, cookies, token storage, what never to do |
| `skills/api-client/` | HTTP clients, interceptors, pagination, verifying backend docs |
| `skills/testing/` | Vitest, what to test first, what not to test |
| `templates/feature-template/` | A complete React feature, as reference |
| `templates/feature-template-angular/` | The same feature in Angular v22 |
| `templates/contract-verification/` | Executable check that a backend you do not own still matches its documentation |

`CLAUDE.md` is written for the agent. `docs/` is written for you — it explains
the reasoning that the rules compress.

## The four rules everything rests on

**Requirements before code.** A request that arrives as prose — a chat message,
a user story, a bug report — gets restated as acceptance criteria first.
Implementing prose means inventing the unstated parts silently.

**Ask before assuming.** If a relevant technical decision is not specified —
auth method, state management, a new dependency — Claude asks instead of
picking one.

**Dependencies point inward.** `domain` imports nothing. Business logic stays
free of React, Angular, HTTP, and the database, which is what makes it cheap to
verify and safe to keep.

**Testing is decided by context, and proven by the cheapest evidence that can
prove it.** An acceptance criterion is a test request; a bug fix always starts
with a failing test; ad-hoc work gets none unless asked. Once a criterion must be
proven, the question is not "is there a test" but which evidence could actually
catch its failure — a unit test for a calculation, a contract run for a backend
shape, a browser for what only a browser can see. `skills/testing/` holds both
gates, and `fw evidence` produces the proof so it is executed rather than
claimed.

## Stack

Frontend-first. The backend section only applies to full-stack personal projects.

- **React** — Next.js App Router, TanStack Query, Zod, React Hook Form, shadcn/ui
- **Angular** — v22 standalone, `@Service()` + `inject()`, signals, `HttpClient`, PrimeNG
- **Backend (opt-in)** — NestJS, Prisma, PostgreSQL
- **Tooling** — TypeScript strict, Vitest, bun

Whatever the UI library, it stays behind a boundary: features import it, it never
imports features, and it never learns a business rule. When it is outgrown, one
folder changes instead of the app.

Full rationale in `docs/stack-defaults.md`.

## Two shapes, one architecture

The same feature, both stacks — folders in React, flat files in Angular, because
[Angular's style guide](https://angular.dev/style-guide) asks for flat feature
directories.

It costs nothing: the dependency rule lives in the imports, not in the folder
names. `domain/invoiceTotals.ts` and `invoice-totals.ts` have identical bodies.

## Next

Start with `docs/clean-architecture.md`, then read
`templates/feature-template/` end to end. The template is the fastest way to see
every rule applied at once.
