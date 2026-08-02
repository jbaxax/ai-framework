# Feature template — Angular v22

The same invoicing feature as `../feature-template/`, in Angular idiom.
Reference only — these files are not part of a build.

## Layout

Flat, as the [Angular style guide](https://angular.dev/style-guide) asks. The
layer is carried by the **file name**, not by a folder:

```
features/invoice/
├── invoice.model.ts       domain — types only
├── invoice-totals.ts      domain — pure logic, imports nothing from Angular
├── invoice-totals.spec.ts
├── invoice-schemas.ts     infrastructure — Zod parsing + field mapping
├── invoice-api.ts         infrastructure — the only file with HttpClient
├── invoice-store.ts       application — signals, orchestration
├── invoice-list/          presentation — CLI creates the folder
└── invoice-form/
```

| Suffix | Layer | Constraint |
|---|---|---|
| `.model.ts` | domain | types only |
| `-totals.ts`, `-rules.ts` | domain | pure functions, no Angular imports |
| `-schemas.ts` | infrastructure | parses payloads, maps API names to domain names |
| `pagination.ts` | infrastructure | generic envelope — belongs in `core/` in a real project |
| `-api.ts` | infrastructure | the only file allowed to inject `HttpClient` |
| `-store.ts` | application | signals and orchestration, never `HttpClient` |
| component folders | presentation | inject the store, never the api |

The suffix convention is **this framework's**, not Angular's. It is compatible
with the official rules — hyphens, descriptive names, no generic `utils.ts` —
but the official guide does not prescribe it.

## Generating the files

```bash
ng g service   features/invoice/invoice-api
ng g service   features/invoice/invoice-store
ng g component features/invoice/invoice-list
ng g component features/invoice/invoice-form
```

`invoice.model.ts` and `invoice-totals.ts` are written by hand. There is no
schematic for them because they contain no Angular — which is exactly how you
can tell where the business logic lives.

Angular v22 generates `@Service()`, not `@Injectable()`. Any `@Injectable()` in
the codebase is legacy to migrate.

## Where this differs from a typical Angular app

- **No `core/services/` dump.** A service used by one feature lives beside that
  feature. `core/` keeps only what the whole app needs: auth, interceptors, guards.
- **`-api` and `-store` are separate classes.** Mixing `HttpClient` and signals
  in one service couples transport to state and makes both harder to reason about.
- **No `should create` specs.** A test that asserts Angular can instantiate a
  class cannot fail. Delete them; keep tests like `invoice-totals.spec.ts`.

## Scaling

Flat until the feature gets large (roughly 15 files). Then group into folders as
a navigation aid — not as an architecture change. The dependency rule lives in
the imports, never in the directory names.
