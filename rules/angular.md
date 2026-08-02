---
paths:
  - "src/app/**/*.ts"
  - "src/app/**/*.html"
  - "**/*.component.ts"
  - "angular.json"
---

# Angular v22 rules

Loaded automatically when working with Angular files. Full detail and rationale
live in `docs/angular.md`.

## Non-negotiable

| Concern | Rule |
|---|---|
| Service decorator | `@Service()` — never `@Injectable()`, and no `providedIn` |
| Dependency injection | `inject()` in a field — never constructor parameters |
| Components | Standalone, `ChangeDetectionStrategy.OnPush` |
| Signals | Keep writable signals private; expose `.asReadonly()` |
| Derived state | `computed()` — never a stored copy |
| Base URL | `environment.apiUrl` — never a hardcoded host or IP |
| UI components | PrimeNG + `@primeng/themes`. Style through the theme, not overrides |
| Tests | Delete CLI-generated `should create` specs; they cannot fail |

The CLI does **not** give you three of these. Check on a fresh project:
`"strict": true` in `tsconfig.json` (absent — `strictInjectionParameters` is not
it), `src/environments/` (never created; run `ng generate environments`), and
`OnPush` on every generated component.

```ts
@Service()                                      // not @Injectable()
export class InvoiceApi {
  private readonly http = inject(HttpClient);   // correct
  // constructor(private http: HttpClient) {}   // FORBIDDEN
}
```

## Feature layout — flat

Angular features stay flat; the file name carries the layer.

| Suffix | Layer | Constraint |
|---|---|---|
| `.model.ts` | domain | types only |
| `-totals.ts`, `-rules.ts` | domain | pure functions, no Angular imports |
| `-schemas.ts` | infrastructure | parses payloads, maps API names |
| `-api.ts` | infrastructure | the only file that injects `HttpClient` |
| `-store.ts` | application | signals; never `HttpClient` |
| component folder | presentation | injects the store, never the api |

`core/` holds only cross-cutting singletons — guards, interceptors, auth. A
service used by one feature lives beside that feature, never in `core/services/`.

PrimeNG components are used directly in a feature's presentation template. A
wrapper goes in `shared/ui/` only when two or more features need the same
configured variant — never in anticipation. A wrapper never knows a business
rule: a table component does not know what a `comprobante` is.

```bash
ng g service   features/invoice/invoice-api
ng g component features/invoice/invoice-list
```

## Reference

- `docs/angular.md` — full rules and rationale
- `templates/feature-template-angular/` — the reference feature
