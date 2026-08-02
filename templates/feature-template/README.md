# Feature template — React / Next.js

Reference implementation of one feature following this framework's architecture.
Copy the folder, rename `invoice` to your feature, delete what you do not need.

These files are **reference only** — they are not part of a build. Import paths
like `@/lib/api/client` assume the host project provides them.

## Layout

```
domain/          pure business logic and types — imports nothing
application/     React Query hooks — orchestration
infrastructure/  HTTP calls and Zod parsing — the only layer that knows the API
presentation/    components and form schemas
```

## What each file demonstrates

| File | Rule it proves |
|---|---|
| `domain/types.ts` | Domain owns its vocabulary; the API's names never reach it |
| `domain/invoiceTotals.ts` | Pure logic — no React, no Axios, no Zod. Rounds per line so totals add up |
| `domain/invoiceTotals.test.ts` | What a good test looks like: edge cases first, no mocks |
| `infrastructure/invoiceSchemas.ts` | Parse at the boundary; map API fields to domain fields |
| `infrastructure/pagination.ts` | The envelope typed once as a generic, validated per item |
| `infrastructure/invoiceApi.ts` | The only file allowed to import the HTTP client |
| `application/useInvoices.ts` | Server state lives in React Query, never duplicated into a store |
| `application/useCreateInvoice.ts` | Invalidate on success instead of hand-patching the cache |
| `presentation/schemas/createInvoiceSchema.ts` | The form schema satisfies the domain type — never the reverse |
| `presentation/components/InvoiceList.tsx` | Presentation calls `application` and `domain`, never `infrastructure` |

## Decisions the code cannot state

The framework forbids comments, so the reasoning that a comment used to carry
lives here. These are the non-obvious choices in the files above.

**`tolerantPaginatedSchema` throws on an unrecognized shape.** It never
normalizes a broken response into an empty page. "No results" looks like valid
empty data and costs hours to trace; a thrown error names the field that changed.
It tolerates a bare array only because this endpoint is documented as paginated
and actually returns one — verified against a real call, and reported to the
backend author. Reaching for it is a signal to report the mismatch, not a reason
to stop reporting it.

**Each line is rounded before accumulating.** Summing raw products and rounding
once at the end produces an invoice whose printed lines do not add up to its
printed total. `Number.EPSILON` is in `roundToCents` because `0.1 + 0.2` is
`0.30000000000000004` and that cent reaches the customer.

**Cursor pagination is a different contract, not a nicer `page`.** With
`page`/`limit`, a row inserted while the user browses shifts everything down and
page 2 repeats an item from page 1. A cursor points at a concrete record, so
insertions do not move the window. The cost is real: no total, no jumping to an
arbitrary page. A screen that shows "page 7 of 30" needs `page`/`limit`.

**`next_cursor` is `nullish`, not `nullable`.** Some backends omit the field at
the end of a list, others send `null`. Both were observed; accepting both beats
guessing.

**`z.coerce` lives in the schemas.** This API sends numbers as strings. Coercing
at the boundary means no component ever does `Number(...)` on a payload.

**`toNewInvoice` is the seam between the form and the domain.** If the domain
gains a required field, this function stops compiling and the form is forced to
catch up. Without it the two shapes drift silently.

**`invoiceKeys` is a shared object** so mutations can invalidate queries without
re-typing a key that a typo would break.

## Dependency direction

```
presentation  →  application  →  domain
infrastructure                →  domain
```

`domain` imports nothing. If a change to the database, the API, or the UI forces
a change inside `domain`, a layer boundary was crossed somewhere.

## Scaling down

Not every feature needs four folders. If there is no business rule — nothing that
could be miscalculated — the layers buy nothing. A plain CRUD feature can be a
single folder with a few files. Promote to layers when real logic appears.

## Angular

The same feature in Angular lives in `../feature-template-angular/`.
`domain/invoiceTotals.ts` is valid in both without a single change.
