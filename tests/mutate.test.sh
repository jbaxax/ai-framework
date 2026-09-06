#!/usr/bin/env bash
# Tests for `fw mutate`. It had three bugs, two of which produced false verdicts
# that looked rigorous, so the tool that exists to distrust green checks is the
# one that most needs a check of its own.
#
# bin/fw is CRLF and a CRLF script does not parse under Linux bash, so each case
# runs a normalised copy. What is under test is cmd_mutate's classification, not
# the file's line endings.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# FW_MUTATE_BIN points the suite at a deliberately broken copy, which is how
# this suite is proved able to go red before its green is believed.
FW_SRC="${FW_MUTATE_BIN:-$FW_ROOT/bin/fw}"
FW_BIN="$(mktemp)"; tr -d '\r' < "$FW_SRC" > "$FW_BIN"; chmod +x "$FW_BIN"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
ko()   { FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n' "$1"; }
check() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then ok "$label"
  else ko "$label"; printf '      expected to find: %s\n' "$needle"; fi
}
refute() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    ko "$label"; printf '      should NOT contain: %s\n' "$needle"
  else ok "$label"; fi
}

# A fixture is a committed git repo, because mutate refuses a dirty tree.
fixture() {
  local dir; dir="$(mktemp -d)"
  printf '{"name":"fixture","version":"1.0.0"}\n' > "$dir/package.json"
  mkdir -p "$dir/src"
  git -C "$dir" init -q
  git -C "$dir" config user.email t@t.t
  git -C "$dir" config user.name t
  printf '%s' "$dir"
}
commit() { git -C "$1" add -A >/dev/null 2>&1; git -C "$1" commit -qm f >/dev/null 2>&1; }
run()    { ( cd "$1" && shift && "$FW_BIN" mutate "$@" 2>&1 ); }

printf '\nfw mutate\n'

# --- KILLED: the suite notices the mutant ------------------------------------
d=$(fixture)
printf 'export const a = (n: number): boolean => n >= 10;\n' > "$d/src/rule.ts"
cat > "$d/t.sh" <<'T'
#!/bin/sh
echo "Tests 1 passed"
grep -q ">= 10" src/rule.ts && exit 0
exit 1
T
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --max 5)
check "a watched line reports KILLED" "$out" "KILLED"
refute "and is not reported as SURVIVED" "$out" "SURVIVED"

# --- SURVIVED: the suite is green whatever the code says ---------------------
d=$(fixture)
printf 'export const a = (n: number): boolean => n >= 10;\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --max 5)
check "an unwatched line reports SURVIVED" "$out" "SURVIVED"
check "and the verdict is FAIL" "$out" "Verdict: FAIL"

# --- NOT VIABLE: retro bug 1, a mutant the compiler rejected -----------------
# Exit 1 with a compile signature and no test summary. Judging by exit code
# alone scores this KILLED and inflates the result exactly where types are
# strongest.
d=$(fixture)
printf 'export const a = (n: number): boolean => n >= 10;\n' > "$d/src/rule.ts"
cat > "$d/t.sh" <<'T'
#!/bin/sh
if grep -q ">= 10" src/rule.ts; then echo "Tests 1 passed"; exit 0; fi
echo "src/rule.ts(1,5): error TS2322: Type mismatch"
exit 1
T
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --max 5)
check "a mutant that never compiled reports NOT VIABLE" "$out" "NOT VIABLE"
refute "and is never counted as KILLED" "$out" "KILLED"
check "and the run is reported as no evidence" "$out" "rejected by the compiler"
refute "not as operators that matched nothing" "$out" "matched no behavioral line"

# --- a real failure still wins over a compile signature ----------------------
# Both signals present: tests ran AND the output mentions a compile error. The
# suite reported, so the mutant died for real.
d=$(fixture)
printf 'export const a = (n: number): boolean => n >= 10;\n' > "$d/src/rule.ts"
cat > "$d/t.sh" <<'T'
#!/bin/sh
echo "error TS2322: something"
echo "Tests 1 failed"
grep -q ">= 10" src/rule.ts && exit 0
exit 1
T
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --max 5)
check "a reported test run outranks a compile signature" "$out" "KILLED"

