---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.html"
  - "**/*.go"
---

# Code conventions

Loaded automatically when editing source. Full detail in `docs/conventions.md`
and `../CLAUDE.md` §5. These are the ones that get broken from memory.

## Do not write comments

Not headers. Not `//` notes. Not JSDoc. Not a `<!-- -->` in a template. Not
"just this one, it explains something subtle".

If the code needs explaining, **rename it or extract a function until it does
not**. A comment is a bug report against the name.

```ts
const KNOWN_DEBT = ['tokenSire'];        // plus four lines of JSDoc
const TOLERATED_UNTIL_SIRE_MOVES_SERVER_SIDE = ['tokenSire'];
```

Same information, no comment. When the reason genuinely cannot live in a name,
it goes in the **test name**, the **commit message**, the feature's
**README.md**, or the backlog entry — never above the line.

The only exceptions are the ones a tool reads: `@ts-expect-error`,
`eslint-disable`, `'use client'`-style pragmas, license headers.

**Consistency within a project outranks this.** If the file you are editing is
already commented, match it and flag the mismatch rather than starting a
cleanup nobody asked for.

## The rest of the non-guessable set

| Rule | |
|---|---|
| Exports | Named. Default only where a framework demands it |
| Barrels | No `index.ts` per feature — hides dependency violations, breaks tree-shaking |
| Return types | Explicit on exported functions |
| `any` | Never. Use `unknown` and narrow |
| Server-only modules | `.server.ts` suffix |
| Language | Identifiers, UI copy and commits in English unless the project is already in another language |
| Commits | Conventional. No AI attribution, no co-author trailers |

## Before you finish

Ask the two questions that catch most of these:

1. Did I add a comment? Delete it and fix the name.
2. Did I write a reason somewhere the reader cannot act on it?
