---
name: diagnosis
description: "Trigger: bug, broken, failing, throwing, crash, no funciona, se rompe, error, regression, slow, performance, debug, diagnose, why is this happening. Build a red-capable feedback loop before forming any theory about the cause."
license: Apache-2.0
metadata:
  author: "walterjave"
  version: "1.0"
---

## Activation Contract

Apply when something is reported broken, slow, or behaving differently than
expected — before reading code to build a theory.

This is the maintenance counterpart to `../testing/`. That skill decides what
evidence proves a *criterion*. This one produces the evidence that a *bug is
real*, and then that it is gone.

## The rule everything rests on

> **No loop, no hypothesis.**

A tight pass/fail signal that goes red on *this* bug is the whole job. With one,
bisection, theory-testing and instrumentation all just consume it. Without one,
no amount of staring at code will save you — you will produce a plausible story,
change something, and the bug will come back next sprint wearing a new symptom.

If you catch yourself explaining the cause before a red command exists, stop.
That is the exact failure this skill prevents.

## Phase 0 — Is it even your bug?

Do this first when you do not own the whole stack, which for this framework is
the normal case.

A frontend fault and a backend fault look identical from the browser: something
is wrong on screen. Diagnosing your own code for a bug that lives on the other
side of the wire is the most expensive mistake available, because the loop you
build will never go red for the right reason.

| Symptom | Check before anything else |
|---|---|
| A field renders empty, `undefined`, or `NaN` | `fw evidence` — run the contract for that endpoint |
| Shape changed after a deploy that was not yours | Contract verification. `contract-drift.md` is the answer |
| Works for one record and not another | Contract, with the failing record's id |
| Only in one environment | Config and base URL before code |

A contract run costs seconds. It either clears the backend and narrows your
search, or it produces `contract-drift.md` — dated, with the exact field path
and the raw response. Send that instead of arguing.

**Say which side the bug is on before Phase 1.** If it is theirs, the deliverable
is the drift report, not a workaround. If a workaround is required anyway,
implement it behind the mapper in `infrastructure/`, never in a component, so it
can be removed in one file when they fix it.

## Phase 1 — Build the feedback loop

Spend disproportionate effort here. Be stubborn.

Ways to build one, roughly cheapest first:

1. **A failing test** at whatever seam reaches the bug.
2. **A contract run** against the endpoint, when the fault crosses the wire.
3. **`curl` against the running dev server**, with the exact payload.
4. **A CLI or script invocation** on a fixture input, diffed against known-good output.
5. **A browser loop** driving the UI and asserting on DOM, console or network —
   see `../testing/` under *Closing the loop in a browser*.
6. **A replayed capture.** Save the real request or event log to disk and run it
   through the code path in isolation.
7. **A throwaway harness** exercising the bug path with one function call.
8. **A property loop** — 1000 random inputs — when the symptom is "sometimes wrong".
9. **`git bisect run`**, when it worked at a known commit.
10. **A differential loop** — same input through two versions or two configs, diffed.

### Tighten it

Treat the loop as the product. Faster (cache setup, narrow scope), sharper
(assert the exact symptom, not "did not crash"), more deterministic (pin the
clock, seed randomness, freeze the network). A flaky 30-second loop is barely
better than none; a deterministic 2-second one is a different job.

For an intermittent bug the goal is not a clean repro but a **higher rate**. Loop
the trigger 100 times, add stress, narrow the timing window. 50% is debuggable,
1% is not.

### Done when

One named command, **already run at least once**, whose invocation and output you
can show, and which is:

- [ ] **Red-capable** — drives the real code path and asserts the user's exact
      symptom. "Runs without erroring" is not a loop
- [ ] **Deterministic** — same verdict every run
- [ ] **Fast** — seconds
- [ ] **Runnable unattended**

### When you genuinely cannot build one

Say so explicitly and list what you tried. Ask for the environment that
reproduces it, a redacted capture, or permission to instrument. **Do not proceed
to hypothesise.** Reporting that you cannot reproduce it is a real answer; a
confident theory with no loop is not.

### Narrowing a codebase you did not write

Before reading files to find the blast radius, ask the graph. If
`graphify-out/graph.json` exists, `graphify affected "<file or symbol>"` returns
the real dependents from the AST, with file and line.

Measured on a 2,874-file React codebase: extraction took 13 seconds, cost **zero
tokens** (tree-sitter, no LLM), and `affected` was **more accurate than grep** —
grep matched `items.service` inside `income-items.service` and reported two
dependents that do not exist; the graph did not.

