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
