#!/usr/bin/env bash
# Tests for `fw backlog`. The date parser accepted only the English marker, so a
# Spanish entry printed "no date" and lost its wait in silence — and the days
# waiting is the only number the blocked bucket exists to show.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW_SRC="${FW_BACKLOG_BIN:-$FW_ROOT/bin/fw}"
FW_BIN="$(mktemp)"; tr -d '\r' < "$FW_SRC" > "$FW_BIN"; chmod +x "$FW_BIN"

PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
ko() { FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n' "$1"; }
check()  { if printf '%s' "$2" | grep -qE -- "$3"; then ok "$1"; else ko "$1"; printf '      expected to match: %s\n' "$3"; fi; }
refute() { if printf '%s' "$2" | grep -qE -- "$3"; then ko "$1"; printf '      should not match: %s\n' "$3"; else ok "$1"; fi; }

# Dates are generated relative to today so the suite does not rot.
ago() { date -d "$1 days ago" +%F; }

backlog() {
  local f; f="$(mktemp)"
  printf '## Blocked\n' > "$f"
  printf -- '- %s\n' "$@" >> "$f"
  printf '%s' "$f"
}
run() { FW_BACKLOG="$1" "$FW_BIN" backlog 2>&1; }

printf '\nfw backlog — waiting time\n'

out=$(run "$(backlog "Endpoint de roles (asked $(ago 5))")")
check "the English marker is read"        "$out" '5d —'
refute "and does not fall through to none" "$out" 'no date'

out=$(run "$(backlog "Endpoint de roles (preguntado $(ago 5))")")
check "the Spanish marker is read"         "$out" '5d —'
refute "and does not print no date"        "$out" 'no date'

out=$(run "$(backlog "Endpoint de roles (preguntada $(ago 2))")")
check "a feminine Spanish marker is read"  "$out" '2d —'

out=$(run "$(backlog "Endpoint de roles (consultado $(ago 4))")")
check "consultado is read"                 "$out" '4d —'

out=$(run "$(backlog "Endpoint de roles ($(ago 7))")")
check "a bare ISO date needs no marker"    "$out" '7d —'

out=$(run "$(backlog "Endpoint de roles, sin fecha")")
check "an entry with no date is called out" "$out" 'no date'

# STALE_DAYS defaults to 3: a longer wait must be flagged, not merely listed.
out=$(FW_STALE_DAYS=3 run "$(backlog "Viejo (preguntado $(ago 9))")")
check "a stale Spanish entry is flagged"   "$out" '9d —'
check "and counted in the follow-up total" "$out" 'question\(s\) unanswered for 3\+ days'

rm -f "$FW_BIN"
printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
