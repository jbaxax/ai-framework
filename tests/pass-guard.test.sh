#!/usr/bin/env bash
# Tests for the Stop hook behind `fw pass`. Its whole job is to speak once, with
# a true count, and then be quiet. A hook that repeats itself every turn gets
# read once and skipped forever — the same silence it was built to fix, arrived
# at more expensively.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$FW_ROOT/hooks/pass-guard.sh"
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
empty() {
  local label="$1" out="$2"
  if [ -z "$out" ]; then ok "$label"
  else ko "$label"; printf '      expected silence, got: %s\n' "$out"; fi
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
fire() { printf '{"cwd":"%s","transcript_path":"/x","stop_hook_active":false}' "$1" | FW_PASS_BIN="$FW_BIN" bash "$HOOK" 2>&1; }
msg()  { fire "$1" | python3 -c 'import json,sys
raw=sys.stdin.read().strip()
print(json.loads(raw)["systemMessage"] if raw else "")'; }

printf '\nfw pass --porcelain\n'

# --- the classifier is the hook'\''s only input, so it is tested first ---------
d="$(fixture)"
out="$(cd "$d" && "$FW_BIN" pass --porcelain 2>&1)"
empty "a clean tree classifies nothing" "$out"

printf '<div>x</div>\n' > "$d/src/app/features/cobros/presentation/collection-list.html"
printf 'export const x = 1\n' > "$d/src/app/features/cobros/application/useCollections.ts"
printf 'export const routes = []\n' > "$d/src/app/app.routes.ts"
out="$(cd "$d" && "$FW_BIN" pass --porcelain 2>&1)"
check "a changed template is a template"  "$out" "template	src/app/features/cobros/presentation/collection-list.html"
check "a source file with no test beside it is untested" "$out" "untested	src/app/features/cobros/application/useCollections.ts"
check "a routes file is an entry point"   "$out" "entry	src/app/app.routes.ts"

# A file whose test sits beside it is already watched, and naming it anyway is
# how a list stops being read.
printf 'export const y = 1\n' > "$d/src/app/features/cobros/application/useTotals.ts"
printf 'test\n' > "$d/src/app/features/cobros/application/useTotals.test.ts"
out="$(cd "$d" && "$FW_BIN" pass --porcelain 2>&1)"
refute "a file with a colocated test is not listed" "$out" "untested	src/app/features/cobros/application/useTotals.ts"

out="$(cd "$(mktemp -d)" && "$FW_BIN" pass --porcelain 2>&1)"
empty "outside a repository it is silent, never an error" "$out"

printf '\npass-guard.sh\n'

# --- speaking, once ---------------------------------------------------------
d="$(fixture)"
printf '<div>x</div>\n' > "$d/src/app/features/cobros/presentation/collection-list.html"
printf 'export const routes = []\n' > "$d/src/app/app.routes.ts"

out="$(msg "$d")"
check "it names the template a person is the only check for" "$out" "collection-list.html"
check "and says what the person is looking for"              "$out" "only a person can check this"
check "it points at the command that records the finding"    "$out" "fw pass note"
check "and at the field the retro is built from"             "$out" "--missed"

# The count and the list under it are the same claim. A count that does not
# match its own list is not trusted a second time — and one file can need a
# person for two reasons at once, which is exactly how they come apart.
check "one file needing two checks is still one file" "$out" "2 file(s) changed"
check "and both of its reasons are named on its line" "$out" "changed with no colocated test; entry point"

# --- and then being quiet ---------------------------------------------------
empty "the same state a second time says nothing" "$(fire "$d")"

printf 'export const z = 1\n' > "$d/src/app/features/cobros/application/useNew.ts"
check "a file that appeared since is new information" "$(msg "$d")" "useNew.ts"
empty "and that state, once said, is quiet too" "$(fire "$d")"

# --- a broken guard must never break the turn -------------------------------
d2="$(fixture)"
empty "a clean tree produces no message"          "$(fire "$d2")"
empty "a payload with no cwd is silent"           "$(printf '{}' | bash "$HOOK" 2>&1)"
empty "a payload that is not JSON is silent"      "$(printf 'not json' | bash "$HOOK" 2>&1)"
empty "an empty payload is silent"                "$(printf '' | bash "$HOOK" 2>&1)"
empty "a cwd that does not exist is silent"       "$(printf '{"cwd":"/no/such/dir"}' | bash "$HOOK" 2>&1)"

printf '{"cwd":"%s"}' "$d2" | bash "$HOOK" >/dev/null 2>&1
ok_exit=$?
if [ "$ok_exit" -eq 0 ]; then ok "it exits 0 so the turn always completes"
else ko "it exits 0 so the turn always completes"; printf '      exit was %s\n' "$ok_exit"; fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
