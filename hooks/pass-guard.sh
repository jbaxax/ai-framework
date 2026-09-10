#!/usr/bin/env bash
set -uo pipefail

# Stop. Fires when the turn ends. `additionalContext` does not reach the model
# here — the conversation is over, so there is no call to inject into — but
# `systemMessage` reaches the person, rendered as `Stop says: …`. That is the
# whole mechanism this hook has, and it is enough: the manual pass is the
# person's job, and what was missing was never the doing, it was the remembering.
#
# Never exit non-zero and never print anything but JSON: a broken guard must not
# break the turn.

payload="$(cat 2>/dev/null || true)"

py=""
for c in python3 python py; do
  cand="$(command -v "$c" 2>/dev/null)" || continue
  [ -n "$cand" ] || continue
  "$cand" -c '' >/dev/null 2>&1 || continue
  py="$cand"; break
done
[ -n "$py" ] || exit 0

cwd="$(printf '%s' "$payload" | "$py" -c 'import json,sys
try: print(json.load(sys.stdin).get("cwd") or "")
except Exception: print("")' 2>/dev/null)"
[ -n "$cwd" ] || exit 0
[ -d "$cwd" ] || exit 0

fw="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../bin/fw"
[ -x "$fw" ] || exit 0

checkable="$(cd "$cwd" && "$fw" pass --porcelain 2>/dev/null || true)"
[ -n "$checkable" ] || exit 0

# Speak only on new information. A hook that repeats itself every turn is a
# hook that gets read once and skipped forever, which is the same silence it
# was built to fix — arrived at more expensively.
stamp="$(printf '%s' "$checkable" | cksum | tr -d ' ')"
seen="$cwd/.fw/pass/.notified"
[ -f "$seen" ] && [ "$(cat "$seen" 2>/dev/null)" = "$stamp" ] && exit 0
mkdir -p "$cwd/.fw/pass" 2>/dev/null || exit 0
printf '%s' "$stamp" > "$seen" 2>/dev/null || exit 0

logged="none recorded today"
[ -f "$cwd/.fw/pass/$(date +%F).md" ] && logged="today's log already has entries"

printf '%s' "$checkable" | "$py" -c '
import json, sys

LABEL = {
    "template": "only a person can check this",
    "untested": "changed with no colocated test",
    "entry":    "entry point — who reaches what may have moved",
}
# One file can need a person for more than one reason. Counting the reasons
# instead of the files reports a number the person cannot reconcile with the
# list under it, and a count that does not match its own list is not trusted
# again.
order, reasons = [], {}
for line in sys.stdin.read().splitlines():
    if "\t" not in line:
        continue
    kind, path = line.split("\t", 1)
    if path not in reasons:
        reasons[path] = []
        order.append(path)
    label = LABEL.get(kind, kind)
    if label not in reasons[path]:
        reasons[path].append(label)

if not order:
    sys.exit(0)

lines = ["fw — %d file(s) changed that no check can see for you (%s)."
         % (len(order), sys.argv[1])]
for path in order[:8]:
    lines.append("  ! %-58s %s" % (path, "; ".join(reasons[path])))
if len(order) > 8:
    lines.append("  … and %d more — fw pass" % (len(order) - 8))
lines.append("")
lines.append("  fw pass                                    the full list, grouped by feature")
lines.append("  fw pass note \"<what you saw>\" --missed \"<what should have caught it>\"")
lines.append("")
lines.append("  --missed empty is not a missing field. It records that nothing was")
lines.append("  watching this, which is the finding.")

print(json.dumps({"systemMessage": "\n".join(lines)}))
' "$logged" 2>/dev/null || true

exit 0
