# Angular v22 rules

Load this file **only when the project is Angular**. Everything in `CLAUDE.md`
still applies — the dependency rule, ask-before-assuming, testing on request,
and the conventions. This document replaces only the React-specific idioms.

## Idioms

| Concern | Rule |
|---|---|
| Service decorator | `@Service()` — **not** `@Injectable()`, and no `providedIn` |
| Dependency injection | `inject()` in a field — **never** constructor parameters |
| Components | Standalone — never `NgModule` |
| Change detection | `ChangeDetectionStrategy.OnPush` |
| Routing | Lazy-loaded `<feature>.routes.ts` per feature |
| Local/shared state | Signals, exposed read-only via `.asReadonly()` |
| Derived state | `computed()` — never a stored copy |
| Server state | `HttpClient` + RxJS — there is no React Query equivalent |
| HTTP | Functional interceptors, not Axios |
| Base URL | `environment.apiUrl` — never a hardcoded host in service code |
| Dev proxy | `proxy.conf.json`, target read from an environment variable |
| Testing | Vitest via `ng test` |

## `@Service` vs `inject` — different tools, similar names

`@Service()` marks the class as injectable. `inject()` retrieves a dependency.
Angular v22 uses **both**. `inject()` did not go away because the decorator was
renamed.

`@Injectable()` belongs to Angular's previous era — treat any occurrence as
legacy to migrate. `@Service()` is root-provided by default, so
`providedIn: 'root'` is noise.

```ts
@Service()                                           // not @Injectable()
export class Auth {
  private readonly http = inject(HttpClient);        // correct
  // constructor(private http: HttpClient) {}        // FORBIDDEN

  private readonly _user = signal<User | null>(null);
  readonly user = this._user.asReadonly();           // never expose the writable signal
}
```

## Feature structure — flat

Angular's [style guide](https://angular.dev/style-guide) asks for feature
directories and explicitly warns against `components/`, `directives/`, and
`services/` folders. So Angular features stay **flat**, and the file name
carries the layer.

```
features/invoice/
├── invoice.model.ts     domain — types only
├── invoice-totals.ts    domain — pure logic, no Angular imports
├── invoice-schemas.ts   infrastructure — Zod parsing + field mapping
├── invoice-api.ts       infrastructure — the only file with HttpClient
├── invoice-store.ts     application — signals, orchestration
├── invoice-list/        presentation — CLI creates the folder
└── invoice-form/
```

| Suffix | Layer | Constraint |
|---|---|---|
| `.model.ts` | domain | types only |
| `-totals.ts`, `-rules.ts` | domain | pure functions, no Angular imports |
| `-schemas.ts` | infrastructure | parses payloads, maps API names |
| `-api.ts` | infrastructure | the only file that injects `HttpClient` |
| `-store.ts` | application | signals; never `HttpClient` |
| component folder | presentation | injects the store, never the api |

This suffix convention is **this framework's**, not Angular's. It is compatible
with the official rules — hyphens, descriptive names, no generic `utils.ts` —
but the official guide does not prescribe it.

The dependency rule lives in the **imports**, not in the folder names. Flat costs
nothing.

Group into folders only when a feature gets large (roughly 15 files), and treat
it as a navigation aid, not an architecture change.

## What `ng new` does not give you

Verified against Angular CLI 22.1.2. Three defaults this framework requires are
**not** produced by the scaffold — check them on the first commit, not later:

| Missing | Fix |
|---|---|
| `"strict": true` in `tsconfig.json` | Add it. The CLI ships `strictInjectionParameters` and `strictInputAccessModifiers` only — neither is TypeScript strict mode |
| `src/environments/` | `ng generate environments`. The `environment.apiUrl` rule below points at a directory the CLI never creates |
| `ChangeDetectionStrategy.OnPush` | Add it to every generated component. `ng g component` omits it |

Adding `strict` to an existing project is a change of its own — it will surface
errors across files that have nothing to do with the current task. Propose it
separately.

## Generating files

```bash
ng g service   features/invoice/invoice-api
ng g service   features/invoice/invoice-store
ng g component features/invoice/invoice-list
```

The CLI accepts nested paths and creates the directories. Components get their
own folder because they are three files; services stay flat beside them.

`invoice.model.ts` and `invoice-totals.ts` are written by hand — there is no
schematic because they contain no Angular. That is how you can tell where the
business logic lives.

## `core/` is not a dumping ground

`core/` holds only cross-cutting singletons: guards, interceptors, app-wide
config, auth. A service used by **one** feature lives beside that feature.

The failure mode is predictable: because "things used everywhere" is a vague
rule, everything eventually qualifies and `core/services/` ends up holding every
service in the app.

`shared/` holds reusable UI with no business logic.

Do not keep both `features/` and `pages/` as parallel homes for screens. Routes
live in `app.routes.ts` and feature route files; screens belong to their feature.

## UI components — PrimeNG

The default. Not because it is the prettiest, but because a work codebase cannot
afford a UI layer that falls out of support on a missed upgrade — PrimeNG is
backed by a company, supports two prior majors, and sells an LTS on top.

```bash
bun add primeng @primeng/themes
```

Two rules:

**Style through the theme, not through overrides.** `@primeng/themes` replaced
the old CSS-variable-and-`::ng-deep` approach entirely. A codebase fighting
PrimeNG with `!important` usually never configured a preset. Configure it once in
`app.config.ts` before concluding the library looks wrong.

**A PrimeNG component is used directly in a feature template.** Wrap one in
`shared/ui/` only when a second feature needs the same configured variant, and
never let the wrapper learn a business rule. A table that knows what a
`comprobante` is cannot be swapped.

The Angular equivalent of shadcn/ui is [spartan/ui](https://spartan.ng) — same
copy-paste model, ~60 components. It supports only the two latest Angular majors,
which is why it is not the default. Choosing it is a decision to state out loud,
not a default to assume. See `stack-defaults.md`.

## Never commit a host or IP

Including in `proxy.conf.json`. Read the target from an environment variable
with a localhost fallback. A committed internal IP stays in git history after
the file is fixed.

## Tests

The CLI generates `should create` specs that assert Angular can instantiate a
component. Those cannot fail and protect nothing — **delete them**.

Test pure logic instead, as in `templates/feature-template-angular/invoice-totals.spec.ts`.
And only when tests were requested.

## Verifying against a real response

Angular is a browser-only SPA. Unlike Next.js it has no route handlers, so there
is no way to exercise `-api.ts` against a real call without a second process.

Run a stub that returns the backend's **actual** payload — its own vocabulary,
its own envelope — and point `proxy.conf.json` at it. Twenty lines is enough:

```ts
Bun.serve({ port: 4100, fetch: () => Response.json({ data: [...], meta: {...} }) });
```

This is what makes the "verify the doc against a real response" step
(`skills/api-client/`) possible without the work backend being reachable. It also
lets you reproduce the failure on purpose: return a bare array where an envelope
was documented and confirm the parse throws instead of rendering "no results".

`-schemas.ts` and the pagination helpers import zod and nothing else, so they run
in plain `bun` — no TestBed, no browser. That is the dependency rule paying off:
the layer that talks to the backend is the one that is cheapest to verify.

## Reference

`templates/feature-template-angular/` — the same feature as the React template,
in Angular idiom. `invoice-totals.ts` is byte-identical to the React version.