# --- retro bug 2: every occurrence, not only the first -----------------------
d=$(fixture)
printf 'export const a = (n: number): boolean => n >= 10;\nexport const b = (n: number): boolean => n >= 20;\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --max 10 --per-file 3)
check "the second occurrence is mutated too" "$out" "src/rule.ts:2"
check "the first one as well" "$out" "src/rule.ts:1"

# --- --per-file caps one file's share of the budget --------------------------
d=$(fixture)
printf 'export const a = (n: number): boolean => n >= 10;\nexport const b = (n: number): boolean => n >= 20;\nexport const c = (n: number): boolean => n >= 30;\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --max 10 --per-file 2)
check "--per-file 2 keeps one file from eating the budget" "$out" "survived 2"
refute "and the third occurrence is left alone" "$out" "src/rule.ts:3"

# --- retro bug 3: a CRLF file must not produce a false verdict ---------------
# sed -i rewrites CRLF as LF, so comparing whole files reports "changed" for an
# edit that matched nothing, and the run scores unmutated code.
d=$(fixture)
printf 'export const a = (n: number): boolean => n.length;\r\nexport const b = 2;\r\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --max 5)
refute "a CRLF file with no operator match reports no mutant" "$out" "SURVIVED"
check "and says nothing was mutated instead" "$out" "nothing was mutated"

# --- a red baseline is refused ----------------------------------------------
d=$(fixture)
printf 'export const a = (n: number): boolean => n >= 10;\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 failed"\nexit 1\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh)
check "a red suite is refused before mutating" "$out" "suite is red before mutating"

# --- a dirty tree is refused ------------------------------------------------
d=$(fixture)
printf 'export const a = (n: number): boolean => n >= 10;\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
printf 'dirty\n' > "$d/src/extra.ts"
out=$(run "$d" --test-cmd ./t.sh)
check "a dirty working tree is refused" "$out" "working tree is dirty"

# --- --replace: the pair is mandatory ----------------------------------------
d=$(fixture)
printf 'export const a = (): boolean => can("p.delete");\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --replace 'can("p.delete")')
check "--replace without --with is refused" "$out" "--replace needs --with"
out=$(run "$d" --test-cmd ./t.sh --with 'can("p.update")')
check "--with without --replace is refused" "$out" "--with needs --replace"
out=$(run "$d" --test-cmd ./t.sh --replace 'x' --with 'x')
check "a replacement identical to the original is refused" "$out" "the same string"

# --- --replace KILLED: the spec watches the exact gate -----------------------
# The edit an operator flip cannot express: both sides are the same call.
d=$(fixture)
printf 'export const a = (): boolean => can("p.delete");\n' > "$d/src/rule.ts"
cat > "$d/t.sh" <<'T'
#!/bin/sh
echo "Tests 1 passed"
grep -q 'can("p.delete")' src/rule.ts && exit 0
exit 1
T
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --replace 'can("p.delete")' --with 'can("p.update")')
check "a watched gate reports KILLED" "$out" "KILLED"
check "and the mutation is named in full" "$out" 'can("p.delete")` to `can("p.update")'
check "and the mutated file is restored afterwards" "$(cat "$d/src/rule.ts")" 'can("p.delete")'
check "leaving no change behind" "$(git -C "$d" status --porcelain | wc -l)" "0"

# --- --replace SURVIVED: nothing notices the gate changing -------------------
d=$(fixture)
printf 'export const a = (): boolean => can("p.delete");\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --replace 'can("p.delete")' --with 'can("p.update")')
check "an unwatched gate reports SURVIVED" "$out" "SURVIVED"
check "and the verdict is FAIL" "$out" "Verdict: FAIL"

