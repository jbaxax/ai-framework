# Stack defaults

Use these without asking. Deviating from any of them requires asking first —
that rule is in `CLAUDE.md` and is not negotiable.

This document records **why** each default was chosen, so the reasoning survives
the decision.

## Scope

The frontend section is always active. The backend section applies only to
full-stack personal projects — ignore it entirely when the work is frontend-only.

## Frontend

| Concern | Default | Why |
|---|---|---|
| Framework | Next.js, App Router | Primary stack |
| Language | TypeScript, `strict: true` | Non-negotiable; `any` defeats the purpose |
| Server state | TanStack Query | Owns fetching, caching, invalidation |
| Client state | React Context | Theme, modals, UI flags only |
| HTTP client | Axios, one shared instance | Interceptors and error normalization in one place |
| Validation | Zod | Same schema validates and produces the type |
| Forms | React Hook Form + Zod resolver | Uncontrolled by default, fewer re-renders |
| UI components | shadcn/ui + Tailwind | Copied into the repo, not a dependency |
| Testing | Vitest | Same runner as Angular v22 |
| Package manager | bun | Migration target for all projects |

### The UI library is a boundary, not a stack choice

Whatever the library, it lands in `components/ui/` and the dependency points one
way:

```
features/*/presentation/  →  components/ui/
```

`components/ui/` never imports from `features/`, never fetches, and never knows a
business rule. A `<Button>` does not know what an invoice is.

This is the same rule as every other layer, and it exists for the same reason:
when the library is abandoned or outgrown, one folder changes instead of the app.
A data table that knows what a `comprobante` is cannot be replaced.

**shadcn/ui is chosen partly because it is not a dependency.** Its components are
copied into the repo and become yours. Abandonment cannot break a build.

### Server state vs client state

The split that matters most:

| | Server state | Client state |
|---|---|---|
| Examples | invoices, products, the user | theme, open modal, active tab |
| Owner | React Query | Context |
| Truth lives | on the server | in the browser |

Never copy server data into Context or a store. Doing so recreates the manual
synchronization React Query already handles, and the copy goes stale.

**Zustand is not a default.** Reach for it only when genuinely complex client
state appears — multi-step wizards, cart-like local aggregates — and ask first.
For most screens, React Query plus a small Context is enough.

## Angular (secondary stack)

Used where a project already runs on it. Same architecture, different idioms.

| Concern | Default |
|---|---|
| Version | v22, standalone components |
| Services | `@Service()`, no `providedIn` |
| Injection | `inject()` in a field |
| State | Signals, exposed via `.asReadonly()` |
| Server state | `HttpClient` + RxJS — no React Query equivalent |
| HTTP | Functional interceptors |
| Testing | Vitest via `ng test` |
| UI components | PrimeNG + `@primeng/themes` |
| Base URL | `environment.apiUrl` |
| Dev proxy | `proxy.conf.json`, target read from an env var |

Never commit a host or IP in a tracked file, including `proxy.conf.json`. It
stays in git history after the file is fixed.

### Why PrimeNG and not a shadcn-style library

Angular has one: [spartan/ui](https://spartan.ng), same copy-paste model, ~60
components. It was evaluated and rejected as a **default** on stability grounds:

| | PrimeNG | spartan/ui |
|---|---|---|
| Backing | PrimeTek, a company | Community project |
| Support window | Two prior majors, plus a paid LTS | **Only the two latest Angular majors** |
| Breadth | Enterprise data tables, charts, trees | ~60 primitives |

That support window is the deciding fact: a project that does not upgrade Angular
roughly every twelve months falls out of support. For work codebases that is not
an acceptable default.

spartan/ui remains a reasonable **deliberate** choice for a personal project,
where the risk is the author's and the copy-paste model caps the damage. Choosing
it is a decision to state, not a default to assume.

If PrimeNG's look is the objection, configure `@primeng/themes` before replacing
anything. The current theming system is not the one older projects were built on,
and an unstyled default is not the same as an unstylable library.

## Backend (opt-in)

| Concern | Default |
|---|---|
| Framework | NestJS |
| ORM | Prisma |
| Database | PostgreSQL |
| Validation | Zod or `class-validator` at the controller boundary |

Layer mapping: controllers are `presentation`, orchestration services are
`application`, repositories and Prisma access are `infrastructure`, entities and
business rules are `domain`.

## Auth

| Situation | Approach |
|---|---|
| Project uses Supabase | Supabase Auth with SSR cookie helpers |
| Next.js, self-managed | Auth.js with database sessions |
| Existing backend owns auth | Server-set `HttpOnly` cookie |

Tokens never touch `localStorage`, `sessionStorage`, or any client store.
Server-side sessions are preferred over stateless JWT: a JWT cannot be revoked
before it expires, so a logout or a ban does not invalidate it.

**Refresh tokens are not a default.** Session expiry is often a deliberate
product decision — do not add silent renewal unless it was requested.

## What still requires asking

Defaults answer the common cases. These are always project decisions:

- Auth method, when not covered above
- Session lifetime and expiry behavior
- Any new runtime dependency
- Data model and schema shape
- Retry and error-handling policy for a new integration
- Anything changing an existing module's public contract

## Legacy exceptions

Older projects may still use `pnpm` or `npm`. Do not migrate a package manager
as a side effect of another task — propose it as its own change.

## Next

- `docs/clean-architecture.md` — how features are structured
- `skills/` — rules for auth, API clients, and testing
