#!/usr/bin/env bash
# Tests for `fw evidence`. It signs the table people paste into a verification
# report, so its two failure modes are the expensive kind: a check that silently
# never ran, and a green row over a run that did not do what it claims.
#
# bin/fw is CRLF and a CRLF script does not parse under Linux bash, so each case
# runs a normalised copy.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# FW_EVIDENCE_BIN points the suite at a deliberately broken copy, which is how
# this suite is proved able to go red before its green is believed.
FW_SRC="${FW_EVIDENCE_BIN:-$FW_ROOT/bin/fw}"
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

# An empty bun.lock pins the runner, so no case depends on which package
# manager happens to be installed on the machine running this suite.
fixture() {
  local dir; dir="$(mktemp -d)"
  : > "$dir/bun.lock"
  printf '%s' "$dir"
}
scripts() {
  local dir="$1"; shift
  local body="" s
  for s in "$@"; do body="$body${body:+,}\"$s\": \"./$s.sh\""; done
  printf '{ "name": "f", "version": "1.0.0", "scripts": { %s } }\n' "$body" > "$dir/package.json"
}
script() { printf '#!/bin/sh\n%s\n' "$2" > "$1/$3.sh"; chmod +x "$1/$3.sh"; }
run()    { ( cd "$1" && shift && "$FW_BIN" evidence "$@" 2>&1 ); }
rc_of()  { ( cd "$1" && shift && "$FW_BIN" evidence "$@" >/dev/null 2>&1 ); printf '%s' "$?"; }

green='echo "Tests  1 passed (1)"'

printf '\nfw evidence\n'

# --- a missing linter is a row, not a terminal-only warning ------------------
# A table that simply omits `lint` is indistinguishable from a project whose
# lint passed, and the table is the part that gets pasted.
d=$(fixture); scripts "$d" typecheck build test
script "$d" 'echo ok' typecheck; script "$d" 'echo ok' build; script "$d" "$green" test
out=$(run "$d")
check "an absent linter appears in the pasted table" "$out" "| lint | — | — | **NOT RUN** — no lint script in package.json |"
check "and the verdict says the run claims less than PASS" "$out" "**Verdict: PASS WITH WARNINGS**"
check "and the gap count is explained" "$out" "check(s) could not run"
check "but it does not fail the run" "$(rc_of "$d")" "0"

# --- every check present and green is still plain PASS ----------------------
d=$(fixture); scripts "$d" typecheck lint build test
for s in typecheck lint build; do script "$d" 'echo ok' "$s"; done
script "$d" "$green" test
mkdir -p "$d/.fw/contracts"; printf 'console.log("contracts ok")\n' > "$d/.fw/contracts/verify.ts"
out=$(run "$d")
check "a complete run is PASS" "$out" "**Verdict: PASS**"
refute "with no gap rows" "$out" "NOT RUN"
refute "and no warnings verdict" "$out" "PASS WITH WARNINGS"

# --- absent contracts are listed but do not lower the verdict ---------------
# Contracts are an opt-in artifact. Counting their absence as a gap would park
# every frontend project at PASS WITH WARNINGS forever and the signal would
# stop meaning anything.
d=$(fixture); scripts "$d" typecheck lint build test
for s in typecheck lint build; do script "$d" 'echo ok' "$s"; done
script "$d" "$green" test
out=$(run "$d")
check "absent contracts are still visible in the table" "$out" "| contracts | — | — | **NOT RUN** — no .fw/contracts/verify.ts |"
check "and the verdict stays PASS" "$out" "**Verdict: PASS**"
refute "not PASS WITH WARNINGS" "$out" "PASS WITH WARNINGS"

# --- an unhandled error is a failure even when the runner exits 0 -----------
# `Tests 297 passed` beside `Errors 1 error` means an assertion held while
# something threw outside it. Whether the runner also exits non-zero is that
# runner's choice, not evidence.
d=$(fixture); scripts "$d" typecheck lint build test
for s in typecheck lint build; do script "$d" 'echo ok' "$s"; done
script "$d" 'echo "Tests  297 passed (297)"; echo "     Errors  1 error"; exit 0' test
out=$(run "$d")
check "the error count travels with the pass count" "$out" "297 passed (297), 1 unhandled error(s)"
check "and the run is FAIL despite exit 0" "$out" "**Verdict: FAIL**"
check "and the process exits non-zero" "$(rc_of "$d")" "1"
refute "the row is never reported as clean" "$out" "✓ tests"

# --- a clean test line is left alone ----------------------------------------
d=$(fixture); scripts "$d" typecheck lint build test
for s in typecheck lint build; do script "$d" 'echo ok' "$s"; done
script "$d" 'echo "Tests  12 passed (12)"' test
out=$(run "$d")
refute "a run with no error line is not annotated" "$out" "unhandled error"
check "and stays PASS" "$out" "**Verdict: PASS**"

# --- --no-build is marked in the report, not only on the terminal -----------
# The verification standard says --no-build has no place in a report. That is
# only enforceable if the report says it was used.
d=$(fixture); scripts "$d" typecheck lint build test
for s in typecheck lint build; do script "$d" 'echo ok' "$s"; done
script "$d" "$green" test
out=$(run "$d" --no-build)
check "a skipped build is named in the table" "$out" "**NOT RUN** — skipped by --no-build"
check "and lowers the verdict" "$out" "**Verdict: PASS WITH WARNINGS**"

# --- a real failure outranks the gaps ---------------------------------------
d=$(fixture); scripts "$d" typecheck test
script "$d" 'echo "src/a.ts(1,1): error TS2322: nope"; exit 2' typecheck
script "$d" "$green" test
out=$(run "$d")
check "a failing check is FAIL, not PASS WITH WARNINGS" "$out" "**Verdict: FAIL**"
check "and the type errors are counted" "$out" "1 type error(s)"

rm -f "$FW_BIN"
printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
