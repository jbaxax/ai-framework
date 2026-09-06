#!/usr/bin/env bash
# Tests for `fw pass`. Its whole value is that the list comes from the diff
# rather than from someone's memory, so a list that quietly omits a changed
# template is worse than no list: it reads as "nothing else to look at".
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW_SRC="${FW_PASS_BIN:-$FW_ROOT/bin/fw}"
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

fixture() {
  local d; d="$(mktemp -d)"
  git -C "$d" init -q
  git -C "$d" config user.email t@t.t
  git -C "$d" config user.name t
  mkdir -p "$d/src/app/features/cobros/presentation" "$d/src/app/features/cobros/application"
  printf 'base\n' > "$d/README.md"
  git -C "$d" add -A >/dev/null 2>&1; git -C "$d" commit -qm base >/dev/null 2>&1
  printf '%s' "$d"
}
run() { ( cd "$1" && shift && "$FW_BIN" pass "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' ); }

printf '\nfw pass\n'

# --- outside a repository there is no diff to build a list from -------------
d="$(mktemp -d)"
out=$(run "$d")
check "outside git it refuses" "$out" "not a git repository"
refute "and does not print an empty list as if it were complete" "$out" "Where to look"

# --- nothing changed --------------------------------------------------------
d=$(fixture)
out=$(run "$d")
check "with nothing changed it says so" "$out" "there is no pass to make"
refute "and lists no screens" "$out" "Only a person can check"

# --- a template is what only a person can check -----------------------------
d=$(fixture)
printf '<button (click)="remove()">Borrar</button>\n' > "$d/src/app/features/cobros/presentation/list.html"
out=$(run "$d")
check "a changed template is named" "$out" "presentation/list.html"
check "under the heading that says why" "$out" "Only a person can check these"
check "and the feature it belongs to is grouped" "$out" "src/app/features/cobros"

# --- source with no colocated test ------------------------------------------
d=$(fixture)
printf 'export const a = 1;\n' > "$d/src/app/features/cobros/application/service.ts"
out=$(run "$d")
check "a changed file with no test beside it is flagged" "$out" "application/service.ts"
check "under the heading naming the reason" "$out" "Changed with no colocated test"

# --- source that does have one ----------------------------------------------
d=$(fixture)
printf 'export const a = 1;\n' > "$d/src/app/features/cobros/application/service.ts"
printf 'test\n' > "$d/src/app/features/cobros/application/service.spec.ts"
out=$(run "$d")
check "the file is still counted as changed" "$out" "2 file(s) changed"
# The warn marker is what says "this one needs your eyes", so the assertion has
# to be about the marker and not about the path, which appears in the grouping
# above for every changed file.
refute "but a tested file carries no warning of its own" "$out" "! src/app/features/cobros/application/service.ts"
check "and the section says everything is covered" "$out" "every changed source file has a test beside it"

# --- a spec file is not itself a finding ------------------------------------
d=$(fixture)
printf 'test\n' > "$d/src/app/features/cobros/application/only.spec.ts"
out=$(run "$d")
check "the spec is counted as a changed file" "$out" "1 file(s) changed"
check "but is never listed as lacking a test" "$out" "every changed source file has a test beside it"

# --- routes, menus and guards move who reaches what -------------------------
d=$(fixture)
mkdir -p "$d/src/app"
printf 'export const routes = [];\n' > "$d/src/app/app.routes.ts"
out=$(run "$d")
# The path also appears in the grouping above, so the assertion is on the marker
# that says "this one moved who can reach what".
check "a changed route file is called an entry point" "$out" "✗ src/app/app.routes.ts"
check "under the heading that says so" "$out" "Entry points touched"
check "and it points at the skill that resolves them" "$out" "skills/gating"

d=$(fixture)
printf 'export const a = 1;\n' > "$d/src/app/features/cobros/application/service.ts"
out=$(run "$d")
check "an ordinary change touches no entry point" "$out" "no route, menu or guard changed"

# --- the note carries both halves -------------------------------------------
d=$(fixture)
out=$(run "$d" note "el toggle de emisión no está gateado" --missed "audit.py: ciego a p-toggleswitch")
check "the note is recorded" "$out" "recorded in .fw/pass/"
log=$(run "$d" log)
check "the log holds what was seen" "$log" "**Seen:** el toggle de emisión no está gateado"
check "and what should have caught it" "$log" "**Should have caught it:** audit.py: ciego a p-toggleswitch"
refute "and does not invent a framework gap" "$log" "nothing exists"

# --- an empty second half is the finding, not a missing field ---------------
d=$(fixture)
out=$(run "$d" note "el sheet no cierra al clic afuera")
check "it is still recorded" "$out" "recorded in .fw/pass/"
check "and the empty half is named as the finding" "$out" "nothing was watching this"
log=$(run "$d" log)
check "the log says so in the entry itself" "$log" "nothing exists — framework gap"

# --- a note with no text is refused -----------------------------------------
d=$(fixture)
out=$(run "$d" note)
check "an empty note is refused" "$out" "nothing to record"
refute "and writes no log" "$(run "$d" log)" "**Seen:**"
check "the log says nothing was recorded" "$(run "$d" log)" "nothing recorded today"

rm -f "$FW_BIN"
printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
