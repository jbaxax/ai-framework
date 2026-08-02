# How the layers are distributed

Every feature is split into four layers so that business logic stays free of
React, Angular, HTTP, and the database. The payoff is concrete: the part that
can be *wrong* becomes cheap to verify, and swapping a framework or a backend
stops being a rewrite.

`CLAUDE.md` states the rules for the agent. This document explains why they
exist and where things go.

## The one rule

Dependencies point **inward**. An inner layer never imports from an outer one.

```
presentation  ──▶  application  ──▶  domain
infrastructure ─────────────────▶  domain
```

| Layer | Knows about | Never imports |
|---|---|---|
| `domain` | nothing | everything else |
| `application` | domain | presentation, infrastructure internals |
| `infrastructure` | domain | application, presentation |
| `presentation` | application, domain | infrastructure |

`domain` importing nothing is the load-bearing part. If a change to the
database, the API, or the UI forces an edit inside `domain`, a boundary leaked.

## Where does X go?

| You are writing… | It goes in |
|---|---|
| A tax, discount, or total calculation | `domain` |
| "Only an issued invoice can be voided" | `domain` |
| A type describing a business concept | `domain` |
| A React Query hook / an Angular store | `application` |
| Cache invalidation after a mutation | `application` |
| An HTTP call | `infrastructure` |
| A Zod schema for an API response | `infrastructure` |
| Renaming `cliente_id` to `customerId` | `infrastructure` |
| A component or template | `presentation` |
| A Zod schema for a **form** | `presentation` |
| Converting form values to a domain input | `presentation` |

Two schema kinds, two homes. The API schema describes what the server sends.
The form schema describes what the user may type. They are not the same shape
and they change for different reasons.

## The two directions

Data crosses a boundary twice, and each crossing has a translator.

**Reading** — server to screen:

```
API  →  zod.parse()  →  toDomainInvoice()  →  domain  →  component
        validates          renames fields
        at runtime         cliente_id → customerId
```

**Writing** — user to server:

```
form  →  toNewInvoice()  →  domain  →  toApiPayload()  →  API
         checked by tsc              renames fields
         at compile time             customerId → cliente_id
```

The two protections answer different threats:

| | `zod.parse()` | `toNewInvoice()` |
|---|---|---|
| Protects against | the backend changing | your own domain drifting |
| Fails | at runtime, on real data | at compile time |
| Delete it and | `undefined` reaches the UI | a field silently never gets sent |

## Two shapes, one architecture

The layers are the same in both stacks. Only how they are expressed differs.

**React / Next.js — folders:**

```
features/invoice/
├── domain/          types.ts · invoiceTotals.ts
├── application/     useInvoices.ts
├── infrastructure/  invoiceApi.ts · invoiceSchemas.ts
└── presentation/    components/ · schemas/
```

**Angular — flat, layer carried by the file name:**

```
features/invoice/
├── invoice.model.ts     domain
├── invoice-totals.ts    domain
├── invoice-api.ts       infrastructure
├── invoice-store.ts     application
└── invoice-list/        presentation
```

Angular's [style guide](https://angular.dev/style-guide) asks for flat feature
directories and explicitly warns against `components/` or `services/` folders.
That costs nothing here, because **the dependency rule lives in the imports, not
in the directory names**. Folders are navigation aids for humans.

Proof: `domain/invoiceTotals.ts` and `invoice-totals.ts` have identical bodies.
Pure logic belongs to no framework.

## When not to use four layers

A feature with no business rule gains nothing from them. If nothing can be
*miscalculated*, `domain` would hold a types file and little else — and you pay
four folders of navigation for it.

| The feature… | Shape |
|---|---|
| Lists, creates, edits, deletes. No rules | Flat. A few files in one folder |
| Calculates, validates, or restricts by state | Full layers |

Start flat and promote when real logic appears. A CRUD screen that later gains
"the base unit cannot be deleted while conversions exist" has just grown a
`domain`. That is normal, not a failure.

The same promotion rule governs `shared/` and `lib/`: nothing is extracted in
anticipation, only when a second real consumer exists.

## Checklist

Before calling a feature done:

- [ ] `domain` imports no framework, no library, no I/O
- [ ] `application` does not import from `presentation`
- [ ] `presentation` does not import from `infrastructure`
- [ ] API field names do not appear outside `infrastructure`
- [ ] Server state lives in React Query or a store — never duplicated in both
- [ ] Every API response is parsed before use

## Next

- `docs/conventions.md` — naming and code rules
- `templates/feature-template/` — the reference implementation
