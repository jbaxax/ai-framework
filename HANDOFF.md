# Handoff — 2026-09-09

For the next session, on any machine. Written because the framework changed a
lot in one day and none of it is reachable until the machine is linked.

## Do this first, once per machine

```bash
cd <this repo> && git pull
fw doctor          # lists exactly what is missing
fw link            # only if doctor asked for it
```

`fw doctor` is silent when everything is fine. It is not a ritual — pulling
updates every rule and skill that was **already** linked, because the symlink
points at the file in this repo. What it cannot do is create links for things
that did not exist before, and this day added four.

If `fw` itself does not run, the file is CRLF again — see the note at the end.

## What changed on 2026-09-09

One rule, from a field observation: over a morning of debugging a backend known
to ship stale docs and null ids, the agent handed the person `curl` after `curl`
it could have run itself. Grepping `rules/`, `skills/` and `docs/` found the
cause — **nothing in the framework said who executes a check.**

| Now exists | What it does |
|---|---|
| `rules/execution.md` | A check you can run, you run. The table of what is genuinely worth a round trip to the person, and the three-sentence shape of the ask when it is |

`skills/diagnosis/` Phase 1 now points at it: the loop is built *and run* by the
agent, and asking for a `curl` it could reach is how ten minutes becomes a
morning.

## What changed on 2026-09-06

Eleven observations from the field retros of 09-04 and 09-05, all closed.

| Now exists | What it does |
|---|---|
| `fw mutate --replace X --with Y --spec S` | Mutates a named string, for the edit an operator flip cannot express: `can('a.delete')` → `can('a.update')`. Searches templates too |
| `fw evidence` NOT RUN rows | A check the project does not have is a row in the pasted table, never a silent omission. Third verdict: `PASS WITH WARNINGS` |
| `fw evidence` audit row | Runs `.fw/audit/tests/run.sh` — the audit's **suite**, never the audit |
| `fw pass` | The manual pass: what changed, which screens, what only a person can check |
| `fw pass note "…" --missed "…"` | A finding while looking at it. The second field is what the retro is built from |
| `fw product list` staleness | A story left at `draft` while its code shipped |
| `fw backlog` | Folds wrapped items, and says how many commits landed since the list moved |
| `fw doctor` | Reports rules present in the repo but not linked on this machine |
| `rules/foreign-source.md` | Source you do not deploy is a hypothesis; its running instance is the evidence |
| `skills/gating` | Resolve who reaches a control before calling it ungated |
| `skills/delegation` | Delegate by what it costs to verify the answer, not by how many files |
| `hooks/skill-router.py` | Every prompt is matched against the installed skills' triggers, and the matches are named |

Full reasoning: `docs/manual-pass.md`, `docs/audit-tools.md`,
`docs/breaking-checks.md`, `docs/foreign-systems.md`.

## The working day, in five lines

```bash
fw doctor                      # once, after pulling
fw pass                        # before opening the app: where to look
fw pass note "<seen>" --missed "<what should have caught it>"
fw evidence                    # before calling anything done
fw pass log                    # end of day — the retro is built from this
```

`--missed` empty is not a missing field. It records `nothing exists — framework
gap`, which is the finding: nothing was watching that class of thing.

## Waiting on a decision

1. **`machine/*.json` drift.** `fw doctor` reports it. Refreshing copies live
   personal config into a committed repo. Copy it, or take the snapshot out of
   git?
2. **Engram `topic_key` is an upsert** and `mem_save` does not say what it
   replaced — six observations were lost in one session. Not this repo. Report
   upstream, or work around it here?
3. **How long `fw evidence` takes on facnet.** The Angular project in this repo
   is a scaffold and its 2s does not transfer. That number sets the boundary
   between the cheap check a `Stop` hook can run every turn and the full one.
4. **Model routing is user config, not framework.** Verified against the
   installed binary `2.1.267`: `opusplan` exists as a `/model` value — Opus in
   plan mode, Sonnet outside it — and `CLAUDE_CODE_SUBAGENT_MODEL` exists to pin
   every subagent. The 18 agents in `~/.claude/agents/` already route per phase
   (`sdd-propose`/`sdd-design` opus, `sdd-apply` and the reviewers sonnet,
   `sdd-archive` haiku). Open question: does `fw doctor` start reporting a flat
   `"model": "opus"` in `settings.json` as a finding, or does that stay a
   per-machine choice the framework never touches?

## Known, measured, not yet built

The `Stop` hook fires and receives `cwd`, `transcript_path`, `permission_mode`
and `stop_hook_active`. `additionalContext` does **not** reach the model on a
normal stop — the conversation ends, so there is no call to inject into.
`systemMessage` **does** reach the user, rendered as `Stop says: …`. So the hook
can report the verification to the person even when it cannot report it to the
agent. Design and remaining questions are in `~/backlog.md`.

## If `fw` stops working on Linux

`bin/fw` was CRLF for months, which made `#!/usr/bin/env bash\r` look for a
binary named `bash\r`. Every command failed, including `fw link` — which is why
two rules were never installed on the Fedora machine. `.gitattributes` now pins
it to LF. If it comes back, an editor wrote it on Windows with the wrong config.
