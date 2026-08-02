# ai-framework

A reusable baseline for building with Claude Code: the stack, the architecture,
and the conventions written down once, so they never have to be re-explained in
a prompt.

Point Claude Code at this repo — or copy `CLAUDE.md` and `skills/` into a
project — and it already knows how you work.

## Install

Done once per project, not per session. `FW` is wherever you cloned this repo.

```bash
export FW=~/path/to/ai-framework
```

### Every project

```bash
cd <project>
cp    $FW/CLAUDE.md   .
cp -r $FW/skills $FW/docs   .
```

### Then, by stack — one extra step

```bash
mkdir -p .claude/rules

cp $FW/rules/angular.md .claude/rules/     # Angular
cp $FW/rules/backend.md .claude/rules/     # NestJS / Prisma
                                           # React / Next.js: nothing
```

These declare `paths` in their frontmatter, so Claude Code loads them only when
the files being touched match. An Angular project never pays for the backend
rules, and a Next.js project never pays for either.

### Verify

Run `/context` in a session and look under **Memory files**:

- [ ] `CLAUDE.md` is listed
- [ ] `skills/` and `docs/` exist at the project root
- [ ] Angular: `.claude/rules/angular.md` appears after Claude reads a file in `src/app/`

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
4. In a shared repository use **`CLAUDE.local.md`** instead of `CLAUDE.md`, so
   your conventions are not imposed on teammates who never agreed to them. Add it
   to `.gitignore`.

Four things are worth fixing immediately, because they are cheap and isolated:
a committed host or IP, an env file required to build but gitignored, tests that
cannot fail, and a response used without validation.

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
| `skills/mentor/` | When teaching happens during the work, and what it must contain |
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
