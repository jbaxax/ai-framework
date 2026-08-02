# Angular validation — findings

Built a paginated invoice list against the framework rules on a fresh
Angular CLI 22.1.2 scaffold, with a stub backend speaking the real thing:
Spanish, `snake_case`, `{ data, meta }`.

## Verified

Executed, not claimed.

```
ng build            → clean, with "strict": true added
ng test             → 17 tests, 2 files, all passing
bun verify-contract → parsed a live HTTP response into domain types
ng serve + proxy    → 200 through proxy.conf.json to the stub
```

| Behavior | Result |
|---|---|
| Build with `strict: true` | Clean |
| Domain unit tests (totals, rounding, `canVoid`, `isOverdue`) | 13 passing |
| Pagination parse tests | 4 passing |
| Live response → domain types | 2 invoices parsed, totals `108.57` / `59` |
| API vocabulary leaking past `infrastructure/` | None — keys are `series`, `status`, `customerName` |
| Backend returns a bare array where an envelope was documented | **Throws**, with the exact path |
| `@Injectable`, constructor injection, `-api` in a component | None found |

## What the CLI does not give you

The largest finding, and it applies to every Angular project including the one
at work. `ng new --defaults` on CLI 22.1.2 omits three things the framework
requires:

| Missing | Consequence |
|---|---|
| `"strict": true` | **an existing project does not have it either** — it ships `strictInjectionParameters` and `strictInputAccessModifiers`, which are Angular options, not TypeScript strict mode |
| `src/environments/` | The rule "base URL comes from `environment.apiUrl`" points at a directory the CLI never creates. `ng generate environments` is a separate command |
| `ChangeDetectionStrategy.OnPush` | Every generated component starts non-compliant |

The framework stated all three as rules and assumed the scaffold produced them.
It does not. Now documented in `docs/angular.md` and `rules/angular.md`.

## The dependency-rule audit had a false positive

`CLAUDE.md` calls the dependency rule "verifiable" but never said how. The naive
check fails:

```
rg -l 'HttpClient' --glob '!*-api.ts'   →  invoice-store.ts
```

The match was the comment *"Injects the api, never HttpClient."* Searching import
statements instead returns nothing, which is correct.

An audit that flags the comment documenting the rule is worse than no audit —
it trains you to ignore it. `CLAUDE.md` §1.2 now says to check imports, not text.

## Angular cannot verify itself

Next.js route handlers made the previous test self-contained: the app was its own
backend. Angular is a browser-only SPA, so `-api.ts` cannot be exercised against
a real call without a second process.

A 40-line `Bun.serve` stub closed the gap, and it did more than the Next test
could: flipping `BARE_ARRAY=1` reproduced the exact failure from real work —
a documented paginated endpoint returning a bare array.

```
ZodError: expected object, received array
```

Immediate and precise, instead of an empty table that looks like valid data.

`invoice-schemas.ts` and `pagination.ts` ran in plain `bun` — no TestBed, no
browser, no Angular at all. They import zod and nothing else. That is the
dependency rule paying for itself: the layer that talks to the backend is the
cheapest one to verify.

## Rules that held up

- **`@Service()` + `inject()`**: matches the CLI's own output. No friction.
- **Flat layout with suffixes**: `ng g component invoices/invoice-list` produced
  exactly the shape the framework describes — the CLI was never fought.
- **Store never touches `HttpClient`**, component never touches `-api.ts`.
  Verified by import audit.
- **`.asReadonly()` and `computed()`**: `isEmpty` and `hasNextPage` derive from
  signals; nothing is stored twice.
- **Unmapped status throws** instead of defaulting — a voided invoice cannot
  render as editable.
- **Per-line rounding**: `3 × 0.335` bills as `1.01` per line, so printed lines
  sum to the printed total.

## Not covered

- Interceptors, guards, and `core/` — no auth in this feature
- Reactive forms with Zod
- Cursor pagination — `parseCursorPage` is tested by shape only, never against
  a live cursor endpoint
- Component rendering — deliberately. It is the layer where the architecture
  matters least

## Reproduce

```bash
bun install
bun stub-backend.ts &                 # BARE_ARRAY=1 to reproduce the mismatch
bun verify-contract.ts
bunx ng test
bunx ng serve --proxy-config proxy.conf.json
```
