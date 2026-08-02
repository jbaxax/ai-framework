---
name: auth
description: "Trigger: login, logout, signup, session, JWT, token storage, protected route, auth middleware. Apply this framework's authentication rules."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "1.0"
---

## Activation Contract

Apply when implementing or modifying: login, logout, signup, password reset,
session handling, token storage, protected routes, or auth middleware.

## Hard Rules

- **Never store tokens in `localStorage` or `sessionStorage`.** Both are readable
  by any script on the page — one XSS leaks the session. This is not negotiable
  and has no "just for development" exception.
- Never store tokens in a non-`HttpOnly` cookie, or in Redux/Context/Zustand.
- Tokens live in cookies with `HttpOnly`, `Secure`, `SameSite=Lax`, `Path=/`.
- Never build custom crypto, password hashing, or token signing. Use the library.
- Never log, or include in error messages, any token, password, or session ID.
- Auth state exposed to the UI is a **user object or a boolean**, never the token.
- Ask before choosing the auth method if the project has not defined one.

## Decision Gates

| Situation | Approach |
|---|---|
| Project already uses Supabase | Supabase Auth with the SSR cookie helpers |
| Next.js, self-managed auth | Auth.js (NextAuth) with the database session strategy |
| Existing backend owns auth | Server-set `HttpOnly` cookie; frontend never parses the token |
| Third-party API requires a bearer token | Server-side route handler proxies it; token never reaches the browser |
| Stateless JWT requested | Ask first — justify why revocation is not needed |

Prefer **server-side sessions** over stateless JWT. A JWT cannot be revoked
before expiry: a logout or a ban does not invalidate it. Choose stateless only
when horizontal scale demands it, and say so explicitly.

## Execution Steps

1. Confirm the auth method. If unspecified, stop and ask.
2. Place code by layer — never all in the component:
   - `domain/` — `User`, `Session`, `AuthError` types and pure rules
   - `application/` — `useLogin`, `useLogout`, `useSession` hooks
   - `infrastructure/` — provider/API calls, cookie handling
   - `presentation/` — forms and Zod schemas
3. Validate credentials with Zod at the boundary — **after** normalizing them.
   Trim and lowercase the email first, or a trailing space becomes a failed login.
4. Enforce route protection **on the server** (middleware, layout, or route
   handler). Client-side redirects are UX, never a security boundary.
5. On logout, clear the server session and invalidate the React Query cache.
6. Return generic auth errors to the UI ("Invalid email or password"). Never
   reveal whether the email exists.
7. Write unit tests for the pure rules in `domain/`.

## Output Contract

Report: auth method used, where the token lives, which layer holds each file,
and where route protection is enforced. Flag any rule above that could not be
satisfied — do not silently work around it.

## References

- `../../CLAUDE.md` — dependency rule and layer contracts
- `../api-client/SKILL.md` — attaching credentials and refresh handling
