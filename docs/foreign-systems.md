# Measuring a system you do not deploy

## The problem this solves

You have read access to the backend repository. You open `bank.controller.ts`,
see `@RequireAccountOwner()`, and write down that the endpoint is owner-only.

That sentence is false in a way no amount of careful reading catches. Between the
decorator and the behavior of the server your frontend talks to sit at least four
independent facts:

1. The deployed binary was built from **this** commit.
2. The guard is registered in the module that serves this route.
3. No earlier middleware or interceptor short-circuits it.
4. The environment the server runs in enables it.

A file can prove exactly one thing: that somebody wrote the decorator. The other
three are claims about a running process.

The case that produced this document: four controllers carried the decorator,
committed months earlier. Measured, three of the four let a non-owner through.

| Endpoint | The source says | The running server, non-owner |
|---|---|---|
| `PATCH /doc-types/:id/ventas` | permission + OWNER | **403 — blocked** |
| `POST /bank` | permission + OWNER | **400 — passed** |
| `POST /transport-company` | permission + OWNER | **400 — passed** |
| `GET /payment-type` | permission + OWNER | **200 — passed** |

The deployed binary was not built from that code. Nothing in the repository could
have said so.

## The rule

> **Source you do not deploy is a hypothesis. Its running instance is the
> evidence.**

This is the same rule `rules/testing.md` already applies to your own improvised
checks, pointed one level further out. A `grep` you have never seen fail proves
nothing about a quiet run; a controller you have never called proves nothing
about a live request.

## Designing a probe that touches nothing

The requirement is uncomfortable: measure authorization on a production-shaped
system without creating, modifying, or deleting a single row.

### The lever

**Authorization runs before body validation.** In NestJS, guards execute ahead of
the `ValidationPipe`, so a write request with an empty body never reaches the
handler. The response separates the two outcomes cleanly:

```
POST /bank   with  {}   and a token WITHOUT the permission

  403  →  the guard rejected you. The gate is live.
  400  →  the guard let you through; validation refused the empty body.
          The gate is not enforced for this principal.
```

Neither answer writes anything. The handler is never entered.

Confirm the ordering holds in the framework you are probing before relying on it.
Where validation runs first, the lever is different — probe a `GET`, or send a
request that is authorized but deliberately malformed — but the principle does
not change: find a response that distinguishes *rejected by the gate* from
*rejected by everything after the gate*.

### Reading the answers

| Status | What it means | What it does not mean |
|---|---|---|
| `401` | Your token is invalid or expired | Nothing about the gate — fix the token and re-run |
| `403` | The gate blocked this principal | — |
| `400` | You reached validation, so the gate did not block you | Not that the endpoint is broken |
| `404` | Route or record missing | Ambiguous — some servers hide forbidden routes as 404 |
| `200` | The gate did not block a read | — |
| `5xx` | You reached the handler | The gate did not block you, and you may have touched data |

`404` and `5xx` are the two that end a probe. A `404` cannot be told apart from a
deliberately hidden route without a second signal, and a `5xx` means the handler
ran — which is exactly what the probe promised not to do.

### The positive control

This is the part that is easy to skip and expensive to skip.

A probe with no known-blocking endpoint in it cannot distinguish these:

- the endpoints are genuinely ungated
- the token was never attached to the request
- the base URL points at a different environment
- the server is returning the same status for everything

All four produce a clean table of "not gated". **Include at least one endpoint
you already know blocks**, and read its row first. If the control does not block,
the run is void and the rest of the table means nothing.

In the measured case the single `403` on `PATCH /doc-types/:id/ventas` is the
only reason the three `400`s could be believed.

### The principal

Build the least-privileged principal that can still reach the route: a role with
the permissions needed to authenticate and nothing else, and a user assigned to
it. Create it against the real server — a principal you constructed in your head
has the same problem as a decorator you read.

Then **read the principal back**. Permissions are usually a graph, not a list: a
role granted `compras.create` may carry `productos.create` by dependency, and a
probe that assumes otherwise measures a permission the principal did not actually
lack. Ask the server which permissions the role ended up with, through a
dependency endpoint or through `/auth/me`.

That graph is worth reading before writing gates at all. Nine "missing gates"
collapsed to one when the dependencies were read: eight of them were conditions
that could never evaluate to false, which is eight branches nobody can exercise
and nobody can test.

## Reporting it

A claim measured this way carries its measurement. A claim that was not measured
says so:

```
Owner-only on POST /bank — HYPOTHESIS, read from bank.controller.ts, not probed.
```

`skills/verification-standards/SKILL.md` treats an unmeasured claim about another
system as `UNVERIFIED`, not as a warning. Naming it costs one word and keeps the
next person from building on it.

## When you cannot probe

Sometimes there is no non-production environment and no spare principal. That is
a legitimate stopping point, and the honest output is the hypothesis plus the
reason it could not be measured — never a table that reads as verified.

What is **not** legitimate is treating the repository as the measurement because
the measurement was inconvenient. The four-row table above was written that way.

## References

- `../rules/foreign-source.md` — the rule, loaded by path
- `../skills/verification-standards/SKILL.md` — how an unmeasured claim is scored
- `../rules/testing.md` — the same rule applied to your own improvised checks
