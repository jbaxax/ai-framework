#!/usr/bin/env bash
# Tests for `fw split`. Everything it checks fails silently in real life: a file
# dropped from a `git add`, content altered while moving it between commits, an
# intermediate commit that does not parse. A clean `git log` shows none of them,
# which is exactly why a command has to.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW_SRC="${FW_SPLIT_BIN:-$FW_ROOT/bin/fw}"
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
  printf 'base\n' > "$d/README.md"
  git -C "$d" add -A >/dev/null 2>&1; git -C "$d" commit -qm base >/dev/null 2>&1
  printf '#!/bin/sh\necho a\n' > "$d/tool-a.sh"
  printf '#!/bin/sh\necho b\n' > "$d/tool-b.sh"
  printf 'x = 1\n' > "$d/lib.py"
  printf '%s' "$d"
}
run()   { ( cd "$1" && shift && "$FW_BIN" split "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' ); }
rc_of() { ( cd "$1" && shift && "$FW_BIN" split "$@" >/dev/null 2>&1 ); printf '%s' "$?"; }
commit(){ git -C "$1" add "${@:3}" >/dev/null 2>&1; git -C "$1" commit -qm "$2" >/dev/null 2>&1; }

printf '\nfw split\n'

# --- verify with no baseline cannot say anything ----------------------------
# Comparing against nothing is the failure this command exists to prevent, so it
# must refuse rather than invent a pass.
d=$(fixture)
out=$(run "$d" verify)
check "verify without a baseline is refused" "$out" "no baseline"
check "and says when it should have been taken" "$out" "before splitting, not after"
refute "and never reports a verdict" "$out" "Verdict:"

# --- a clean tree has nothing to split --------------------------------------
d=$(fixture); rm "$d/tool-a.sh" "$d/tool-b.sh" "$d/lib.py"
out=$(run "$d" start)
check "start on a clean tree is refused" "$out" "the working tree is clean"

# --- the honest case --------------------------------------------------------
d=$(fixture)
run "$d" start >/dev/null
commit "$d" "feat: a" tool-a.sh
commit "$d" "feat: b" tool-b.sh lib.py
out=$(run "$d" verify)
check "a sound split reports the content intact" "$out" "3 file(s) identical to the baseline"
check "and the tree empty" "$out" "working tree clean"
check "and every commit named" "$out" "feat: a"
check "with the verdict" "$out" "**Verdict: PASS**"

# --- a file that never reached a commit -------------------------------------
# The one a clean `git log` hides completely: two tidy commits, and the third
# file still sitting in the working tree.
d=$(fixture)
run "$d" start >/dev/null
commit "$d" "feat: a" tool-a.sh
commit "$d" "feat: b" tool-b.sh
out=$(run "$d" verify)
check "a file left behind is reported" "$out" "1 path(s) still uncommitted"
check "and named" "$out" "lib.py"
check "and the verdict is FAIL" "$out" "**Verdict: FAIL**"
check "and the process exits non-zero" "$(rc_of "$d" verify)" "1"

# --- content altered while being split --------------------------------------
# A split may move work between commits. It may not change it, or the review
# is of something nobody wrote on purpose.
d=$(fixture)
run "$d" start >/dev/null
printf '#!/bin/sh\necho a-edited\n' > "$d/tool-a.sh"
commit "$d" "feat: a" tool-a.sh
commit "$d" "feat: b" tool-b.sh lib.py
out=$(run "$d" verify)
check "content that drifted is reported" "$out" "changed since the baseline: tool-a.sh"
check "and the reason is stated" "$out" "may only move work between commits"
check "and it fails" "$out" "**Verdict: FAIL**"

# --- an intermediate commit that does not parse -----------------------------
# The subtle one: the final tree is perfect, so nothing about HEAD reveals that
# the middle of the history cannot be checked out and run.
d=$(fixture)
printf '#!/bin/sh\nif [ 1 = 1 ]; then echo a; fi\n' > "$d/tool-a.sh"
run "$d" start >/dev/null
printf '#!/bin/sh\nif [ 1 = 1 ]; then echo a\n' > "$d/tool-a.sh"   # falta el fi
commit "$d" "feat: broken middle" tool-a.sh
printf '#!/bin/sh\nif [ 1 = 1 ]; then echo a; fi\n' > "$d/tool-a.sh"   # reparado al final
commit "$d" "feat: rest" tool-a.sh tool-b.sh lib.py
out=$(run "$d" verify)
check "the final content still matches the baseline" "$out" "identical to the baseline"
check "but the broken middle commit is caught" "$out" "tool-a.sh does not parse"
check "and it fails" "$out" "**Verdict: FAIL**"

# --- python is checked too --------------------------------------------------
d=$(fixture)
run "$d" start >/dev/null
printf 'def f(:\n' > "$d/lib.py"
commit "$d" "feat: bad python" lib.py
commit "$d" "feat: rest" tool-a.sh tool-b.sh
out=$(run "$d" verify)
check "a python file that does not parse is caught" "$out" "lib.py does not parse"

# --- what cannot be syntax-checked is said, not assumed ---------------------
d=$(fixture); printf 'hello\n' > "$d/notes.md"
run "$d" start >/dev/null
commit "$d" "feat: all" tool-a.sh tool-b.sh lib.py notes.md
out=$(run "$d" verify)
check "the run passes" "$out" "**Verdict: PASS**"
check "and unverifiable files are counted separately" "$out" "not checkable by syntax alone"
refute "never folded into the parsed count as if they were fine" "$out" "0 not checkable"

# --- the baseline is cleared only on success --------------------------------
d=$(fixture)
run "$d" start >/dev/null
commit "$d" "feat: a" tool-a.sh
out=$(run "$d" verify)
check "a failed verify keeps the baseline" "$out" "**Verdict: FAIL**"
# The point is that the baseline survives a failure, so the same answer comes
# back rather than "no baseline" — not the specific count.
check "so a second verify still answers" "$(run "$d" verify)" "path(s) still uncommitted"
refute "and does not claim the baseline is gone" "$(run "$d" verify)" "no baseline"

rm -f "$FW_BIN"
printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
