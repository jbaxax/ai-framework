---
paths:
  - "**/*.controller.ts"
  - "**/*.guard.ts"
  - "**/*.decorator.ts"
  - "**/*.resolver.ts"
  - "**/openapi*.yaml"
  - "**/openapi*.json"
  - "**/swagger*.json"
  - "**/*.proto"
---

# Reading a system you do not deploy

One question first, and it takes a second to answer:

> **Do you deploy this?**

- **Yes** — it is your source. `backend.md` applies and this file does not.
- **No** — you are reading a description of a server you have never measured.

## The rule

**Source you do not deploy is a hypothesis. Its running instance is the
evidence.**

A decorator in a repository proves the decorator was written. It does not prove
the deployed binary was built from that commit, that the guard is registered,
that later middleware short-circuits it, or that the environment enables it.
Those are four separate claims and none of them is visible in the file.

The case this rule was written from: four NestJS controllers carried
`@RequireAccountOwner()`, committed months earlier. A table was built from that
reading and presented as verified. Measured against the running server, **three
of the four let a non-owner straight through** — the deployed binary was not
built from that code. Believing the file would have added four owner-gates to
the frontend, hiding controls that work today for the people using them.

## Before asserting behavior

| The claim | Reading the source is | The evidence is |
|---|---|---|
| This endpoint requires permission X | a hypothesis | a request from a principal without X |
| This field is optional | a hypothesis | a request that omits it |
| The response has this shape | a hypothesis | a captured response |
| This code path exists in the repository | evidence | — |

Say which one you have. *"The controller carries the decorator"* is an honest
sentence. *"The endpoint is owner-only"* is not, until it has been measured.

## The probe

Full recipe in `../docs/foreign-systems.md`. Two properties make it safe to point
at a real server:

- **It must not mutate.** NestJS runs guards **before** the `ValidationPipe`, so
  a `POST`/`PATCH` with an empty body never reaches a handler. `403` means the
  gate blocked you; `400` means it let you through and validation stopped you.
  Zero rows touched.
- **It needs a positive control.** A probe that cannot tell "not gated" from
  "wrong host, expired token, server down" reports everything as open. Include
  one endpoint you already know blocks. In the case above a single `403` from
  `PATCH /doc-types/:id/ventas` is what made the other three answers believable.

A probe you have never seen block is not a probe — the same rule `testing.md`
applies to any improvised check. Make it fail once first.

## Permissions are a graph, not a list

Before concluding that a control needs a gate, check whether the permission it
would test is already implied by the one that opened the screen. A role holding
`compras.create` may carry `productos.create` by dependency, which makes the gate
you were about to write a condition that never evaluates to false.

Ask the server for the graph — a permission-dependency endpoint, or a role built
and read back through `/auth/me`. Nine "missing gates" collapsed to one that way.
