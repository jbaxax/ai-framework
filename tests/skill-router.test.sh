#!/usr/bin/env bash
# Tests for the skill router in the UserPromptSubmit hook. It runs on every
# prompt, so its two failure modes are opposite and both silent: naming nothing
# leaves the pull channel exactly as dead as before, and naming something on
# every prompt turns the injection into scenery nobody reads.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# FW_ROUTER points the suite at a deliberately broken copy, which is how this
# suite is proved able to go red before its green is believed.
ROUTER="${FW_ROUTER:-$FW_ROOT/hooks/skill-router.py}"
PY="$(command -v python3 || command -v python)"

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
  if [ -z "$(printf '%s' "$out" | tr -d '[:space:]')" ]; then ok "$label"
  else ko "$label"; printf '      expected silence, got: %s\n' "$out"; fi
}

# A synthetic skills directory. Asserting against the real trigger lists would
# make every edit to a skill's description break this suite for no defect; what
# is under test here is the matcher.
skill() {
  mkdir -p "$1/$2"
  printf -- '---\nname: %s\ndescription: "Trigger: %s. What it does."\n---\n\nbody\n' "$2" "$3" > "$1/$2/SKILL.md"
}
route() { printf '%s' "$2" | "$PY" "$ROUTER" "$1" 2>&1; }
rc_of() { printf '%s' "$2" | "$PY" "$ROUTER" "$1" >/dev/null 2>&1; printf '%s' "$?"; }

printf '\nfw skill router\n'

d=$(mktemp -d)
skill "$d" alpha "widget, blue widget, que sigo"
skill "$d" beta  "gadget, red gadget"
skill "$d" _shared "widget"

# --- silence is the default -------------------------------------------------
empty "a prompt matching nothing prints nothing" "$(route "$d" 'nothing relevant here')"
empty "an empty prompt prints nothing" "$(route "$d" '')"
check "and neither is an error" "$(rc_of "$d" 'nothing relevant here')" "0"

# --- a match names the skill and where to read it ---------------------------
out=$(route "$d" 'please fix the widget')
check "a matched skill is named" "$out" "| alpha |"
check "with the phrase that matched" "$out" '"widget"'
check "and the path to read" "$out" "$d/alpha/SKILL.md"
refute "an unmatched skill is not named" "$out" "| beta |"

# --- word boundaries --------------------------------------------------------
# Substring matching would fire `widget` inside `widgets-are-fine` and, more
# to the point, `test` inside `latest` on the real skills.
empty "a trigger inside a longer word does not fire" "$(route "$d" 'the midwidgetry is fine')"

# --- plurals, because that is how people actually type ----------------------
out=$(route "$d" 'the widgets are broken')
check "a plural still reaches its trigger" "$out" "| alpha |"

# --- accents fold both ways -------------------------------------------------
out=$(route "$d" 'qué sigo ahora')
check "an accented prompt matches an unaccented trigger" "$out" "| alpha |"
d2=$(mktemp -d); skill "$d2" gamma "qué sigo"
out=$(route "$d2" 'que sigo ahora')
check "and an unaccented prompt matches an accented trigger" "$out" "| gamma |"
# Folding is for matching only. Echoing the folded phrase back tells a Spanish
# reader their own trigger lost its accents.
check "the phrase is reported as it was written" "$out" '"qué sigo"'
refute "not as the folded form used to match it" "$out" '"que sigo"'

# --- ranking and the cap ----------------------------------------------------
d3=$(mktemp -d)
skill "$d3" one   "widget"
skill "$d3" two   "widget, gadget, sprocket"
skill "$d3" three "widget"
skill "$d3" four  "widget"
skill "$d3" five  "widget"
out=$(route "$d3" 'widget gadget sprocket')
check "the skill with most matches is listed first" "$(printf '%s' "$out" | grep -m1 '^| [a-z]')" "| two |"
check "the list is capped" "$out" "more matched and were not listed"

# --- the envelope is not the prompt -----------------------------------------
# The hook payload is JSON. Matching it whole fires on the machine's own paths.
out=$(route "$d" '{"cwd":"/home/x/src/app/widget/list","prompt":"unrelated question"}')
empty "a trigger appearing only in the payload envelope does not fire" "$out"
out=$(route "$d" '{"cwd":"/home/x/src","prompt":"fix the widget"}')
check "and the prompt field is still read" "$out" "| alpha |"

# --- what is not a skill ----------------------------------------------------
# A router that printed nothing satisfies this refute without having read a
# directory at all. Measured: against an empty skills dir it prints nothing and
# the refute passes, proving only that the assertion cannot tell.
out=$(route "$d" 'please fix the widget')
check "the routing happened at all" "$out" "| alpha |"
refute "and an underscore directory is skipped" "$out" "_shared"
d4=$(mktemp -d)
mkdir -p "$d4/plain"; printf -- '---\nname: plain\ndescription: "Does things with widgets."\n---\n' > "$d4/plain/SKILL.md"
empty "a description with no Trigger list never matches" "$(route "$d4" 'widget')"

# --- a defect must never eat a prompt ---------------------------------------
check "a missing skills directory exits clean" "$(rc_of /nonexistent/path 'widget')" "0"
empty "and prints nothing" "$(route /nonexistent/path 'widget')"
d5=$(mktemp -d); mkdir -p "$d5/bad"; printf 'not frontmatter at all\n' > "$d5/bad/SKILL.md"
check "an unparseable SKILL.md exits clean" "$(rc_of "$d5" 'widget')" "0"

# --- regression on the real trigger lists -----------------------------------
# These four prompts are the ones from the 2026-09-05 session where four skills
# were on topic and none was opened. They are asserted against the repository's
# own skills on purpose: if the Spanish triggers are dropped, this goes red.
real() { printf '%s' "$1" | "$PY" "$ROUTER" "$FW_ROOT/skills" 2>&1; }
check "a 403 report routes to diagnosis" "$(real 'transportista me deja crear pero no editar, tira 403')" "| diagnosis |"
check "asking to verify routes to verification-standards" "$(real 'verificá que esto está bien antes de cerrar')" "| verification-standards |"
check "writing a spec routes to testing" "$(real 'escribí un spec para el gate de permisos')" "| testing |"
check "asking what is next routes to backlog" "$(real 'qué sigo ahora')" "| backlog |"
check "an exploration request routes to delegation" "$(real 'revisá todo el módulo de cobros')" "| delegation |"
check "and so does naming a subagent" "$(real 'delegá esto a un subagente')" "| delegation |"
check "a gating finding routes to gating" "$(real 'este control no tiene gate')" "| gating |"
check "and so does asking who opens a screen" "$(real 'quién abre este modal')" "| gating |"
check "in English too" "$(real 'who opens this modal')" "| gating |"
empty "and an ordinary edit request stays silent" "$(real 'agregá un botón de guardar en el modal')"

printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
