#!/usr/bin/env bash
# Tests for how `fw` finds Python.
#
# Windows App Execution Aliases put a `python3` on PATH that is not Python: it
# prints "install it from the Microsoft Store" and exits 49. `command -v` finds
# it, so a lookup that trusts resolution alone returns a binary that cannot run
# anything. Every feature behind it then fails, and on 2026-09-07 that was the
# plan hook: `fw doctor` said "run 'fw link'" and `fw link` failed the same way
# each time, with the real reason only visible if the output was not truncated.
#
# The suite proves the lookup by making the first candidate a stub, which is the
# exact shape of the machine that found the bug.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW_SRC="${FW_PYTHON_BIN_UNDER_TEST:-$FW_ROOT/bin/fw}"

# Same reason as doctor.test.sh: a CRLF checkout does not parse under Linux
# bash, and the suite would go red for a reason unrelated to what it tests.
FW_HOME="$(mktemp -d)"; mkdir -p "$FW_HOME/bin"
FW_BIN="$FW_HOME/bin/fw"
tr -d '\r' < "$FW_SRC" > "$FW_BIN"; chmod +x "$FW_BIN"
ln -s "$FW_ROOT/rules" "$FW_HOME/rules"
ln -s "$FW_ROOT/hooks" "$FW_HOME/hooks"
ln -s "$FW_ROOT/skills" "$FW_HOME/skills"

PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
ko() { FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n' "$1"; }
check() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | tr -d '\000' | grep -qaF -- "$needle"; then ok "$label"
  else ko "$label"; printf '      expected to find: %s\n' "$needle"; fi
}
refute() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | tr -d '\000' | grep -qaF -- "$needle"; then
    ko "$label"; printf '      should NOT contain: %s\n' "$needle"
  else ok "$label"; fi
}

# The real interpreter, found before PATH is rewritten. Without one there is
# nothing to prefer over the stub and the suite would pass by accident.
REAL_PY=""
for c in python python3 py; do
  p="$(command -v "$c" 2>/dev/null)" || continue
  [ -n "$p" ] && "$p" -c '' >/dev/null 2>&1 && { REAL_PY="$p"; break; }
done
if [ -z "$REAL_PY" ]; then
  printf '  \033[33m!\033[0m no working Python on PATH — cannot test the lookup\n'
  exit 0
fi

# A PATH whose `python3` is the Store stub and whose `python` is real. Ordered
# so the broken candidate is the one a naive lookup returns first.
SHIM="$(mktemp -d)"
cat > "$SHIM/python3" <<'STUB'
#!/usr/bin/env bash
echo "no se encontro Python; ejecutar sin argumentos para instalar desde el Microsoft Store" >&2
exit 49
STUB
chmod +x "$SHIM/python3"
ln -s "$REAL_PY" "$SHIM/python"

run_link() {
  local home; home="$(mktemp -d)"
  PATH="$SHIM:$PATH" CLAUDE_CONFIG_DIR="$home" "$FW_BIN" link 2>&1
}

printf '\n\033[1mPython lookup skips a candidate that does not run\033[0m\n'

out="$(run_link)"

check "registers the plan hook despite a stub python3 first on PATH" \
      "$out" "plan hook added in settings.json"

refute "does not report the stub's Microsoft Store message as the failure" \
       "$out" "could not register"

refute "does not claim Python is missing while a working one is on PATH" \
       "$out" "no python on PATH"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
