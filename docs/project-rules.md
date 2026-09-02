# Project rules that survive a reinstall

`CLAUDE.md`, `AGENTS.md` and `GEMINI.md` in a project are **generated**. Every
`fw install` rebuilds them from the framework rules. Anything you type into them
is gone at the next run, and the run says `✓ CLAUDE.md` while it happens.

Project-specific rules go in `PROJECT-RULES.md` instead.

```
PROJECT-RULES.md     yours — fw only ever reads it
CLAUDE.md   ┐
AGENTS.md   ├─ generated = framework rules + PROJECT-RULES.md
GEMINI.md   ┘
```

Start from `templates/PROJECT-RULES.md`, or write your own — the format is
whatever the agents should read.

## Why a separate file rather than a smarter check

The generated files have two authors, and any scheme that lets both write one
file needs a rule for telling their content apart. `fw install` already had one:
it aborted if the target existed and did not carry the framework's header. It
did not help. A personalised `CLAUDE.md` still carries that header, so the check
passed and the copy went through.

A check that has to be right every time eventually is not. `PROJECT-RULES.md`
survives because no code path in `fw` writes it — the guarantee is structural,
not conditional.

## Where it lives

At the repository root, tracked. Rules about a project belong to whoever works
on it, so they are not in the global gitignore and are meant to be committed.

Personal notes that only apply to you are a different thing: those belong in
`~/.claude/CLAUDE.md`, which is global, and which `fw` never writes either.

## What still overwrites

`fw install` regenerates the three files unconditionally. If a project was
personalised in-place before `PROJECT-RULES.md` existed, move that content into
it **before** running `fw install` again — the run cannot recover what it
replaces.