# --- --replace sweeps every occurrence, not the first ------------------------
# The duplicated gate is the one that hides, so the default budget is per
# occurrence and not the operator sweep's 3.
d=$(fixture)
printf 'const a = can("p.delete");\nconst b = can("p.delete");\nconst c = can("p.delete");\nconst e = can("p.delete");\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --replace 'can("p.delete")' --with 'can("p.update")')
check "the fourth occurrence is mutated too" "$out" "src/rule.ts:4"
check "and all four are counted" "$out" "survived 4"

# --- the forecast is counted, not the flag default ---------------------------
# --replace budgets 50. Announcing fifty suite runs for a string that occurs
# twice is a cost forecast the caller cannot use.
d=$(fixture)
printf 'const a = can("p.delete");\nconst b = can("p.delete");\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --replace 'can("p.delete")' --with 'can("p.update")')
check "the occurrence count is reported" "$out" "2 line(s) contain the string"
check "and the forecast uses it" "$out" "up to 2 mutation(s)"
refute "not the budget default" "$out" "up to 50 mutation(s)"

# --- a string that is not there is not a pass --------------------------------
d=$(fixture)
printf 'const a = can("p.delete");\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --replace 'can("nope.delete")' --with 'true')
check "a string that never appears is reported as such" "$out" "the string never appears"
refute "and is never a verdict" "$out" "Verdict: PASS"

# --- occurrences that carry no behavior are named, not counted ---------------
d=$(fixture)
printf '// can("p.delete") is checked elsewhere\nimport { can } from "./can";\nexport const a = 1;\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --replace 'can(' --with 'may(')
check "matches on comment and import lines are reported as behaviourless" "$out" "carries no behavior"
refute "and are not confused with a string that is absent" "$out" "never appears"

# --- templates are searched in replace mode ----------------------------------
# An Angular gate lives in the .html. A sweep of .ts only would call that file
# clean without opening it.
d=$(fixture)
printf 'export const a = 1;\n' > "$d/src/rule.ts"
printf '@if (can("p.delete")) { <button>Borrar</button> }\n' > "$d/src/rule.html"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --replace 'can("p.delete")' --with 'true')
check "a gate in a template is mutated" "$out" "src/rule.html:1"

refute "and templates stay out of the operator sweep" "$(run "$d" --test-cmd ./t.sh --max 5)" "src/rule.html"

# --- --spec is appended to the test command ----------------------------------
d=$(fixture)
printf 'export const a = (n: number): boolean => n >= 10;\n' > "$d/src/rule.ts"
cat > "$d/t.sh" <<'T'
#!/bin/sh
[ "$1" = "src/rule.spec.ts" ] || { echo "no spec argument reached the runner"; exit 1; }
echo "Tests 1 passed"
exit 0
T
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --spec src/rule.spec.ts --max 2)
check "--spec reaches the runner" "$out" "test command: ./t.sh src/rule.spec.ts"
refute "and the baseline is not red" "$out" "suite is red"

# --- a scoped command that ran nothing is refused ----------------------------
# Exit 0 from a runner that matched no spec file is byte-identical to a passing
# suite, and every mutant would then SURVIVE against a suite that never ran.
d=$(fixture)
printf 'export const a = (n: number): boolean => n >= 10;\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "No test files found, exiting"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --spec src/nowhere.spec.ts --max 2)
check "a scoped command with no test run is refused" "$out" "without reporting a test run"
refute "and no mutant is scored against it" "$out" "SURVIVED"

# --- a replacement containing @@ is not cut in half --------------------------
# The operator table packs from/to/label with @@. A caller's string must never
# be parsed by that convention.
d=$(fixture)
printf 'const a = "x@@y";\n' > "$d/src/rule.ts"
printf '#!/bin/sh\necho "Tests 1 passed"\nexit 0\n' > "$d/t.sh"
chmod +x "$d/t.sh"; commit "$d"
out=$(run "$d" --test-cmd ./t.sh --replace 'x@@y' --with 'z@@w')
check "the @@ in the original survives the label" "$out" 'x@@y` to `z@@w'
check "and the line is mutated" "$out" "src/rule.ts:1"

rm -f "$FW_BIN"
printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
