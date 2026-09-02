# Handoff — 2026-09-01, personal machine → work machine

Read this before touching anything. It is written for the agent working on the
**work machine** the morning of 2026-09-02.

There are unpushed commits on the work machine and new work pushed from the
personal machine. **Reconcile git before writing a single line of code.**

---

## PART 1 — GIT. DO THIS FIRST.

### The situation

| Where | State |
|---|---|
| Personal machine | Committed and **pushed** to `origin/main` on 2026-09-01 night |
| Work machine | Has local commits that were **never pushed**. They exist nowhere else. |

The work machine's commits are the only copy in existence. Everything below is
arranged so they cannot be lost.

### What will happen, and why it is not a problem

`origin/main` has moved ahead. A plain `git push` from the work machine **will be
rejected** with `non-fast-forward`. That rejection is git protecting the work,
not an error to route around. The fix is to rebase, never to force.

### The sequence

```bash
cd <framework repo>

# 1. See what is actually here. Do not assume.
git status
git log --oneline origin/main..HEAD     # the local-only commits
git log --oneline HEAD..origin/main     # what came from the other machine

# 2. Safety net BEFORE anything else. Costs nothing, undoes everything.
git branch backup-work-$(date +%Y%m%d)

# 3. If `git status` shows uncommitted changes, commit them. Do not stash and
#    forget; a forgotten stash is how work disappears.
git add -A && git commit -m "<conventional message>"

# 4. Fetch and replay the local commits on top of what arrived.
git fetch origin
git rebase origin/main

# 5. Only when the rebase is clean:
git push
```

### If the rebase conflicts

Expect a conflict in **`bin/fw`**. The personal machine added ~470 lines to that
file (two new commands). If the work-machine fix also touched `bin/fw`, they
collide there.

```bash
# See exactly what disagrees
git status
git diff

# Edit the file, keeping BOTH sides' intent — this is a merge, not a choice
git add bin/fw
git rebase --continue

# To back out entirely and think again:
git rebase --abort          # returns to the pre-rebase state, loses nothing
```

**Check first whether the work-machine fix is already here.** The OpenCode
integration described as "fixed at work" may already be in `origin/main`:
`cmd_link` already links every skill into `$OPENCODE_HOME` (`bin/fw`, the
`link_skills_into "$OPENCODE_HOME" "opencode"` call), and `cmd_doctor` already
counts them per agent. If the local commit does the same thing, the resolution is
to keep what is on `origin/main` and drop the duplicate — but **verify by reading
both diffs**, do not assume.

### Forbidden

- `git push --force` / `--force-with-lease` — the one operation that can actually
  destroy the other machine's work
- `git reset --hard` before the backup branch exists
- `git checkout .` or `git restore .` over uncommitted work you have not read
- Resolving a conflict by deleting the other side because it is longer

If anything is unclear, **stop and ask Walter**. A rebase paused for five minutes
costs nothing. A force push costs a day.

### Verify before moving on

```bash
git status                              # clean
git log --oneline -8                    # both machines' commits present
git log --oneline origin/main..HEAD     # empty
bash -n bin/fw && ./bin/fw              # script parses, usage lists 7 commands
fw doctor                               # install intact
```

Delete the backup branch only after all five pass:
`git branch -D backup-work-<date>`

---

## PART 2 — What was built on 2026-09-01

Two gaps found by using the framework for two days. Both are now closed.

### Gap 1 — a green suite proved nothing

Walter ran `bun run test` on an ERP that an agent had just added specs to.
Everything passed. There was no way to tell whether the tests watched anything.

This is the same failure already recorded in commit `3c64fd2` — *un exit code
cero no prueba que el comando hizo lo suyo* — applied to the test suite itself.

**`fw mutate`** answers it mechanically:

```bash
fw mutate                          # 10 mutations, files with a colocated test first
fw mutate --max 25
fw mutate src/domain/totals.ts
fw mutate --test-cmd 'bun test src/domain'
```

It breaks production code on purpose — `&&`→`||`, `===`→`!==`, `return true`→
`return false` — reruns the suite, and restores the file byte for byte.
`KILLED` = a test noticed. `SURVIVED` = that line is unprotected **with a green
check over it**, which is worse than untested, because untested code does not lie.

Safeguards, all deliberate:
- refuses to run on a dirty working tree (it rewrites source in place)
- refuses to run on a red baseline (every mutant would read as killed)
- `trap ... EXIT INT TERM` restores on Ctrl-C
- `cmp -s` confirms the edit changed bytes; a `sed` that matched nothing is not
  counted as a run
- exits non-zero if any mutant survives

