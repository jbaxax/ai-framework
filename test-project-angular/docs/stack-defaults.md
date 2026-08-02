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
| Testing | Vitest | Same runner as Angular v22 |
| Package manager | bun | Migration target for all projects |

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
| Base URL | `environment.apiUrl` |
| Dev proxy | `proxy.conf.json`, target read from an env var |

Never commit a host or IP in a tracked file, including `proxy.conf.json`. It
stays in git history after the file is fixed.

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
