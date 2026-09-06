#!/usr/bin/env bash
# Tests for `fw product`. It had no suite, which is the same complaint the
# artifacts it manages are subject to: a thing that describes work, with nothing
# checking it still says something true.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW_SRC="${FW_PRODUCT_BIN:-$FW_ROOT/bin/fw}"
# fw derives FW_ROOT from its own path and reads templates/ from there, so the
# copy under test gets the repository's shape.
FW_HOME="$(mktemp -d)"; mkdir -p "$FW_HOME/bin"
FW_BIN="$FW_HOME/bin/fw"
tr -d '\r' < "$FW_SRC" > "$FW_BIN"; chmod +x "$FW_BIN"
ln -s "$FW_ROOT/templates" "$FW_HOME/templates"

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
  printf 'seed\n' > "$d/seed.txt"
  git -C "$d" add -A >/dev/null 2>&1; git -C "$d" commit -qm seed >/dev/null 2>&1
  ( cd "$d" && "$FW_BIN" product init >/dev/null 2>&1 )
  ( cd "$d" && "$FW_BIN" product epic checkout "Checkout" >/dev/null 2>&1 )
  ( cd "$d" && "$FW_BIN" product hu checkout "Pagar con tarjeta" >/dev/null 2>&1 )
  printf '%s' "$d"
}
list() { ( cd "$1" && "$FW_BIN" product list 2>&1 | sed 's/\x1b\[[0-9;]*m//g' ); }
# A commit made now is necessarily newer than a file written a moment ago only
# if the file's mtime is pushed back, so the age is set explicitly rather than
# by sleeping.
age() { touch -d "@$(( $(date +%s) - 3600 ))" "$1"; }
commit() { printf '%s\n' "$2" >> "$1/$3"; git -C "$1" add -A >/dev/null 2>&1; git -C "$1" commit -qm "$2" >/dev/null 2>&1; }

printf '\nfw product\n'

story() { printf '%s' "$1/.fw/product/criteria/checkout-01.md"; }

# --- a fresh artifact is not nagged -----------------------------------------
d=$(fixture)
out=$(list "$d")
check "a new story is listed" "$out" "checkout-01"
refute "and nothing is called stale" "$out" "since it was written"

# --- work moved after the artifact did --------------------------------------
d=$(fixture); age "$(story "$d")"
commit "$d" "cambio real" seed.txt
out=$(list "$d")
check "a story left behind by a commit is flagged" "$out" "commit(s) since it was written"
check "and the run says how many artifacts are affected" "$out" "1 artifact(s) describe work that moved without them"

# --- a story that names its files asks a sharper question -------------------
d=$(fixture)
sed -i 's|^Files:$|Files: src/checkout|' "$(story "$d")"
age "$(story "$d")"
mkdir -p "$d/src/checkout"
commit "$d" "toca lo suyo" src/checkout/pay.ts
out=$(list "$d")
check "a commit on its own files is a finding, not a hint" "$out" "commit(s) touched its files since it was written"
refute "and does not ask for the Files it already has" "$out" "declare  Files:"

# --- a commit elsewhere does not accuse a story that named its files ---------
d=$(fixture)
sed -i 's|^Files:$|Files: src/checkout|' "$(story "$d")"
age "$(story "$d")"
commit "$d" "otra cosa" seed.txt
out=$(list "$d")
# Both messages end in the same words, so the needle has to be the half that
# differs — a refute on the shared tail passes for the wrong reason.
# And without a positive assertion both refutes below pass on an empty listing.
check "the story is listed at all" "$out" "checkout-01"
refute "an unrelated commit leaves a scoped story alone" "$out" "touched its files"
refute "and is not downgraded to the blunt question either" "$out" "commit(s) since it was written"

# --- a finished story is allowed to sit still -------------------------------
d=$(fixture)
sed -i 's|^Status: draft$|Status: done|' "$(story "$d")"
age "$(story "$d")"
commit "$d" "vida sigue" seed.txt
out=$(list "$d")
check "the status is read back as done" "$(list "$d")" "checkout-01                  done"
refute "a done story is never called stale" "$out" "since it was written"

# --- a story with no epic is still an error ---------------------------------
d=$(fixture)
cp "$(story "$d")" "$d/.fw/product/criteria/huerfana-01.md"
out=$(list "$d")
check "an orphan story is reported" "$out" "huerfana-01"
check "naming the epic it wants" "$out" "epics/huerfana.md"

rm -rf "$FW_HOME"
printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