Package manager comes from the existing `runner()`: bun / pnpm / npm.

**Verified by running it**, not by describing it. A fixture with two files: one
with real tests (5/5 mutants KILLED) and one carrying the exact tautology from
`skills/testing/SKILL.md` (`expect(invoiceTotal(l)).toBe(round2(sumLines(l)))`),
which SURVIVED. Score 83%, verdict FAIL. Detection confirmed on all three
package managers.

### Gap 2 — user stories only ever existed in chat

Walter noticed the agent returned user stories as chat messages that vanished
with the session.

**The agent was not disobeying the framework. It was obeying it.**
`skills/requirements/SKILL.md` said, literally: *"This list is the deliverable to
send back over chat."* And `skills/epic/SKILL.md` defined the epic format without
ever saying where the file lives. With no place to write, it wrote to chat. The
gap was in the framework.

**`fw product`**:

```bash
fw product init                                  # once per project
fw product epic checkout "Split payment"
fw product hu checkout "Reject an expired card"
fw product                                       # what exists, where each story stands
```

```
.fw/product/
├── epics/checkout.md          boundary, standing decisions, slices table
└── criteria/checkout-01.md    story, EARS criteria, gaps, assumptions, evidence
```

Three design decisions worth not re-litigating:

1. **Under `.fw/`** — already the framework's standing decision
   (`skills/epic/example.md`), already in the global gitignore, already used by
   `fw install --shared` and `fw evidence`. No new namespace was invented.
2. **Flat, not nested.** Not `epics/checkout/stories/01.md`. The epic's `## Slices`
   table already lists what belongs to it; nesting records that same fact twice
   and the two drift the first time a slice is renamed. `fw product hu` appends
   the row so the table cannot fall behind.
3. **No `backend/` and `frontend/` split.** A story is a unit of business, not of
   deployment. If it crosses layers, the criterion says which layer proves it —
   that is the Evidence Gate's job.

Story numbering comes from the files on disk (max + 1), never from the table, so
a hand-edited table cannot make two stories claim one id and a deleted story
never has its number reused.

**Verified by running it** in a real git repo: `git status --porcelain` empty,
`git check-ignore -v` resolving to the global ignore. Edge cases: duplicate epic
refused, unknown epic refused, invalid slug refused, orphan story exits non-zero.

### Wiring — the part that makes it live

Two commands nobody invokes are dead code. The skills now point at them:

| File | Change |
|---|---|
| `skills/testing/SKILL.md` | `### Proving it mechanically — fw mutate`, after the tautology section |
| `skills/verification-standards/SKILL.md` | hard rule + gate row: criterion claimed covered by a pre-existing test whose mutant survived = `FAIL — UNVERIFIED` |
| `skills/requirements/SKILL.md` | `## Where this lives` — replaces the "deliverable over chat" line that caused Gap 2 |
| `skills/epic/SKILL.md` | `## Where it lives` |

Docs: `docs/mutation-testing.md`, `docs/product-artifacts.md`.
Templates: `templates/product/{epic.md,hu.md}`.
`cmd_doctor` now fails if `.fw/` is tracked in a repository.

---

## PART 3 — Open questions

- **The ERP has never been mutation-tested.** Its suite is green and unaudited.
  Run `fw mutate --max 5` on the critical path. Start narrow: five survivors that
  get acted on beat four hundred that get scrolled past.
- **An agent's claim about itself is not evidence.** Asked whether it used this
  framework, another agent said yes and credited it for prioritising unit tests.
  Both parts fail verification: `skills/testing/SKILL.md` *requires* announcing
  the resolved Mode Resolution row in one line, and it never did; and the Evidence
  Gate says a unit test cannot see a backend's contract drift, so blanket-first
  unit tests on an ERP is what this framework tells you **not** to do — it is the
  generic default wearing the framework's label. Verify behaviour, not
  self-report. Same rule as `3c64fd2`.
- **Is the framework meant to be on all the time?** No. `skills/epic/SKILL.md`
  has a `## When NOT to write one` section that ends *"An epic that is never read
  is pure cost."* It activates by threshold. To check whether a skill actually
  loaded, ask the agent which skills it loaded and why, before the work starts —
  `fw doctor` verifies installation, which is a different question from runtime.

---

## Constraints

- **Never commit or push without Walter's explicit say-so.** This file was
  committed because he asked for it directly.
- No `Co-Authored-By` and no AI attribution in commit messages. Conventional
  commits only.
- Technical artifacts in English; conversation with Walter in Spanish.
- Delete this file once both machines are reconciled and the work above is
  understood. It is a handoff, not documentation — the documentation is in
  `docs/`.
