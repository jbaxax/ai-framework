---
name: gating
description: "Trigger: gate, gating, permission, permiso, permisos, este control no tiene gate, hallazgo, finding, triage, triaje, entry point, punto de entrada, quién abre, quién llama, who opens, who reaches, who calls, alcanzable, reachable, dead code, código muerto, isOwner, can(. Resolve who reaches a control before calling it ungated, gating it, or deleting it."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "1.0"
---

## Activation Contract

Apply before writing a permission gate, before recording a finding that says a
control is ungated, and before deleting something as unreachable.

Do not apply it to a bug — that is `../diagnosis/`. This is about a claim, not
about a defect.

## The rule

> **A finding about one file is a hypothesis until you know who reaches it.**

A control's reachability is not written in the file that declares it. The button
says what it does; it does not say who could ever have arrived at the screen it
lives on. A regex over templates can only see the first half, so every finding it
produces is half a claim.

This is the same rule as `../../rules/foreign-source.md`, one level in: there the
missing half is the running server, here it is the caller.

## What it costs to skip it

Both directions of the error, from one audit:

- **False findings.** Eight of thirty-three remaining findings were controls
  already covered by the gate of whoever opens them — a modal reached only
  through a menu that already requires `productos.update`, a form reachable only
  under `isOwner()`. Written as findings, they become eight gates that can never
  evaluate to false.
- **False clean.** Twice a claim of "`roles.ts` has no gate" was recorded from a
  grep. Both files sat inside `if (this.isOwner())`. Neither had ever appeared in
  the audit; both came from reading one file.

The audit could not see either, and neither could the person reading the same
file. Nothing in the file answers the question.

## The triage

1. **Resolve every entry point.** Not one — every one.

   ```bash
   graphify affected "removeCollection"     # reverse traversal: who reaches this
   graphify explain "product-branch-modal"  # callers and definition
   ```

   One entry point is where this goes wrong. `collection.html` was fixed and
   `collection-list.html` called the **same** `removeCollection()` with the same
   hole, and it surfaced three hours later during triage. A sibling page is not
   an edge case, it is the normal shape of a UI.

2. **Read the gate on each entry point.** The route guard, the menu item's
   `@if`, the tab, the `isOwner()` wrapping the whole template.

3. **Then classify**, never before.

| Entry point requires | The control itself | Verdict |
|---|---|---|
| nothing | nothing | **Finding.** Reachable and ungated |
| the same permission the control needs | nothing | **Covered.** Not a finding — say so and move on |
| a *weaker* permission than the control needs | nothing | **Finding, and the worst kind.** The screen opens with `.update` and the button deletes |
| the same permission | gates on it again | **Redundant.** A branch that never evaluates to false |
| gate not resolvable — no graph, dynamic route | — | **Unknown.** Say `UNVERIFIED`, never "covered" |

Two entry points with different gates means the weakest one decides. A control
is as reachable as its easiest door.

## On the redundant row

The call this framework makes: **do not write a gate that can never be false.**
Eight of them is eight branches nobody exercises and no test can cover, in a
codebase that already has more unread code than anyone wants.

The argument for writing them anyway is uniformity — the local rule "gate with
what the endpoint demands" is simpler to state and does not ask anyone to reason
about the graph. That argument lost, on evidence, and it is worth knowing why:
the cost of uniformity is paid by whoever reads the code afterwards.

**The condition that flips it**: if an entry point could gain a second door later,
or its gate is owned by someone who might change it without looking here, the
redundant gate stops being dead and becomes insurance. Say which case you are in.

## The report

A finding without its entry point is not reviewable. Four columns, always:

```markdown
| Control | Código | Punto de entrada | Gate del punto de entrada |
|---|---|---|---|
| Eliminar cobro | collection.html:142 | menú Cobros | `can('cobros.view')` |
| Eliminar cobro | collection-list.html:88 | menú Cobros | `can('cobros.view')` |
| Editar sucursal | branch-form.html:12 | company-branch.html | `isOwner()` |
```

Two rows for one control is not duplication — it is the sibling page that would
otherwise be missed.

## When there is no graph

`graphify-out/` may not exist. Then say so in the same line, and read the routes
and the menu by hand — the answer is still required, only more expensive.

An unmeasured entry point is an assumption, not a finding.
`../verification-standards/SKILL.md` scores it `UNVERIFIED`.

## References

- `../verification-standards/SKILL.md` — an unmeasured claim is not a finding
- `../../docs/audit-tools.md` — the audit script that produces these findings
- `../../rules/foreign-source.md` — the same rule about a system you do not deploy
