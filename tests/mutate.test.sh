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

rm -f "$FW_BIN"
printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
