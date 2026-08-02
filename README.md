# my-ai-framework

A reusable baseline for building with Claude Code: the stack, the architecture,
and the conventions written down once, so they never have to be re-explained in
a prompt.

Point Claude Code at this repo — or copy `CLAUDE.md` and `skills/` into a
project — and it already knows how you work.

## Quick path

Same three files for every project:

```bash
cp CLAUDE.md          <project>/
cp -r skills docs     <project>/
```

**Angular projects only** — one extra step, done once:

```bash
mkdir -p <project>/.claude/rules
cp rules/angular.md   <project>/.claude/rules/
```

That file declares `paths` in its frontmatter, so Claude Code loads it
automatically when working with Angular files and never loads it anywhere else.
Nothing to remember per session.

Then ask for a feature. Claude follows the rules instead of guessing.

## What is in here

| Path | Purpose |
|---|---|
| `CLAUDE.md` | The rules Claude reads. Loaded every session |
| `rules/angular.md` | Path-scoped rule — copy to `.claude/rules/` in Angular projects |
| `rules/backend.md` | Path-scoped rule — NestJS/Prisma, full-stack projects only |
| `docs/setup.md` | How to install the framework in a project |
| `docs/workflow.md` | Where this sits in the lifecycle, and how to write the prompt |
| `docs/clean-architecture.md` | How the layers work, and where each file goes |
| `docs/conventions.md` | Naming and code rules for both stacks |
| `docs/stack-defaults.md` | The stack, and why each default was chosen |
| `skills/requirements/` | Turning a chat message or user story into testable criteria |
| `skills/auth/` | Sessions, cookies, token storage, what never to do |
| `skills/api-client/` | HTTP clients, interceptors, pagination, verifying backend docs |
| `skills/testing/` | Vitest, what to test first, what not to test |
| `templates/feature-template/` | A complete React feature, as reference |
| `templates/feature-template-angular/` | The same feature in Angular v22 |

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

**Tests are written on request.** Never added unprompted. Untested pure logic is
declared in one line at the end, so the decision stays visible.

## Stack

Frontend-first. The backend section only applies to full-stack personal projects.

- **React** — Next.js App Router, TanStack Query, Axios, Zod, React Hook Form
- **Angular** — v22 standalone, `@Service()` + `inject()`, signals, `HttpClient`
- **Backend (opt-in)** — NestJS, Prisma, PostgreSQL
- **Tooling** — TypeScript strict, Vitest, bun

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
