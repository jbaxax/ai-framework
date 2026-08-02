# Framework Rules

Reusable baseline for projects built with Claude Code. It encodes the stack, the
architecture, and the conventions so they never have to be re-explained per prompt.

**Scope**: the frontend section is always active. The backend section applies only
to full-stack personal projects — ignore it when the project is frontend-only.

Detailed docs live in `docs/`. Task-specific rules live in `skills/`. A working
reference implementation lives in `templates/feature-template/`.

---

## 1. Non-negotiable rules

### 1.1 Ask before assuming

If a relevant technical decision is not specified, **stop and ask**. Do not pick
one and implement it.

Decisions that always require asking when unspecified:

- Authentication method (sessions, JWT, provider-based)
- Token/session storage strategy
- State management beyond the defaults in section 2
- Any new runtime dependency not already in `package.json`
- Data model or schema shape
- Error handling and retry policy for a new integration
- Anything that changes the public contract of an existing module

Ask **one** question at a time and wait for the answer. A default listed in this
file is an answer — use it without asking. Silence on something *not* covered
here is not permission.

### 1.2 The dependency rule

Layers depend **inward only**. An inner layer must never import from an outer one.

```
presentation  →  application  →  domain
infrastructure  →  domain
```

| Layer | May import from | Must never import from |
|---|---|---|
| `domain` | nothing (only other `domain` files) | application, infrastructure, presentation, any library, any framework |
| `application` | domain | presentation, framework routing/UI |
| `infrastructure` | domain | application, presentation |
| `presentation` | application, domain | infrastructure |

This rule is verifiable, not aspirational. Before finishing any feature, check the
imports in each layer against this table.

**Forbidden patterns** — these are real violations found in previous projects:

```ts
// FORBIDDEN — application importing a Zod schema type from presentation
// features/auth/application/useUpdateProfile.ts
import { UpdateUserInput } from "../presentation/schemas/profileSchema"
```
Input types belong to `domain`. Presentation builds its validation schema *from*
the domain type, never the other way around.

```ts
// FORBIDDEN — database schema types leaking into domain
// features/diet/domain/calories.ts
import { Tables, Enums } from "@/lib/supabase/types"
```
`domain` declares its own types. `infrastructure` maps DB rows to domain types at
the boundary. If the database vendor changes, `domain` must not change.

### 1.3 Domain stays pure

`domain` contains business logic as plain functions and types. No React, no HTTP
client, no ORM, no framework imports, no I/O. If a rule can be expressed as a pure
function, it belongs in `domain` and it gets a unit test.

Rationale: business logic tangled into components cannot be tested cheaply, and
logic that is expensive to test does not get tested at all. Keeping `domain` pure
means the option to test is always available and always cheap.

**Tests are written on request only** — see `skills/testing/SKILL.md`. Do not add
them unprompted. When pure logic ships untested, say so in one line at the end so
the decision stays visible.

---

## 2. Stack defaults

Use these without asking. Deviating from them requires asking first.

### Frontend (always active)

| Concern | Default |
|---|---|
| Framework | Next.js, App Router |
| Language | TypeScript, `strict: true` |
| Server state | TanStack Query (React Query) |
| Client/UI state | React Context — only for theme, modals, and UI flags |
| HTTP client | Axios, via a shared configured instance (see `skills/api-client`) |
| Validation | Zod, in `presentation/schemas/` |
| Forms | React Hook Form + Zod resolver |
| Testing | Vitest (see `skills/testing`) |
| Package manager | bun |

**Server state never lives in Context or a global store.** React Query owns
fetching, caching, and invalidation. Duplicating server data into a store
reintroduces manual synchronization that React Query already solves.

Zustand is **not** a default. Introduce it only for genuinely complex client
state (multi-step wizards, cart-like local aggregates), and only after asking.

### Secondary frontend: Angular (v22)

Keep the same architecture and dependency rule. Substitute the Angular idioms:

| Concern | Rule |
|---|---|
| Service decorator | `@Service()` — **not** `@Injectable()`, and no `providedIn` |
| Dependency injection | `inject()` in a field — **never** constructor parameter injection |
| Components | Standalone — never `NgModule` |
| Routing | Lazy-loaded `<feature>.routes.ts` per feature |
| Local/shared state | Signals; expose them read-only via `.asReadonly()` |
| Server state | `HttpClient` + RxJS — no React Query equivalent |
| HTTP | Functional interceptors, not Axios |
| Base URL | `environment.apiUrl` — never a hardcoded host in service code |
| Dev CORS | `proxy.conf.json` at the repo root |

`@Service` and `inject` are different tools with confusingly similar names:
`@Service()` marks the class as injectable; `inject()` retrieves a dependency.
Angular 22 uses both — `inject()` is not optional just because the decorator
changed name.

Any service that consumes an API is decorated with `@Service()`. `@Injectable()`
belongs to Angular's previous era — treat any occurrence as legacy to migrate.
`@Service()` is root-provided by default; adding `providedIn: 'root'` is noise.

```ts
@Service()                                           // not @Injectable()
export class Auth {
  private readonly http = inject(HttpClient);        // correct
  // constructor(private http: HttpClient) {}        // FORBIDDEN
  private readonly _user = signal<User | null>(null);
  readonly user = this._user.asReadonly();           // never expose the writable signal
}
```

