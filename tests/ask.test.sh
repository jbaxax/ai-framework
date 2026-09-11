#!/usr/bin/env bash
# Tests for `fw ask`. It never calls the real agy: a stub sits ahead of it on
# PATH and every case here proves the wrapper's own behaviour — what it packs,
# what it refuses, what it reports — none of it depends on Google's quota or
# a network. The case that matters most is the ERROR one: a wrapper that
# prints agy's error body and still exits 0 is indistinguishable from a
# working one until a caller trusts it.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW_SRC="${FW_ASK_BIN:-$FW_ROOT/bin/fw}"
# fw derives FW_ROOT from its own path and cmd_ask calls out to the sibling
# bin/ask.py, so a bare copy in /tmp would fail to find it — the fixture needs
# the repository's bin/ shape, with ask.py symlinked to the real one.
FW_HOME="$(mktemp -d)"; mkdir -p "$FW_HOME/bin"
FW_BIN="$FW_HOME/bin/fw"
tr -d '\r' < "$FW_SRC" > "$FW_BIN"; chmod +x "$FW_BIN"
ln -s "$FW_ROOT/bin/ask.py" "$FW_HOME/bin/ask.py"

PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
ko() { FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n' "$1"; }
check()  { if printf '%s' "$2" | grep -qF -- "$3"; then ok "$1"; else ko "$1"; printf '      expected to find: %s\n' "$3"; fi; }
refute() { if printf '%s' "$2" | grep -qF -- "$3"; then ko "$1"; printf '      should NOT contain: %s\n' "$3"; else ok "$1"; fi; }

# A stub, never the real thing. It records the exact argv it was called with
# (so a test can prove the prompt is never one of them — argv has an OS ceiling
# that moves with the caller's own environment, which is the bug this file
# guards against) and the full stdin it received (the prompt travels there
# instead), plus a call marker, then answers with whatever status the test asks
# for.
STUB_DIR="$(mktemp -d)"
cat > "$STUB_DIR/agy" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "${AGY_ARGV:-/dev/null}"
cat > "${AGY_CAPTURE:-/dev/null}"
: >> "${AGY_CALLS:-/dev/null}"
printf '{"status":"%s","response":"stub answer","usage":{"total_tokens":123},"duration_seconds":1.2}\n' \
  "${AGY_STATUS:-SUCCESS}"
STUB
chmod +x "$STUB_DIR/agy"

CAPTURE="$(mktemp)"
CALLS="$(mktemp)"
ARGV="$(mktemp)"

ask() {
  : > "$CAPTURE"; : > "$CALLS"; : > "$ARGV"
  AGY_CAPTURE="$CAPTURE" AGY_CALLS="$CALLS" AGY_ARGV="$ARGV" AGY_STATUS="${AGY_STATUS:-SUCCESS}" \
    PATH="$STUB_DIR:$PATH" "$FW_BIN" ask "$@" 2>&1
}
ask_rc() { ask "$@" >/dev/null 2>&1; printf '%s' $?; }
was_called() { [ -s "$CALLS" ]; }

FIX="$(mktemp -d)"
mkdir -p "$FIX/src" "$FIX/node_modules/pkg"
printf 'export const total = 1\n' > "$FIX/src/app.ts"
printf 'module.exports = {}\n'    > "$FIX/node_modules/pkg/index.js"
printf '{}\n'                     > "$FIX/package-lock.json"
head -c 64 /dev/urandom > "$FIX/logo.bin"

printf '\nfw ask — packing\n'

out="$(ask "what does app.ts export?" "$FIX")"
prompt="$(cat "$CAPTURE")"
check "the source file is packed behind a FILE marker" "$prompt" "=== FILE:"
check "the source file's content reached agy" "$prompt" "export const total = 1"
refute "node_modules is excluded"     "$prompt" "node_modules"
refute "the lockfile is excluded"     "$prompt" "package-lock.json"
refute "the binary file is excluded"  "$prompt" "logo.bin"

printf '\nfw ask — the prompt travels over stdin, never argv\n'

# `-p "<huge string>"` shares the kernel's argv+environ budget with whatever
# the caller's own shell has already exported. A payload comfortably under our
# own 1 MB ceiling still blew that up in the wild once the environment was
# large enough — an OSError this script never even gets to report cleanly.
# Only a mechanism change fixes it: nothing this large may ever appear in argv.
argv="$(cat "$ARGV")"
refute "the prompt is not passed as -p"      "$argv" "-p"
refute "the prompt is not passed as --print" "$argv" "--print"
check "the prompt is requested over stdin instead" "$argv" "--input-format"

BULK="$(mktemp -d)"
for i in 1 2 3 4 5 6 7 8; do
  head -c 30000 /dev/zero | tr '\0' 'x' > "$BULK/file$i.txt"
done
out="$(ask "summarize this" "$BULK")"
check "a payload well past the old real-world failure size still packs" "$out" "packed  8 files"
refute "and produces no interpreter traceback" "$out" "Traceback"
refute "and never an OS argument-list error"   "$out" "Argument list too long"
[ "$(ask_rc "summarize this" "$BULK")" = 0 ] \
  && ok "and the call still succeeds" || ko "and the call still succeeds"

printf '\nfw ask — the ceiling\n'

BIG="$(mktemp -d)"
head -c 1200000 /dev/zero | tr '\0' 'a' > "$BIG/huge.txt"
out="$(ask "summarize this" "$BIG/huge.txt")"
check "the ceiling names the size"       "$out" "over the 1 MB ceiling"
check "and what to do about it"          "$out" "narrow the paths"
[ "$(ask_rc "summarize this" "$BIG/huge.txt")" != 0 ] \
  && ok "and exits non-zero" || ko "and exits non-zero"
ask "summarize this" "$BIG/huge.txt" >/dev/null
was_called && ko "agy is never reached over the ceiling" || ok "agy is never reached over the ceiling"

printf '\nfw ask — dry run\n'

out="$(ask "what does app.ts export?" "$FIX" --dry-run)"
check "dry-run reports what would be packed" "$out" "packed  1 files"
check "and says it called nothing"           "$out" "dry-run — agy was not called"
[ "$(ask_rc "q" "$FIX" --dry-run)" = 0 ] && ok "dry-run exits zero" || ko "dry-run exits zero"
ask "q" "$FIX" --dry-run >/dev/null
was_called && ko "dry-run never calls agy" || ok "dry-run never calls agy"

printf '\nfw ask — the failure that looks like success\n'

AGY_STATUS=ERROR
out="$(ask "what does app.ts export?" "$FIX")"
check "an ERROR status is reported, not hidden" "$out" "did not succeed"
[ "$(ask_rc "what does app.ts export?" "$FIX")" != 0 ] \
  && ok "and fw ask exits non-zero on it" || ko "and fw ask exits non-zero on it"
unset AGY_STATUS

printf '\nfw ask — agy missing\n'

out=$(PATH="/usr/bin:/bin" "$FW_BIN" ask "q" "$FIX" 2>&1)
check "a clear refusal names agy"     "$out" "agy not found on PATH"
refute "never a raw shell error"      "$out" "command not found"
rc=0; PATH="/usr/bin:/bin" "$FW_BIN" ask "q" "$FIX" >/dev/null 2>&1 || rc=$?
[ "$rc" != 0 ] && ok "and exits non-zero" || ko "and exits non-zero"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