| Use it for | Do not use it for |
|---|---|
| `affected "X"` — what breaks if X changes | Answering "how does X work" |
| `explain "X"` — callers and definition, with lines | Replacing reading the file |
| `god-nodes` — what is load-bearing before touching it | Anything needing the code's actual logic |

The natural-language `query` was measured returning 33 of 2,929 nodes for
~1,022 tokens, when reading the two files that actually held the answer cost
~813. **Use the graph to decide which files to open, then open them.** A node
list is a map, not an explanation.

Build with `graphify update <path>` — free and incremental. Never let a graph go
stale and be trusted; re-run it before relying on the answer.

## Phase 2 — Reproduce, then minimise

Run the loop and watch it go red.

Confirm it is **the user's failure**, not a different one nearby. Wrong bug,
wrong fix — and the report comes back.

Then shrink to the smallest scenario that still goes red. Cut inputs, callers,
config and steps **one at a time**, re-running after each cut. Done when every
remaining element is load-bearing: removing any one turns it green.

The minimal repro is what makes Phase 3 cheap and becomes the regression test in
Phase 5.

## Phase 3 — Hypothesise

Write **3 to 5 ranked hypotheses before testing any of them.** Generating one at
a time anchors you on the first plausible idea, which is how three days
disappear.

Each must be falsifiable — state the prediction:

> *"If the mapper drops the field, then requesting a record that has it will
> still render empty."*

If you cannot state a prediction, it is a vibe. Sharpen it or drop it.

Show the ranked list before testing. Domain knowledge re-ranks it instantly
— *"we deployed a change to number three yesterday"*. Do not block on the answer.

## Phase 4 — Instrument

Each probe maps to one prediction. **Change one variable at a time.**

1. Debugger or REPL when available. One breakpoint beats ten logs
2. Targeted logs at the boundary that separates two hypotheses
3. Never "log everything and grep"

**Tag every debug log** with a unique prefix — `[DEBUG-a4f2]` — so cleanup is one
grep. Untagged logs survive forever; tagged ones die.

For a performance regression, logs usually lie. Measure a baseline first
(`performance.now()`, profiler, query plan), then bisect. Measure, then fix.

## Phase 5 — Fix, with the regression test first

`../testing/` requires a failing test before a bug fix. This phase says where it
goes: **at a seam that exercises the real bug pattern as it occurs at the call
site.**

A seam too shallow to reproduce the bug gives false confidence — a unit test
that cannot replicate the chain that triggered it will pass whether or not the
bug is fixed.

**If no correct seam exists, that is the finding, not a licence to skip the
test.** Say it in one line: *"No seam can reproduce this — the logic is inline in
the component. Locking it down requires extracting to `domain/` first."* Then
either extract, or record it as the reason the fix ships unlocked. Silence here
is what turns the testing rule into paperwork.

With a seam:

1. Turn the minimised repro into a failing test there
2. Watch it fail — a regression test never seen red proves nothing
3. Apply the fix
4. Watch it pass
5. **Re-run the Phase 1 loop against the original, un-minimised scenario**

Step 5 is the one people skip. The minimal case passing does not mean the user's
case does.

## Phase 6 — Cleanup

Before saying it is done:

- [ ] The original repro no longer reproduces — Phase 1 loop re-run, output shown
- [ ] The regression test passes, or the absence of a seam is written down
- [ ] Every `[DEBUG-...]` line removed — grep the prefix
- [ ] Throwaway harnesses deleted
- [ ] `fw evidence` run, and its table pasted into the report
- [ ] **The hypothesis that turned out right is stated in the commit message**,
      so the next person to meet this bug inherits the reasoning instead of the
      patch alone

## Redaction

This skill has you show commands, outputs and captured artifacts. **Redact every
secret first** — write `<REDACTED>` in its place. Build loops against environment
variables so the credential stays in the environment rather than in what you
paste. Captured requests carry auth headers: quote only the lines that carry
signal.

If the redacted output is no longer enough to diagnose, say so and ask.

## References

- `../testing/SKILL.md` — the seam, the bug-fix row of Mode Resolution, the browser loop
- `../api-client/SKILL.md` — where a backend fault is contained
- `../../templates/contract-verification/` — Phase 0's instrument
- `../../bin/fw` — `fw evidence` produces the closing proof

The phase structure, the loop-before-hypothesis rule, ranked falsifiable
hypotheses and tagged instrumentation are adapted from the `diagnosing-bugs`
skill in [mattpocock/skills](https://github.com/mattpocock/skills) (MIT).
Phase 0, the contract-verification instrument and the `fw evidence` closing step
are this framework's own.
