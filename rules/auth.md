---
paths:
  - "**/auth/**"
  - "**/*auth*.ts"
  - "**/*login*.ts"
  - "**/*session*.ts"
  - "**/*.guard.ts"
  - "**/middleware.ts"
---

# Auth rules

Loaded automatically when touching authentication. Decision core only — the
method comparison, the flows and the gates live in
`../skills/auth/SKILL.md`. These are the ones that get broken from memory, and
each one is a real breach when it is.

## Never negotiable

- **Never store a token in `localStorage` or `sessionStorage`.** Both are
  readable by any script on the page, so one XSS takes the session. There is no
  "just for development" exception.
- Never store a token in a non-`HttpOnly` cookie, or in Redux, Context, a signal,
  or Zustand.
- Tokens live in cookies with `HttpOnly`, `Secure`, `SameSite=Lax`, `Path=/`.
- Never write custom crypto, password hashing, or token signing. Use the library.
- Never log, or put in an error message, any token, password, or session id.
- What the UI sees is a **user object or a boolean** — never the token itself.

## Ask first

The auth method is not a default. If the project has not defined one, **stop and
ask** before implementing. Session storage, refresh strategy, and where the
session is validated are the same: `../CLAUDE.md` §1.1 lists them by name.

## Reference

`../skills/auth/SKILL.md` — methods, flows, protected routes, logout
