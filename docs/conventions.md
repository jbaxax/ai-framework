# Naming and code conventions

Consistency inside a project beats consistency with this document. When
extending existing code, match what is already there and flag the mismatch
instead of introducing a third style.

## Files and folders

| Item | Convention | Example |
|---|---|---|
| Folders | kebab-case | `features/meal-entries/` |
| React components | PascalCase | `DietDashboard.tsx` |
| React hooks | camelCase, `use` prefix | `useMealEntries.ts` |
| Angular files | kebab-case, no type suffix | `invoice-api.ts` |
| Angular classes | PascalCase, no type suffix | `class InvoiceApi` |
| Types & interfaces | PascalCase | `MealEntry`, `InvoiceTotals` |
| Constants | SCREAMING_SNAKE_CASE | `IGV_RATE` |
| Server-only modules | `.server.ts` suffix | `session.server.ts` |
| React tests | `.test.ts` beside the subject | `calories.test.ts` |
| Angular tests | `.spec.ts` beside the subject | `invoice-totals.spec.ts` |

Angular's official guide asks for hyphens, descriptive names, and no
`.component.ts` / `.service.ts` suffixes. Angular v22's CLI already generates
files this way.

## Angular layer suffixes

Angular features are flat, so the file name carries the layer. This convention
is **this framework's**, not Angular's — it is compatible with the official
rules but not prescribed by them.

| Suffix | Layer | Constraint |
|---|---|---|
| `.model.ts` | domain | types only |
| `-totals.ts`, `-rules.ts` | domain | pure functions, no Angular imports |
| `-schemas.ts` | infrastructure | parses payloads, maps API names |
| `-api.ts` | infrastructure | the only file that injects `HttpClient` |
| `-store.ts` | application | signals and orchestration |
| component folder | presentation | injects the store, never the api |

Avoid generic names. `utils.ts`, `helpers.ts`, and `common.ts` become dumping
grounds — the same way `core/` does when its rule is "things used everywhere".

## Code

| Rule | Reason |
|---|---|
| Named exports | Default exports rename freely and break find-references. Framework-required files (Next.js pages) are the exception |
| No barrel `index.ts` per feature | Hides which layer you are importing from, and breaks tree-shaking |
| Explicit return types on exported functions | The signature is the contract; inference lets it drift silently |
| No `any` — use `unknown` and narrow | `any` disables the checks you are paying for |
| **No comments** | See below |

## No comments

Do not write comments. Not file headers, not `//` notes above a line, not JSDoc
blocks. When code seems to need explaining, the fix is to rename a variable,
extract a function, or make a type more specific — until the code says it itself.

Exceptions, and only these: directives a tool actually reads (`@ts-expect-error`,
`eslint-disable-next-line`, `'use client'`), and license headers.

Two habits replace what comments used to do:

| Instead of | Do this |
|---|---|
| `// rounds to cents so lines match the total` | Name it `roundToCents` |
| `// naive float sum gives 0.30000000000000004` | Put it in the test name: `it('sums 0.1 and 0.2 to exactly 0.3, not 0.30000000000000004')` |
| A block explaining why a layer exists | Write it once in the feature's `README.md` |
| `// reported to the backend, doc says paginated` | Commit message, or the README |

A reason the code genuinely cannot carry — a business decision, a backend
mismatch, a deliberate trade-off — is still worth recording. It goes in the
feature `README.md` or the commit message, where it survives a refactor. A
comment above a line does not: the line moves, the comment stays, and now it
lies.

## Angular specifics

| Rule | Correct |
|---|---|
| Service decorator | `@Service()` — never `@Injectable()`, and no `providedIn` |
| Dependency injection | `inject()` in a field — never constructor parameters |
| Components | Standalone. Never `NgModule` |
| Change detection | `ChangeDetectionStrategy.OnPush` |
| Signals | Keep writable signals private; expose `.asReadonly()` |
| Derived state | `computed()` — never a stored copy, which goes stale |

```ts
@Service()
export class InvoiceStore {
  private readonly api = inject(InvoiceApi);          // correct
  // constructor(private api: InvoiceApi) {}          // FORBIDDEN

  private readonly _invoices = signal<readonly Invoice[]>([]);
  readonly invoices = this._invoices.asReadonly();     // never expose the writable signal
}
```

## React specifics

| Rule | Reason |
|---|---|
| Server state in React Query only | Copying it into Context reintroduces manual sync |
| Context for UI state only | Theme, modals, flags — nothing fetched |
| Invalidate after mutations | Hand-patching the cache drifts from the server |
| `'use client'` only where needed | Everything else stays a Server Component |

## Language

Identifiers, comments, UI copy, commit messages, and documentation are in
English — unless the project is already written in another language, in which
case match it.

The exception is deliberate: API payloads keep the backend's vocabulary inside
`infrastructure/`, where the mapping to English domain names happens.

## Commits

Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.

No AI attribution and no co-author trailers.

## Checklist

- [ ] File and folder names match the tables above
- [ ] No `any`, no barrel exports, no generic `utils.ts`
- [ ] Exported functions declare their return type
- [ ] Angular: `@Service()`, `inject()`, `OnPush`, `.asReadonly()`
- [ ] React: no server state outside React Query
- [ ] Commit message follows conventional commits

## Next

- `docs/clean-architecture.md` — which layer a file belongs to
- `docs/stack-defaults.md` — which library to reach for
