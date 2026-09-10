#!/usr/bin/env bash
# Tests for the agy <-> engram bridge. The case that matters most is the one
# that looks fine: a bridge wired with write access reads exactly like a
# correct one until the day a second writer overwrites an observation in place.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRIDGE="$FW_ROOT/bin/agy-bridge.py"

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

home() {
  local d; d="$(mktemp -d)"
  mkdir -p "$d/config" "$d/antigravity-cli"
  printf '%s' "$d"
}
run() {
  local d="$1" mode="$2"
  GEMINI_CONFIG_DIR="$d" ANTIGRAVITY_CONFIG_DIR="$d/antigravity-cli" \
    python3 "$BRIDGE" "$mode" 2>&1
}
rc() {
  local d="$1" mode="$2"
  GEMINI_CONFIG_DIR="$d" ANTIGRAVITY_CONFIG_DIR="$d/antigravity-cli" \
    python3 "$BRIDGE" "$mode" >/dev/null 2>&1; printf '%s' $?
}

printf '\nagy-bridge check\n'

d="$(home)"
out="$(run "$d" check)"
check "an unconfigured machine reports the missing server" "$out" "bad	agy: engram not registered"
check "and that headless mode would deny the tools"        "$out" "bad	agy: MCP tools are auto-denied"
check "and the missing protocol"                           "$out" "bad	agy: no memory protocol"
[ "$(rc "$d" check)" = 1 ] && ok "check exits non-zero when something is missing" || ko "check exits non-zero when something is missing"

printf '\nagy-bridge install\n'

out="$(run "$d" install)"
check "install registers the server read-only" "$out" "ok	agy: engram registered read-only"
check "install adds the narrow allow rule"     "$out" "ok	agy: added mcp(engram/*)"
check "install writes the read-only protocol"  "$out" "ok	agy: read-only memory protocol written"

out="$(run "$d" check)"
refute "and the machine is then clean" "$out" "bad"
[ "$(rc "$d" check)" = 0 ] && ok "check exits zero once configured" || ko "check exits zero once configured"

out="$(run "$d" install)"
refute "install is idempotent" "$out" "bad"
check "a second install still reports read-only" "$out" "ok	agy: engram registered, read-only"

printf '\nthe failure that looks like success\n'

# The whole point of the bridge. --tools=agent is what `engram setup` installs,
# and it carries mem_save: a second writer into a store whose topic_key upsert
# replaces in place with no record of what it replaced.
d="$(home)"
run "$d" install >/dev/null
python3 - "$d" <<'EOF'
import json, sys
p = sys.argv[1] + "/config/mcp_config.json"
d = json.load(open(p))
d["mcpServers"]["engram"]["args"] = ["mcp", "--tools=agent"]
json.dump(d, open(p, "w"), indent=2)
EOF
out="$(run "$d" check)"
check "a writable engram is reported, not passed" "$out" "bad	agy: engram can WRITE memory"
check "and it names what made it writable"        "$out" "agent"
[ "$(rc "$d" check)" = 1 ] && ok "and check fails" || ko "and check fails"

out="$(run "$d" install)"
check "install repairs it back to read-only" "$out" "ok	agy: engram registered read-only"

d="$(home)"
run "$d" install >/dev/null
python3 - "$d" <<'EOF'
import json, sys
p = sys.argv[1] + "/config/mcp_config.json"
d = json.load(open(p))
d["mcpServers"]["engram"]["args"] = ["mcp", "--tools=mem_search,mem_save"]
json.dump(d, open(p, "w"), indent=2)
EOF
check "one write tool among reads is still writable" "$(run "$d" check)" "bad	agy: engram can WRITE memory"

printf '\nwhat agy and engram actually leave behind\n'

# agy creates mcp_config.json as a zero-byte file, and `engram setup` crashes on
# it with `unexpected end of JSON input`. Install has to survive what is really
# on disk, not what a schema says should be.
d="$(home)"
: > "$d/config/mcp_config.json"
out="$(run "$d" install)"
check "an empty mcp_config.json is installable, not a crash" "$out" "ok	agy: engram registered read-only"

d="$(home)"
printf 'not json at all' > "$d/config/mcp_config.json"
out="$(run "$d" check)"
check "malformed JSON is reported, never silently rewritten" "$out" "bad	agy: mcp_config.json is not valid JSON"

# engram setup writes a protocol that mandates mem_save and recommends
# topic_key — the exact behaviour this bridge exists to prevent.
d="$(home)"
printf '<!-- BEGIN ENGRAM MEMORY PROTOCOL -->\nCall mem_save. Reuse the same topic_key.\n<!-- END ENGRAM MEMORY PROTOCOL -->\n' > "$d/GEMINI.md"
check "the writable protocol is reported" "$(run "$d" check)" "bad	agy: GEMINI.md carries the writable protocol"
run "$d" install >/dev/null
body="$(cat "$d/GEMINI.md")"
check "install replaces it with the read-only one" "$body" "READ ONLY"
refute "and does not leave the old one behind"     "$body" "Reuse the same topic_key"
[ "$(grep -c 'BEGIN ENGRAM MEMORY PROTOCOL' "$d/GEMINI.md")" = 1 ] \
  && ok "exactly one protocol block survives" || ko "exactly one protocol block survives"

printf '\nit is a guest in files it does not own\n'

d="$(home)"
printf '# My own rules\n\nNever use tabs.\n' > "$d/GEMINI.md"
printf '{"trustedWorkspaces":["/tmp/x"]}\n' > "$d/antigravity-cli/settings.json"
run "$d" install >/dev/null
check "existing GEMINI.md content is kept" "$(cat "$d/GEMINI.md")" "Never use tabs."
check "existing settings.json keys are kept" "$(cat "$d/antigravity-cli/settings.json")" "trustedWorkspaces"

# mcp(*) is broader than what install writes, but it is a real answer to the
# same question, and rewriting a deliberate choice is not a repair.
d="$(home)"
run "$d" install >/dev/null
python3 - "$d" <<'EOF'
import json, sys
p = sys.argv[1] + "/antigravity-cli/settings.json"
d = json.load(open(p)); d["permissions"]["allow"] = ["mcp(*)"]
json.dump(d, open(p, "w"), indent=2)
EOF
check "a broader rule the user chose is accepted" "$(run "$d" check)" "ok	agy: MCP tools allowed"

printf '\nthe lane it will not enable for you\n'

# Reading files needs command(*), which is arbitrary shell in the person's
# repository. An installer that quietly grants that has made a security decision
# on their behalf and told them by not mentioning it.
d="$(home)"
run "$d" install >/dev/null
out="$(run "$d" check)"
check "the file lane is named, not enabled" "$out" "note	agy: memory only"
check "and says exactly what it would cost" "$out" "command(*), which is arbitrary shell"
refute "install never writes it"            "$(cat "$d/antigravity-cli/settings.json")" "command(*)"
[ "$(rc "$d" check)" = 0 ] && ok "and its absence is not a fault" || ko "and its absence is not a fault"

python3 - "$d" <<'EOF'
import json, sys
p = sys.argv[1] + "/antigravity-cli/settings.json"
d = json.load(open(p)); d["permissions"]["allow"].append("command(*)")
json.dump(d, open(p, "w"), indent=2)
EOF
refute "once the person grants it, the note stops" "$(run "$d" check)" "note	agy: memory only"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
