# Framework Rules

Reusable baseline for projects built with Claude Code: the architecture, the
stack, and the conventions, so they are never re-explained per prompt.

Detail lives in `docs/`. Task rules live in `skills/`. Working reference code
lives in `templates/`. This file holds only what must be true in every session.

---

## 1. Non-negotiable rules

### 1.1 Ask before assuming

If a relevant technical decision is unspecified, **stop and ask**. Do not pick
one and implement it.

Always requires asking: authentication method, session storage, state management
beyond section 2, any new runtime dependency, data model shape, retry policy for
a new integration, and anything that changes an existing module's public contract.

Ask **one** question at a time and wait. A default in this file is an answer. A
decision gate in `skills/` is an answer too — follow it and say which row applied.
Silence on something covered nowhere is not permission.

When asking is impossible, state the assumption and its blast radius in the final
report. Never bury it.

### 1.2 The dependency rule

Layers depend **inward only**.

```
presentation  →  application  →  domain
infrastructure  →  domain
```

| Layer | May import from | Must never import from |
|---|---|---|
| `domain` | only other `domain` files | everything else, including any library or framework |
| `application` | domain | presentation, framework routing/UI |
| `infrastructure` | domain | application, presentation |
| `presentation` | application, domain | infrastructure |

Verifiable, not aspirational — check the imports in each layer before finishing.
Check **import statements**, not text: a search for `HttpClient` also matches the
comment that says a file must never import it.

**Forbidden patterns.** Both are real violations found in previous projects:

```ts
// FORBIDDEN — application importing a Zod schema type from presentation
import { UpdateUserInput } from "../presentation/schemas/profileSchema"
```
Input types belong to `domain`. Presentation builds its schema *from* the domain
type, never the reverse.

```ts
// FORBIDDEN — database types leaking into domain
import { Tables, Enums } from "@/lib/supabase/types"
```
`domain` declares its own types; `infrastructure` maps rows at the boundary. If
the database vendor changes, `domain` must not.

### 1.3 Domain stays pure

Business logic as plain functions and types. No React, no HTTP client, no ORM,
no I/O. Inject time as a parameter (`now: number`) instead of reading the clock —
it is what makes rules like lockouts verifiable without waiting.

Logic that is expensive to test does not get tested. A pure `domain` keeps the
option cheap and always available.

**Tests are written on request only** — see `skills/testing/`. When pure logic
ships untested, say so in one line so the decision stays visible.

### 1.4 Normalize before validating

Validating raw input rejects values a domain rule would have fixed, so the rule
never runs.

```ts
// WRONG — "  Walter@Example.com " is rejected before normalizeEmail can trim it
email: z.email()
// RIGHT
email: z.string().transform(normalizeEmail).pipe(z.email())
```

---

## 2. Stack defaults

Use without asking. Deviating requires asking first.

| Concern | Default |
|---|---|
| Framework | Next.js, App Router |
| Language | TypeScript, `strict: true` |
| Server state | TanStack Query |
| Client/UI state | React Context — theme, modals, UI flags only |
| HTTP client | `fetch` same-origin; Axios instance for external APIs (`skills/api-client`) |
| Validation | Zod |
| Forms | React Hook Form + Zod resolver |
| Testing | Vitest (`skills/testing`) |
| Package manager | bun — do not migrate a legacy `pnpm`/`npm` project as a side effect |

**Server state never lives in Context or a global store.** React Query owns
fetching, caching, and invalidation; duplicating it reintroduces manual sync.

Zustand is **not** a default. Only for genuinely complex client state, after asking.

**Angular projects: read `docs/angular.md` before writing code.** It replaces the
React idioms above. If `.claude/rules/angular.md` is missing from the project,
tell the user to run this once, then continue:

```bash
mkdir -p .claude/rules && cp <framework>/rules/angular.md .claude/rules/
```

Full-stack personal projects: `rules/backend.md` (NestJS, Prisma, PostgreSQL).

---

## 3. Requirements come before code

When the request arrives as prose — a user story, a chat message, a bug report,
a backend `.md` — **restate it as acceptance criteria before implementing.** See
`skills/requirements/` for the shape and `docs/workflow.md` for the prompts.

