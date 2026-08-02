---
paths:
  - "**/*.controller.ts"
  - "**/*.module.ts"
  - "**/*.resolver.ts"
  - "prisma/**"
  - "src/main.ts"
  - "nest-cli.json"
---

# Backend rules — NestJS

Applies to personal full-stack projects. Frontend-only work never loads this.

| Concern | Default |
|---|---|
| Framework | NestJS |
| ORM | Prisma |
| Database | PostgreSQL |
| Validation | Zod or `class-validator`, at the controller boundary |
| Testing | Vitest or Jest, matching the project |

## Layer mapping

A NestJS module is a feature. Inside it, the same dependency rule as the
frontend applies — inward only.

| NestJS concept | Layer | Constraint |
|---|---|---|
| Controller | presentation | Parses input, returns DTOs. No business rules |
| Service that orchestrates | application | Calls domain rules and repositories |
| Repository, Prisma client | infrastructure | The only place `PrismaService` is injected |
| Entity, business rule | domain | Pure. No Prisma, no Nest decorators, no I/O |

A Prisma model is **not** a domain entity. It is a database row. Map it at the
repository boundary, the same way a Zod schema maps an API payload on the
frontend. If the ORM changes, `domain` must not change.

## Rules

- Validate at the controller boundary. A service must never receive unvalidated
  input and must never re-validate what the controller already checked.
- **Normalize before validating format** — the same failure as the frontend:
  validating first rejects values a domain rule would have fixed, so the rule
  never runs.
- Never return a Prisma model directly from a controller. It leaks columns,
  including the ones you forgot were there.
- Errors carry a domain type, not an HTTP status. The exception filter maps
  domain error → status in one place.
- Migrations are reviewed like code. `prisma db push` is for a scratch database
  and nothing else.
- Never log request bodies on auth routes.

## Contract with the frontend

When both sides live in the same project, the response shape is decided **once**
and written down before either side is built. Guessing on either side produces
the exact mismatch that `skills/api-client/` exists to catch.

Pagination envelopes stay identical across every endpoint. One shape, one
generic type on the client.