**Never hardcode a host or IP in a tracked file**, including `proxy.conf.json`.
Read the target from an environment variable with a localhost fallback.
A committed internal IP leaks network topology into git history, where it stays
after the file is fixed.

**Layer mapping** — `core/` holds only cross-cutting singletons (guards,
interceptors, app-wide config). It is not a services dumping ground: a service
used by one feature lives in that feature's `infrastructure/`. `shared/` holds
reusable UI with no business logic.

Do not keep both `features/` and `pages/` as parallel homes for screens. Routes
live in `app.routes.ts` and feature route files; the screens themselves belong to
their feature.

### Backend (opt-in — personal full-stack projects only)

| Concern | Default |
|---|---|
| Framework | NestJS |
| ORM | Prisma |
| Database | PostgreSQL |
| Validation | Zod or `class-validator` at the controller boundary |
| Testing | Vitest or Jest, matching the project |

NestJS modules map to features. Controllers are `presentation`, services that
orchestrate are `application`, repositories and Prisma access are
`infrastructure`, and entities plus business rules are `domain`.

### Legacy exception

Older projects may still use `pnpm` or `npm`. Do not migrate a project's package
manager as a side effect of another task — propose it as its own change.

---

## 3. Architecture

### 3.1 Feature-colocated, not layer-first

A feature is **one folder** containing its own layers. Never split a feature
across top-level `components/`, `hooks/`, and `services/` folders.

```
features/
└── diet/
    ├── domain/
    │   ├── types.ts            pure types, no framework
    │   ├── calories.ts         pure business logic
    │   └── calories.test.ts    unit tests, colocated
    ├── application/
    │   ├── useFoods.ts         React Query hooks, orchestration
    │   └── useMealEntries.ts
    ├── infrastructure/
    │   └── dietService.ts      HTTP/DB access, maps to domain types
    └── presentation/
        ├── components/         feature-owned UI
        └── schemas/            Zod schemas for forms
```

Rationale: everything needed to change one behavior lives in one place. Layer-first
layouts force jumping across four root folders to touch a single feature, and they
accumulate orphaned files that fit no layer.

### 3.2 Module grouping (only when needed)

Below ~15 features, keep `features/` flat. Past that, group by business module:

```
features/
├── gerencia/
│   ├── roles/       → domain/ application/ infrastructure/ presentation/
│   └── usuarios/    → domain/ application/ infrastructure/ presentation/
└── logistica/
    └── compras/     → domain/ application/ infrastructure/ presentation/
```

The grouping level adds **only** a folder. It never introduces shared
`components/` or `hooks/` folders at the module level — that reintroduces
layer-first layout through the back door.

### 3.3 What lives outside `features/`

| Path | Contents | Rule |
|---|---|---|
| `app/` | Routing only — `page.tsx`, `layout.tsx`, route handlers | Pages compose feature components. No business logic. |
| `components/ui/` | Design-system primitives (button, input, dialog) | No business logic, no data fetching. |
| `components/shared/` | Cross-feature composite UI | Used by 2+ features. Used by one? It belongs to that feature. |
| `lib/` | Framework-agnostic utilities and client setup | Pure and testable. |
| `hooks/` | Generic, feature-agnostic hooks (`useDebounce`) | Feature-specific hooks belong in that feature's `application/`. |

**Promotion rule**: code starts inside its feature. It moves to `shared/` or
`lib/` only when a second consumer actually exists — never in anticipation.

---

## 4. Conventions

### Files and folders

| Item | Convention | Example |
|---|---|---|
| Folders | kebab-case | `features/meal-entries/` |
| React/Angular components | PascalCase | `DietDashboard.tsx` |
| Hooks | camelCase, `use` prefix | `useMealEntries.ts` |
| Services | camelCase + `.service.ts` or `<name>Service.ts` — pick one per project | `dietService.ts` |
| Types & schemas | camelCase file, PascalCase type | `types.ts` → `MealEntry` |
| Tests | sibling of subject, `.test.ts` | `calories.test.ts` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_DAILY_CALORIES` |

Be consistent **within a project** above all. When extending existing code, match
what is already there rather than what this table says, and flag the mismatch.

### Code

- Named exports. Default exports only where the framework requires them (Next.js pages/layouts).
- No barrel `index.ts` re-exporting a whole feature — it hides dependency violations and breaks tree-shaking.
- Explicit return types on exported functions.
- No `any`. Use `unknown` and narrow.
- Comments explain **why**, never **what**.
- Identifiers, comments, UI copy, and commit messages in English unless the project is already in another language.

### Commits

Conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).
No AI attribution or co-author trailers.

---

## 5. Definition of done

Before reporting a feature complete, verify:

- [ ] Imports in every layer match the table in 1.2 — no inward violations
- [ ] `domain` has no framework, library, or I/O imports
- [ ] No server state duplicated into Context or a store
- [ ] No new dependency added without asking
- [ ] Types check and lint pass
- [ ] Untested pure logic declared in one line — tests only if they were requested

Report failures honestly, with the actual output. Do not describe unverified work
as done.
