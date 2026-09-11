---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.html"
  - "**/*.go"
  - "**/*.py"
  - "**/.env*"
---

# Who runs the check

`foreign-source.md` establishes that the running instance is the evidence. It
never said who goes and gets it. This file does.

## The rule

> **A check you can run, you run. Handing it to the person is the last resort,
> never the cheap one.**

Asking costs seconds to type and a round trip to answer. The round trip is the
expensive half, and it is paid by someone who was doing something else. A `curl`
that would have taken two seconds, handed over instead, is how a diagnosis that
should have taken ten minutes takes a morning.

The case this rule was written from: a backend known to ship stale documentation,
wrong casing, and null ids. Every question about it — is it up, what does it
actually return, is that id null — was answerable with one request from the
terminal the agent already had. It was handed over instead, several times in one
morning.

## Before asking, answer this

> **Did I try, and what stopped me?**

"I do not have it in front of me" is not an answer. The terminal is in front of
you.

| About to ask for | Do this instead |
|---|---|
| "Can you curl the backend and paste it?" | Run it. `curl -s -o /dev/null -w '%{http_code}'` first, then the body |
| "Is the API up?" | Hit it. A refused connection is a result, not a blocker |
| "What does this endpoint return?" | Request it and read it — the contract run in `../skills/diagnosis/` Phase 0 |
| "Can you check the env var?" | Read the file. `.env` is on disk |
| "Do the tests pass?" | `fw evidence`, and paste the table |
| "Which commit broke it?" | `git log`, `git bisect run` |
| "Can you check the logs?" | Read them, or start the process and watch it |
| "Can you start the dev server?" | Start it, background it, and hit it yourself |

## What genuinely needs the person

These are real, and asking for them is correct — not a failure:

- **A credential you do not hold.** An SSO login, a 2FA prompt, a VPN this
  session is not on.
- **A network you cannot reach.** A host that resolves only from their machine.
  Say what `curl` returned, and from where, before concluding this.
- **A judgment about the screen.** Whether it looks right, reads right, or is
  usable. That is the manual pass — `fw pass`, and the finding goes to
  `fw pass note`.
- **Authorisation.** Anything that writes to a system you were not told to write
  to, costs money, or is hard to undo.
- **Knowledge that exists nowhere on disk.** What the client meant; which of two
  defensible behaviours is the intended one.

## How to ask, when it is one of those

Three sentences, in this order, and then stop:

1. **What you tried and what it returned** — the command and its output, never
   "I could not".
2. **The exact thing to run**, ready to paste, with no editing.
3. **What the answer decides** — which hypothesis it kills. If nothing changes
   with either answer, do not ask at all.

Wrong: *"Could you check whether the backend is returning the id?"*

Right: *"`curl -s $API/orders/8812 | jq .customerId` returns `Connection
refused` from here — the host resolves only on your network. Run that line and
paste the value: `null` confirms hypothesis 2, the backend drops it; a number
moves the fault into our mapper."*

Then keep going on everything that does not depend on the answer. A question is
not a reason to stop working — it is a reason to stop working *on that branch*.

## The same question, one level in

The rule above is about the person. This is the same question aimed at
yourself: **a question the cheap lane can answer goes to the cheap lane.**
Reading twelve files into context to answer one question spends the allowance
the rest of the session needs — measured, not assumed: `skills/delegation`
priced graphify at zero tokens and `fw ask` (agy, on Google's quota) at 40,158
input tokens for 104 KB of files, with about 120 characters landing back here.
Both are cheaper than reading the same material inline, and neither is free —
each answers a narrower class of question than "read the code."

| About to do | Do this instead |
|---|---|
| Read a dozen files to learn a module's shape | `graphify` — structure, zero tokens, seconds |
| Read a pile of text to answer one question about what it means or says | `fw ask "<question>" <paths>` — Google's quota, a short answer back |
| Read one or two files you already need to edit | Just read them. Packing a brief for one file costs more than reading it |
| Answer a question only the whole design in your head can answer | Inline. The brief would have to restate everything the cheap lane lacks |

**What genuinely needs the expensive lane**: anything you must be able to trust
without a spot-check — code you are about to write, a claim that gates a
decision, a security-relevant read. `graphify` gives structure, not meaning;
`fw ask` is a cold agent that over-asserts when its brief runs out of material,
per `skills/delegation`. Its answers arrive with `file:line` for exactly that
reason — check two of them, the way any subagent's report gets checked.

## Why this needs writing down

Asking is safe. Running the command produces a result you can be measured
against; asking produces a wait, and a wait is never wrong. That trade is
invisible to the agent and expensive for the person, which is exactly the kind of
rule that cannot be left to judgment.
