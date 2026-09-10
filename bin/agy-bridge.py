#!/usr/bin/env python3
"""Check or install the agy <-> engram bridge.

agy reads the memory this framework's sessions write, and never writes to it.
That direction is the whole design: the topic_key upsert replaces an
observation in place with no record of what it replaced, so a second writer
turns a shared store into one nobody can trust.

Emits `status<TAB>message` per finding so the caller renders them, and exits
non-zero from `check` when anything is missing.
"""
import json
import os
import sys

HOME = os.path.expanduser("~")
MCP = os.path.join(os.environ.get("GEMINI_CONFIG_DIR", os.path.join(HOME, ".gemini")),
                   "config", "mcp_config.json")
GEMINI_DIR = os.environ.get("GEMINI_CONFIG_DIR", os.path.join(HOME, ".gemini"))
SETTINGS = os.path.join(os.environ.get("ANTIGRAVITY_CONFIG_DIR",
                                       os.path.join(GEMINI_DIR, "antigravity-cli")),
                        "settings.json")
RULES = os.path.join(GEMINI_DIR, "GEMINI.md")

READ_ONLY = "--tools=mem_search,mem_context,mem_get_observation,mem_current_project"
WRITE_TOOLS = ("mem_save", "mem_update", "mem_delete", "mem_session_summary",
               "mem_capture_passive", "agent", "admin", "all")
# Measured against agy 1.2.0: `mcp` and `mcp(engram__*)` are both denied in
# headless mode; `mcp(*)` works but covers every server ever added.
RULE = "mcp(engram/*)"
# Reading files needs `command(*)`, which is arbitrary shell — `command(cat *)`
# is rejected, so there is no narrow version. That is a decision for the person,
# not something an installer performs on their behalf.
FILE_RULE = "command(*)"

PROTOCOL = """<!-- BEGIN ENGRAM MEMORY PROTOCOL — managed by fw -->

## Engram Persistent Memory — READ ONLY

You share a memory store with another agent that does the writing. Your tools
are `mem_search`, `mem_context`, `mem_get_observation` and `mem_current_project`.
There is no `mem_save`, `mem_update` or `mem_session_summary` here, on purpose:
one writer keeps the store worth reading.

### Search memory before assuming a project has no history

1. `mem_context` — recent sessions, fast and cheap.
2. `mem_search` with keywords when that is not enough.
3. `mem_get_observation` for the full text of a hit worth reading.

Do it when the user references past work, and when starting on something the
project may already have decided. What comes back is background — why the
project is the way it is. It is not the task: the task is in the prompt, and
anything the prompt does not say is not settled by memory.

### At the end, do not try to save

Report what you did in your answer. The writer records it.

<!-- END ENGRAM MEMORY PROTOCOL -->
"""

findings = []


def say(status, message):
    findings.append((status, message))


def load(path):
    """An empty file is what agy itself leaves behind, and json.load raises on
    it. Treating that as {} is what makes install idempotent rather than a
    crash the caller has to know about."""
    try:
        raw = open(path, encoding="utf-8").read().strip()
    except FileNotFoundError:
        return None
    if not raw:
        return {}
    try:
        return json.loads(raw)
    except ValueError:
        return False


def save(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("\n")


def engram_binary():
    for d in (os.path.join(HOME, ".local", "bin"), "/usr/local/bin", "/usr/bin"):
        p = os.path.join(d, "engram")
        if os.path.isfile(p):
            return p
    return "engram"


def check_mcp(fix):
    data = load(MCP)
    if data is False:
        say("bad", "agy: mcp_config.json is not valid JSON — fix it by hand: %s" % MCP)
        return
    if data is None:
        data = {} if fix else None
    if data is None:
        say("bad", "agy: engram not registered as an MCP server — run 'fw link'")
        return

    server = (data.get("mcpServers") or {}).get("engram")
    args = (server or {}).get("args") or []
    writable = [t for t in WRITE_TOOLS if any(t in a for a in args)]

    if server and args and not writable:
        say("ok", "agy: engram registered, read-only")
        return
    if not fix:
        if not server:
            say("bad", "agy: engram not registered as an MCP server — run 'fw link'")
        else:
            say("bad", "agy: engram can WRITE memory (%s) — run 'fw link'" % ",".join(writable))
        return

    data.setdefault("mcpServers", {})["engram"] = {
        "command": engram_binary(),
        "args": ["mcp", READ_ONLY],
    }
    save(MCP, data)
    say("ok", "agy: engram registered read-only in mcp_config.json")


def check_rule(fix):
    data = load(SETTINGS)
    if data is False:
        say("bad", "agy: settings.json is not valid JSON — fix it by hand: %s" % SETTINGS)
        return
    if data is None:
        # A missing file and a missing rule have the same consequence, and the
        # consequence is what the person can act on. Naming the file instead
        # reports the plumbing and leaves them to work out what it costs.
        if not fix:
            say("bad", "agy: MCP tools are auto-denied in headless mode — run 'fw link'")
            return
        data = {}

    allow = (data.get("permissions") or {}).get("allow") or []
    if RULE in allow or "mcp(*)" in allow:
        say("ok", "agy: MCP tools allowed in headless mode")
        if FILE_RULE not in allow:
            say("note", "agy: memory only — reading files needs %s, which is arbitrary shell" % FILE_RULE)
        return
    if not fix:
        say("bad", "agy: MCP tools are auto-denied in headless mode — run 'fw link'")
        return

    data.setdefault("permissions", {}).setdefault("allow", [])
    data["permissions"]["allow"].append(RULE)
    save(SETTINGS, data)
    say("ok", "agy: added %s to settings.json" % RULE)


def check_protocol(fix):
    current = ""
    if os.path.isfile(RULES):
        current = open(RULES, encoding="utf-8").read()

    if "READ ONLY" in current and "ENGRAM MEMORY PROTOCOL" in current:
        say("ok", "agy: read-only memory protocol in GEMINI.md")
        return
    if not fix:
        if "ENGRAM MEMORY PROTOCOL" in current:
            say("bad", "agy: GEMINI.md carries the writable protocol — run 'fw link'")
        else:
            say("bad", "agy: no memory protocol in GEMINI.md — run 'fw link'")
        return

    # `engram setup antigravity-cli` writes its own block and would otherwise be
    # appended to rather than replaced, leaving two protocols that contradict.
    start = current.find("<!-- BEGIN ENGRAM MEMORY PROTOCOL")
    if start != -1:
        end = current.find("-->", current.find("<!-- END ENGRAM MEMORY PROTOCOL"))
        current = current[:start] + (current[end + 3:] if end != -1 else "")
    os.makedirs(os.path.dirname(RULES), exist_ok=True)
    with open(RULES, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(PROTOCOL + current.lstrip("\n"))
    say("ok", "agy: read-only memory protocol written to GEMINI.md")


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "check"
    if mode not in ("check", "install"):
        print("usage: agy-bridge.py [check|install]", file=sys.stderr)
        return 2

    fix = mode == "install"
    check_mcp(fix)
    check_rule(fix)
    check_protocol(fix)

    for status, message in findings:
        print("%s\t%s" % (status, message))
    return 1 if any(s == "bad" for s, _ in findings) else 0


if __name__ == "__main__":
    sys.exit(main())
