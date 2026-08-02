---
name: api-client
description: "Trigger: HTTP call, Axios, fetch, interceptor, API integration, endpoint, backend docs, refresh token, request error. Apply this framework's API client rules."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "1.0"
---

## Activation Contract

Apply when creating or modifying: HTTP calls, client setup, interceptors,
request/response error handling, or any integration against a backend API.

## Hard Rules

- One configured client instance per API. Never call `axios.get(...)` ad hoc.
- **Only `infrastructure/` may import the HTTP client.** `application/` and
  `presentation/` never see an `AxiosError` or a raw response body.
- Credentials travel in `HttpOnly` cookies — set `withCredentials: true`. Never
  build an `Authorization` header from browser storage.
- Always set an explicit timeout. A request with no timeout hangs forever.
- Never log headers, tokens, credentials, or personal data.
- Base URL comes from an environment variable. Never hardcode a host or IP.
- Normalize every failure into a domain error type before leaving `infrastructure/`.
- No automatic retries on `POST`, `PATCH`, or `DELETE` — they are not idempotent.

## Decision Gates

| Situation | Client |
|---|---|
| Supabase project | Supabase SDK — do not wrap it in Axios |
| Server Component / Route Handler | Native `fetch` |
| Client-side REST API | Axios instance from `lib/api/` |
| Angular | `HttpClient` + functional interceptors |
| External API needing a secret | Route handler proxies it; never call from the browser |

**Refresh tokens are not the default.** With server-side sessions the server
handles renewal and the client needs no refresh logic. Session expiry is often a
deliberate product decision — do not add silent renewal unless it was requested.
If the project genuinely uses client-side JWT, implement refresh **single-flight**:
one refresh in progress, concurrent `401`s queue and await that one result.
Firing one refresh per failed request logs the user out.

## Execution Steps

1. Create the instance in `lib/api/` with `baseURL`, `timeout`, `withCredentials`.
2. Request interceptor: correlation id and content negotiation only — no tokens.
3. Response interceptor: map status to a domain error —
   `401` session expired, `403` forbidden, `404` not found, `422` validation,
   `5xx` server failure. Preserve the server's field-level validation messages.
4. **Verify the contract before writing code against it** (see below).
5. Parse every response with a Zod schema at the `infrastructure/` boundary.
6. Map the parsed payload to `domain/` types. Backend field names never leak
   past `infrastructure/`.

## Verifying backend documentation

Treat a backend `.md` as a **claim, not a contract**. It is written by a person
and drifts from the running code.

1. Read the doc to learn intent — endpoints, auth, expected fields.
2. Make one real call and inspect the actual response before implementing.
3. Where doc and reality disagree, **reality wins** for the implementation.
4. Write the Zod schema against the verified response, never against the doc.
5. Report the mismatch to the backend author. Do not silently work around it —
   an unreported mismatch breaks again the day they "fix" it.
6. Never infer pagination, nullability, or field types from prose. A documented
   paginated envelope that returns a bare array is a common failure.

A Zod parse at the boundary turns this class of bug into an immediate, precise
error instead of an `undefined` surfacing several layers away in the UI.

## Pagination

Backends return the same envelope across endpoints. Type it **once** as a
generic and let each feature supply its item schema. Never redeclare
`{ data, meta }` per feature.

- Build the envelope from the project's **actual** response, not from a `.md`
  and not copied from another project.
- Validate the items, never cast. `response as PaginatedResponse<T>` checks that
  `data` is an array and nothing inside it — the exact bug a parse would catch.
- **An unrecognized shape must throw.** Never normalize an unexpected payload
  into an empty page: a broken response rendered as "no results" looks like
  valid empty data and costs hours to trace.
- Tolerating a bare array where an envelope was documented is allowed only after
  verifying the real response — and it does not replace reporting the mismatch.

Two contracts, chosen by what the screen needs:

| Screen | Contract | Why |
|---|---|---|
| Table with a page selector | `page` / `limit` | Needs a total and page count |
| Infinite scroll, "load more" | cursor | Insertions do not shift the window |

A cursor is not a nicer `page`. It gives up the total and arbitrary page jumps
in exchange for stability: with `page`/`limit`, a row inserted mid-browse shifts
everything down and page 2 repeats an item from page 1.

See `templates/feature-template/infrastructure/pagination.ts`.

## Output Contract

Report: which client was used, where the instance lives, how errors map to domain
types, and any mismatch found between backend docs and actual responses.

## References

- `../../CLAUDE.md` — dependency rule and layer contracts
- `../auth/SKILL.md` — credential handling and session strategy
