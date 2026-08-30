# Contract verification

For the common case: a backend you do not own, cannot read, and cannot change.
They send documentation. The documentation drifts from the running code. You
find out when a screen breaks.

This turns that argument into evidence.

## What it checks

Three questions, in order. Each one fails loudly and separately.

| Check | Question | Failure means |
|---|---|---|
| Endpoint reachable | Does it answer? | Environment or auth problem — not drift |
| Response matches documented shape | Does reality match what they promised? | **Drift.** Their doc and their code disagree |
| No undocumented fields | Did they add something not in the doc? | Warning only — new fields do not break you, but you should know |
| Wire vocabulary stops at infrastructure | Did their field names reach your domain? | **Your** bug, not theirs. The mapping leaks |

The third check is the one that catches a backend rename before it spreads
through every component that read the raw field.

## Files

| File | Role |
|---|---|
| `contract.ts` | The runner. Copy as-is, do not edit per project |
| `invoices.contract.ts` | One contract, as reference. Copy the shape, replace the content |
| `verify.ts` | Entry point. Register each contract here |
| `stub-backend.ts` | A fake backend that can drift on demand — for practising, and for CI without their server |

## Install

In a repository you own, `contracts/` at the root is fine. In a repository
shared with a team that has not adopted this, install under `.fw/` — a single
namespaced directory for everything the framework drops into someone else's
project, kept out of git by one global ignore rule:

```bash
mkdir -p .fw/contracts
cp <framework>/templates/contract-verification/{contract.ts,verify.ts} .fw/contracts/
cp <framework>/templates/contract-verification/invoices.contract.ts .fw/contracts/example.contract.ts
```

Run it directly rather than adding a `package.json` script — `package.json` is
committed, and a script entry is a change your teammates would review:

```bash
bun run .fw/contracts/verify.ts
```

In your own repositories, add the script and commit the contracts. A contract
test is ordinary engineering; it only stays personal where the team has not
agreed to it.

## Writing a contract

The `documented` schema encodes **what their documentation promises** — not what
you wish it said, and not what the response happens to contain today. That
distinction is the whole point: the schema is their promise, written down, so
the diff against reality is mechanical.

```ts
export const ordersContract: ContractDefinition<DocumentedOrder, Order> = {
  name: 'GET /api/pedidos — order list',
  url: `${BASE}/api/pedidos`,
  init: { headers: { Authorization: `Bearer ${Bun.env['API_TOKEN']}` } },
  documented: documentedOrderPage,
  wireVocabulary: ['numero_pedido', 'estado', 'fecha_creacion'],
  map: toOrderPage,
};
```

`map` is the same mapping function your `infrastructure/` layer uses. Import it
from there rather than duplicating it — otherwise the check verifies a copy and
the real mapping stays untested.

## Running it

```bash
bun run verify:contracts                      # against the real backend
BASE=https://staging.example.com bun run verify:contracts
```

Exit code is `0` when every contract matches, `1` on drift. That makes it usable
as a CI step and as a pre-implementation gate.

On drift it writes `contract-drift.md`: the failing field paths, the expected
type, what arrived, and the raw response. **Send that file.** It is not a
complaint, it is their own promise next to their own output, with a timestamp.

## Practising against the stub

The stub reproduces the drift classes that actually happen:

```bash
DRIFT=none          bun run stub-backend.ts   # matches the contract
DRIFT=bare-array    bun run stub-backend.ts   # documented envelope, returns a bare array
DRIFT=date-format   bun run stub-backend.ts   # ISO 8601 documented, returns dd/mm/yyyy
DRIFT=missing-field bun run stub-backend.ts   # a documented field disappears
DRIFT=wrong-type    bun run stub-backend.ts   # number documented, string returned
DRIFT=extra-field   bun run stub-backend.ts   # an undocumented field appears
```

Then in another shell: `BASE=http://localhost:4100 bun run verify.ts`

`extra-field` is the only one that still exits `0`. A field you did not ask for
cannot break a parse — but it is often the first visible sign that the backend
changed, so it reports as a warning rather than passing silently.

## Where this sits

Run it **before** writing code against a new endpoint, and keep it running after.

This is not E2E. It opens no browser, logs nobody in, and touches none of your
UI. It answers one question — *is their response the shape they promised* — in
seconds, and names the exact field when the answer is no.

An E2E failure tells you a screen is empty. A contract failure tells you which
field changed and in what way. Only the second one can be forwarded to the
person who caused it.
