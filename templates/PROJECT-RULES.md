# Project Rules

Rules that apply to this project and nowhere else. `fw install` appends this
file to `CLAUDE.md`, `AGENTS.md` and `GEMINI.md` every time it runs, and never
writes it — so what you put here survives a reinstall and a framework upgrade.

Delete the headings you do not need. An empty section is noise that competes
with the sections that say something.

## Vocabulary

Terms this codebase uses in a way an outsider would get wrong.

- `<term>` — <what it means here, and what it does not>

## Standing decisions

Decisions already made. Not up for rediscussion in every session; the reason is
what stops them being re-litigated.

- <decision> — because <reason>

## Deviations from the framework

Where this project knowingly does something the framework advises against, and
why. Without the why, the next reader "fixes" it.

| Framework says | Here we | Why |
|---|---|---|
| | | |

## Domain rules

Business rules that are not guessable from the code.

- <rule, with the edge case that makes it non-obvious>

## What not to touch

Code that looks wrong and is not, with the reason it stays.

- `<path>` — <why it is like that>
