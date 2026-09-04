---
paths:
  - "**/*.service.ts"
  - "**/*interceptor*.ts"
  - "**/*.api.ts"
  - "**/api/**/*.ts"
  - "**/infrastructure/**/*.ts"
---

# API client rules

Loaded automatically when touching an HTTP boundary. Decision core only — the
client setup, interceptor order, pagination and the backend-doc verification
gate live in `../skills/api-client/SKILL.md`.

## Never negotiable

- One configured client instance per API. Never an ad-hoc `axios.get(...)`.
- **Only `infrastructure/` may import the HTTP client.** `application/` and
  `presentation/` never see an `AxiosError`, an `HttpErrorResponse`, or a raw
  response body.
- Credentials travel in `HttpOnly` cookies — `withCredentials: true`. Never build
  an `Authorization` header out of browser storage.
- Always set an explicit timeout. A request without one hangs forever.
- Never log headers, tokens, credentials, or personal data.
- Base URL comes from an environment variable. Never hardcode a host or an IP.
- Normalize every failure into a domain error before it leaves `infrastructure/`.
- No automatic retry on `POST`, `PATCH` or `DELETE` — they are not idempotent.

## Normalize before validating

Validating raw input rejects values a domain rule would have fixed, so the rule
never runs.

```ts
// WRONG — "  Walter@Example.com " is rejected before normalizeEmail can trim it
email: z.email()

// RIGHT — clean, then validate
email: z.string().transform(normalizeEmail).pipe(z.email())
```

## A backend document is a claim

It is not evidence until a run agrees with it. Verify before planning on it —
`../templates/contract-verification/`. A plan built on a drifted doc is rework
with extra steps.

## Reference

`../skills/api-client/SKILL.md` — client setup, interceptors, pagination, errors