Implementing prose means inventing the unstated parts silently. Restating makes
each gap visible as a question, which is cheap to answer and expensive to guess.

---

## 4. Architecture

### 4.1 Feature-colocated, not layer-first

A feature is **one folder** holding its own layers. Never split a feature across
top-level `components/`, `hooks/`, and `services/`.

```
features/diet/
├── domain/           types.ts, calories.ts — pure, colocated tests
├── application/      useMealEntries.ts — React Query hooks, orchestration
├── infrastructure/   dietService.ts — HTTP/DB, maps to domain types
└── presentation/     components/, schemas/
```

Everything needed to change one behavior lives in one place. Layer-first layouts
force jumping across four root folders for a single feature and accumulate
orphaned files that fit no layer.

### 4.2 Module grouping (only past ~15 features)

Group by business module (`features/gerencia/roles/`). The grouping level adds
**only** a folder — never shared `components/` or `hooks/` at the module level,
which is layer-first through the back door.

### 4.3 Outside `features/`

| Path | Contents | Rule |
|---|---|---|
| `app/` | Routing, route handlers | Handlers orchestrate by calling `domain` and `infrastructure`. They hold no rules of their own |
| `components/ui/` | Design-system primitives | No business logic, no fetching |
| `components/shared/` | Cross-feature UI | Used by 2+ features. Used by one? It belongs to that feature |
| `lib/` | Framework-agnostic utilities, client setup | Pure and testable |
| `hooks/` | Generic hooks (`useDebounce`) | Feature-specific hooks go in that feature's `application/` |

**Promotion rule**: code starts inside its feature and moves out only when a
second consumer actually exists — never in anticipation.

### 4.4 Existing projects

This framework describes the target, not a mandate to rewrite.

- New code follows it fully.
- **Never restructure existing code as a side effect of another task** — the diff
  is unreviewable and conflicts with everyone else's branch.
- When editing existing code, match the surrounding style and flag the mismatch
  once. Do not introduce a third convention.
- Propose migrations as their own change, one module at a time.

Fix-now exceptions — cheap, isolated, independently valuable:

| Finding | Why it does not wait |
|---|---|
| A committed host, IP, or secret | Stays in git history after the fix |
| An env file required to build but gitignored | A fresh clone cannot run |
| Tests that cannot fail (`should create`) | Slow the suite, protect nothing |
| A response used without validation | The next backend change reaches the UI |

---

## 5. Conventions

Full tables in `docs/conventions.md`. The rules that are not guessable:

- Named exports. Default exports only where the framework requires them.
- No barrel `index.ts` per feature — hides dependency violations, breaks tree-shaking.
- Explicit return types on exported functions.
- No `any`. Use `unknown` and narrow.
- Server-only modules take a `.server.ts` suffix.
- **Do not write comments.** Not headers, not `//` notes, not JSDoc. If code
  needs explaining, rename it or extract a function until it does not.
  The only exceptions are the ones a tool reads: `@ts-expect-error`, `eslint-disable`,
  `'use client'`-style pragmas, and license headers.
- A reason the code genuinely cannot express — why a request throws instead of
  falling back, why a rate is what it is — goes in the feature's `README.md` or
  the commit message, not above the line.
- Identifiers, comments, UI copy, and commits in English unless the project is
  already in another language. API payloads keep the backend's vocabulary inside
  `infrastructure/`, where the mapping happens.
- Conventional commits. No AI attribution, no co-author trailers.

Consistency **within a project** outranks this document. When extending existing
code, match what is there and flag the mismatch.

---

## 6. Definition of done

- [ ] Imports in every layer match §1.2 — no inward violations
- [ ] `domain` has no framework, library, or I/O imports
- [ ] No server state duplicated into Context or a store
- [ ] No new dependency added without asking
- [ ] Types check and lint pass
- [ ] Each acceptance criterion mapped to where it lives
- [ ] Untested pure logic declared in one line — tests only if requested

Report failures with the actual output. Never describe unverified work as done.
