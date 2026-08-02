# Installing the framework in a project

Two commands for any project, plus one extra for Angular. Done once per project,
not per session.

## Every project

```bash
cp   <framework>/CLAUDE.md      .
cp -r <framework>/skills docs   .
```

| File | Loads |
|---|---|
| `CLAUDE.md` | every session, automatically |
| `skills/*` | only when the task matches |
| `docs/*` | only when Claude reads them |

Only `CLAUDE.md` costs context on every session. Everything else is free until
it is needed.

## Angular projects — one extra step

```bash
mkdir -p .claude/rules
cp <framework>/rules/angular.md .claude/rules/
```

`rules/angular.md` declares `paths` in its frontmatter, so Claude Code loads it
automatically whenever it touches `src/app/**` — and never in a project without
those files.

Without this step the Angular rules still work, but only because `CLAUDE.md`
tells Claude to read `docs/angular.md`. That is instruction-following, not a
guarantee. The rules file makes it a mechanism.

**Verify it loaded**: run `/context` in a session and look under **Memory files**.

## React / Next.js projects

Nothing extra. `rules/angular.md` is not copied, and even if it were, its
`paths` would never match.

## Full-stack personal projects

```bash
mkdir -p .claude/rules
cp <framework>/rules/backend.md .claude/rules/
```

Same mechanism: `paths` matches controllers, modules, and `prisma/`, so the
NestJS rules load only when the work is actually backend. A frontend-only
project never pays for them.

## Existing projects

The framework applies to new code first. See "Existing projects" in `CLAUDE.md`
before restructuring anything that already works.

## Verifying the install

- [ ] `/context` lists `CLAUDE.md` under Memory files
- [ ] `skills/` and `docs/` exist at the project root
- [ ] Angular only: `.claude/rules/angular.md` exists
- [ ] Angular only: `/context` shows the rule after Claude reads a file in `src/app/`
- [ ] Full-stack only: `.claude/rules/backend.md` exists

## Then what

Read `workflow.md` before the first feature. It covers where the framework sits
in the lifecycle and how to write the prompt that starts each phase — including
the case where the requirement arrives over chat instead of as a document.
