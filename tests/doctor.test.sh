#!/usr/bin/env bash
# Tests for the install checks in `fw doctor`. Its whole job is to end silent
# failures of the install, so a check it does not make is a failure mode that
# stays invisible — the exact shape it exists to remove.
#
# bin/fw is CRLF and a CRLF script does not parse under Linux bash, so each case
# runs a normalised copy.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# FW_DOCTOR_BIN points the suite at a deliberately broken copy, which is how
# this suite is proved able to go red before its green is believed.
FW_SRC="${FW_DOCTOR_BIN:-$FW_ROOT/bin/fw}"
# fw derives FW_ROOT from its own path, and doctor compares the repository's
# rules against the install. A bare copy in /tmp would therefore find no rules
# to compare and report a clean install for every case — so the copy gets the
# repository's shape, with rules/, hooks/ and skills/ pointing at the real ones.
# Leaving skills/ out makes doctor stop before its summary, which reads exactly
# like a tool bug and is really an incomplete fixture.
FW_HOME="$(mktemp -d)"; mkdir -p "$FW_HOME/bin"
FW_BIN="$FW_HOME/bin/fw"
tr -d '\r' < "$FW_SRC" > "$FW_BIN"; chmod +x "$FW_BIN"
ln -s "$FW_ROOT/rules" "$FW_HOME/rules"
ln -s "$FW_ROOT/hooks" "$FW_HOME/hooks"
ln -s "$FW_ROOT/skills" "$FW_HOME/skills"

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

# A home whose rules/ is linked from the real repository, so what is under test
# is the comparison between the two and not a hand-built fixture that could
# drift from either.
home_with_all_rules() {
  local h; h="$(mktemp -d)"
  mkdir -p "$h/rules"
  local r
  for r in "$FW_ROOT"/rules/*.md; do
    ln -s "$r" "$h/rules/fw-$(basename "$r")"
  done
  printf '%s' "$h"
}
# ANSI is stripped so an assertion can name the marker a line carries. Without
# it "rule not linked: x" matches whether the line was rendered as a failure or
# as an informational warning, and a check that cannot tell those apart passes
# for a tool that stopped reporting the problem.
doctor() { CLAUDE_CONFIG_DIR="$1" "$FW_BIN" doctor 2>&1 | sed 's/\x1b\[[0-9;]*m//g'; }

printf '\nfw doctor\n'

# --- a fully linked install reports no unlinked rule -------------------------
h=$(home_with_all_rules)
out=$(doctor "$h")
refute "a complete install reports nothing unlinked" "$out" "rule not linked"
check "and the rules it did link are named" "$out" "rule linked: fw-testing.md"

# --- a rule added since the last link is a problem, not silence --------------
# This is the failure this check exists for: the rule is in the repository, the
# install predates it, and nothing about the resulting session looks different
# from one where the rule simply did not apply.
h=$(home_with_all_rules)
rm -f "$h/rules/fw-foreign-source.md"
out=$(doctor "$h")
check "a rule present in the repo but not linked is reported" "$out" "✗ rule not linked: fw-foreign-source.md"
check "and the fix is named" "$out" "run 'fw link'"

# --- every repository rule is covered, not just a known list -----------------
# Hardcoding names here would reproduce the bug: a rule added later would be
# unchecked by both the tool and this test.
h=$(home_with_all_rules)
missing=""
for r in "$FW_ROOT"/rules/*.md; do
  b="fw-$(basename "$r")"
  rm -f "$h/rules/$b"
  missing="$missing$b "
done
# One rule must stay linked or doctor reports "no framework rules linked"
# instead, which is a different message for a different situation.
ln -s "$FW_ROOT/rules/conventions.md" "$h/rules/fw-conventions.md"
out=$(doctor "$h")
for b in $missing; do
  [ "$b" = "fw-conventions.md" ] && continue
  check "$b is checked" "$out" "✗ rule not linked: $b"
done

# --- an install with nothing linked keeps its own message --------------------
h="$(mktemp -d)"; mkdir -p "$h/rules"
out=$(doctor "$h")
check "an empty install says so" "$out" "no framework rules linked"
refute "and does not enumerate every rule as unlinked" "$out" "rule not linked"

# --- a broken symlink is still reported --------------------------------------
h=$(home_with_all_rules)
rm -f "$h/rules/fw-testing.md"
ln -s "$FW_ROOT/rules/does-not-exist.md" "$h/rules/fw-testing.md"
out=$(doctor "$h")
check "a dangling symlink is reported" "$out" "broken symlink"

rm -rf "$FW_HOME"
printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
