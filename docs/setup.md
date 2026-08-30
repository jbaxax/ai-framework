# Installing the framework in a project

One command per machine, one per project.

## Once per machine

```bash
~/ai-framework/bin/fw link
```

This does three things:

| What | Where | Why a symlink |
|---|---|---|
| Path-scoped rules | `~/.claude/rules/fw-*.md` | One copy. Improve it here, every project has it |
| Skills | `~/.claude/skills/*` | Same — and they load only when a task matches their trigger |
| Personal-file patterns | `~/.config/git/ignore` | Git reads this path by default; no `core.excludesFile` needed |

Rules and skills live in your **user scope**, so they are not inside any project.
There is nothing to copy per project, nothing to keep in sync, and nothing that
can appear in a commit.

The rules carry `paths` frontmatter, so `angular.md` loads only when Claude
touches `src/app/**` and `backend.md` only on controllers, modules, and
`prisma/`. A project on another stack never pays for them.

`fw link` is idempotent. Run it again after `git pull` in the framework; it
reports what was already in place.

## Once per project

```bash
cd <project>
fw install
```

It reads `package.json` for the stack (`next`, `react`, `@angular/core`,
`@nestjs/core`) and counts distinct commit authors to decide how to install.

### Your own repository

Writes `CLAUDE.md` and `docs/` at the root. Commit them — they are the project's
conventions and they belong in its history.

### A repository shared with a team

Writes `CLAUDE.local.md` and `.fw/docs/` instead. Claude Code loads
`CLAUDE.local.md` alongside the project's own `CLAUDE.md` and reads it **after**,
so your rules apply without replacing anything the team agreed on.

Both paths are in the global gitignore, so `git status` stays clean and no pull
request ever carries them. `.fw/` is the single namespaced directory for
everything the framework puts inside someone else's repository.

Override the detection with `--personal` or `--shared`. Preview with `--dry-run`.

### When it refuses

If a `CLAUDE.md` exists that this framework did not write, `fw install` aborts
and writes **nothing** — not even the docs. That file belongs to the project, and
a partial install is worse than none: it leaves your files in a repository whose
owners did not ask for them. The message points you at `--shared`, which is
almost always what you wanted.

## New projects

Scaffold first. The framework describes how to build, not how to create a repo,
and `fw install` refuses to run without a `package.json`.

```bash
bun create next-app@latest <name>          # Next.js
bunx @angular/cli@22 new <name>            # Angular
bunx @nestjs/cli new <name>                # NestJS
```

Angular needs three things its CLI does not generate. Do them before the first
feature:

```bash
bunx ng generate environments               # src/environments/ is not created
                                            # add "strict": true to tsconfig.json
                                            # add OnPush to every component
```

Then `fw install`, and start with the requirement — not the code. See
`workflow.md`.

## Existing projects

The framework applies to new code first. Read "Existing projects" in `CLAUDE.md`
before restructuring anything that already works.

## Verifying

```bash
fw doctor
```

Checks that every symlink resolves, that the global gitignore is configured, and
that nothing personal is visible to git in the current repository.

Run it inside a shared repository before you push. It catches the one failure a
gitignore cannot prevent: a personal file that was **already committed** before
the ignore existed. Git will not ignore a tracked file, and `git check-ignore`
will not even report it. The fix is one command:

```bash
git rm --cached CLAUDE.local.md
```

That drops it from the index and leaves it on disk.

To see what actually loaded in a session, run `/context` and read the list under
**Memory files**.

## Then what

Read `workflow.md` before the first feature. It covers where the framework sits
in the lifecycle and how to write the prompt that starts each phase — including
the case where the requirement arrives over chat instead of as a document.
