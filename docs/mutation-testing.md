# Mutation testing — proving the suite watches something

## The problem this solves

`bun run test` exits zero. Four tests pass. Nothing is proven yet.

A green suite is evidence that the tests **ran**. It is not evidence that they
**observe** anything. A test can call production code, assert a specific value,
read well in review, and still stay green while you delete the logic under it.

This is the same failure recorded in commit `3c64fd2` — *un exit code cero no
prueba que el comando hizo lo suyo* — applied to the test suite itself. `ln -s`
returned zero while writing a copy. `fw doctor` returned zero while printing
failures. A test suite returns zero while watching nothing. Three shapes of one
mistake: **trusting the exit code instead of the result.**

The question `fw mutate` answers is the only one that settles it:

> If I break the production code on purpose, does the suite notice?

## How it works

1. Run the suite once. It **must** be green — against a red baseline every
   mutant reads as killed by a failure that was already there.
2. Pick a source file and apply one small mutation: `&&` becomes `||`, `===`
   becomes `!==`, `return true` becomes `return false`.
3. Run the suite again.
4. Restore the file, byte for byte.
5. Repeat.

Three outcomes, and only one of them is good news:

| Result | Meaning |
|---|---|
| **KILLED** | The suite went red on an assertion. A test was watching that line. |
| **SURVIVED** | The suite stayed green. That line is unprotected, with a green check over it. |
| **NOT VIABLE** | The mutant never compiled, so the suite never saw it. No evidence either way. |

A survivor is worse than an untested line, because an untested line does not lie
to you.

### Why NOT VIABLE exists

A non-zero exit is not proof that a test noticed. In a typed language a mutation
can be rejected by the compiler — `s !== 'todas'` becomes `s === 'todas'` on a
narrowed union and `tsc` refuses it — and the run exits non-zero having executed
**no tests at all**. Counting that as KILLED inflates the score precisely where
the type system is strongest, which turns a high score into a lie in exactly the
codebases that look safest.

So the run's output is read, not discarded. A mutant is judged NOT VIABLE only
when a build signature is present *and* the runner never printed a test summary;
if tests ran, a real failure wins. Non-viable mutants are listed in the table and
excluded from the score:

```
score = KILLED / (KILLED + SURVIVED)
```

That the compiler caught the edit is real protection — it is just not evidence
about your suite, which is the only question this command asks.

## Usage

```bash
fw mutate                          # 10 mutations, files with a colocated test first
fw mutate --max 25                 # more mutations, one full suite run each
fw mutate --per-file 8             # allow more mutants in a single file (default 3)
fw mutate src/domain/totals.ts     # one file
fw mutate --test-cmd 'bun test src/domain'   # narrow the suite
```

Every occurrence of an operator is a candidate, not only the first one in the
file. Duplicated logic — the same guard copied into a second method — is exactly
where a hole hides, and a first-match-only sweep reports that file as clean.

`--per-file` caps how many mutants one file may take from the `--max` budget so a
single large file cannot consume the whole run. Raise it when you are auditing
one file on purpose.

The package manager is detected the same way `fw evidence` detects it: `bun.lock`
means bun, `pnpm-lock.yaml` means pnpm, otherwise npm. The test command is
`<manager> run test`, or `bun test` when bun is present with no `test` script.

Exit code is non-zero if any mutant survives, so it composes into a pipeline the
same way `fw evidence` does.

## What it will not do

**It will not run on a dirty working tree.** The tool rewrites source files in
place and restores them. On a clean tree the worst case is `git checkout`. On a
dirty tree the worst case is losing work that exists nowhere else. It refuses.

**It will not judge the tests for you.** It reports which lines you can break
with the suite green. Whether that matters is a decision about the criterion,
not about the tool. See the Evidence Gate in `../skills/testing/SKILL.md`.

**It is not a coverage tool.** Coverage says a line was executed. Mutation says
a line was *observed*. A file can sit at 100% coverage and lose every mutant —
that is exactly what the tautology in `skills/testing/SKILL.md` produces.

## Reading a survivor

A survivor is a finding, not a verdict. Three causes, in the order worth checking:

1. **The assertion is a tautology.** The expected value is built from the code's
   own helpers, so mutating the code moves both sides of the comparison and they
   stay equal. `expect(invoiceTotal(l)).toBe(round2(sumLines(l)))` survives every
   mutant inside `round2` and `sumLines`.
2. **The seam is wrong.** The test asserts on something the mutation does not
   reach — a rendered class name, a call count, an internal helper.
3. **Nothing tests it.** Legitimate, and now visible. Decide with the Evidence
   Gate whether this criterion is worth proving before writing anything.

## Reading a NOT VIABLE

It means the edit never became a running program. Usually the type system
narrowed something and the mutation contradicted it. There is nothing to fix and
nothing to celebrate — it is a mutant that could not be asked the question.

If a whole run comes back non-viable, the file is decided at compile time rather
than at runtime, and mutation testing has little to say about it. Point the
command at code whose branches are chosen from data instead.

## Why this is mechanical and not a judgment call

An agent that writes the tests and then rules on whether its own tests are any
good has a conflict of interest. The mutation is a script: it edits bytes, runs
a command, reads what the run printed, and restores the file. Nothing about the
verdict depends on anyone's opinion of the work.

It reads the output rather than only the exit code for the same reason the rest
of this document exists. An exit code says the process failed; it does not say
a test was watching. Those are different claims, and only one of them is the
question.

This is the same reason `fw evidence` pastes its table verbatim instead of
summarising it. *A run is evidence. A description of a run is not.*

## Cost

Every mutation is a full suite run. Ten mutations against a 30-second suite is
five minutes. The forecast is printed before the first mutant so the cost is a
decision, not a surprise.

On a large codebase with no testing culture, start narrow — the critical path,
one file — instead of a full sweep whose report nobody reads. Five survivors you
act on beat four hundred you scroll past.

## References

- `../skills/testing/SKILL.md` — the Evidence Gate, the seam, and the tautology
  that survives review
- `../skills/verification-standards/SKILL.md` — what counts as proof of done
- `../bin/fw` — `cmd_mutate`
