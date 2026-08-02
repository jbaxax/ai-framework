# Framework validation — findings

Built a basic email + password login against the framework rules, then recorded
where the rules held, where they were ambiguous, and where they were wrong.

## Verified

Not claimed — executed.

```
bun run typecheck   → clean
bun run build       → compiled, 8 routes, proxy registered
```

| Behavior | Result |
|---|---|
| Login, valid credentials | `200`, session cookie set |
| Cookie attributes | `Path=/; Secure; HttpOnly; SameSite=lax` |
| Login, wrong password | `401`, generic message |
| Login, malformed email | `422` |
| `/api/auth/me` without cookie | `401` |
| `/api/auth/me` with cookie | `200`, user payload |
| 6 failed attempts | attempts 1–5 `401`, attempt 6 `429` |
| Email with spaces and capitals | `200` after fix, `422` before |

## Bug the framework did not prevent

**Validation ran before normalization, so a domain rule never executed.**

```ts
// BEFORE — "  WALTER@Example.com " rejected as malformed
const requestSchema = z.object({ email: z.email(), ... });
const email = normalizeEmail(parsed.data.email);   // too late
```

`normalizeEmail` existed in `domain/`, was correct, and was called. It still had
no effect: `z.email()` rejected the raw input first, so a user who trailed a
space could not log in. Confirmed with a real request returning `422`.

```ts
// AFTER — clean, then validate
email: z.string().transform(normalizeEmail).pipe(z.email())
```

The framework says *where* validation and business rules live. It never said
**in what order they run at the boundary**. That gap is now a rule in
`skills/api-client/SKILL.md`.

## Ambiguities found

### 1. "Ask before assuming" cannot be satisfied unattended

Rule 1.1 requires asking when the auth method is unspecified. The task was given
with no method and no opportunity to ask.

Resolved by falling back to the `skills/auth` decision gates — but the rule does
not say a decision gate counts as an answer. It now does.

### 2. Axios is the wrong default for same-origin route handlers

Rule: "HTTP client — Axios, via a shared configured instance."

For a Next.js app calling its own `/api` routes, `fetch` is already there and
needs no dependency. Axios was used to follow the rule; the interceptor for
error normalization did earn its place, but the dependency is hard to justify
on a same-origin call.

The decision gate now distinguishes same-origin route handlers from external APIs.

### 3. Where does a route handler live?

`app/` is documented as "routing only — no business logic". A login route
handler orchestrates: validate, check lockout, verify password, issue session.
That is `application` work sitting in `app/`.

It reads as a violation but is not — Next.js requires the file to be there.
Now stated explicitly, with the rule that route handlers delegate and never
hold rules of their own.

### 4. `.server.ts` suffix was never defined

Two files needed it (`userStore.server.ts`, `session.server.ts`) to keep
server-only code out of the client bundle. The convention table had no entry.
`self` already uses it (`authService.server.ts`). Now documented.

## Rules that held up

- **Dependency direction**: no violation. `domain/session.ts` imports only its
  own types — no React, no cookies, no crypto.
- **Time injected, never read**: every domain function takes `now: number`.
  Made the lockout rule verifiable without waiting 15 minutes.
- **Layer split forced a better design**: the lockout rule sits in `domain/`,
  so it applies to any caller. Written inside the component it would have been
  bypassable by any other client.
- **Generic error messages**: same status and body whether the email exists or
  the password was wrong — no account enumeration.
- **`HttpOnly` cookie**: no token is reachable from JavaScript, so the "never
  use localStorage" rule had nothing to tempt it.

## Not covered by this test

- Registration, password reset, email verification
- Refresh tokens (deliberately — not a framework default)
- The Angular path — `rules/angular.md` was never exercised
- Pagination — no list endpoint exists here

## Reproduce

```bash
bun install
bun run build
PORT=3999 bun run start

curl -i -X POST localhost:3999/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"walter@example.com","password":"correct-horse-battery"}'
```

Users live in memory and reset on restart. Swapping
`infrastructure/userStore.server.ts` for Prisma changes nothing else — which was
the point of the layering.
