#!/usr/bin/env python3
"""Register or verify the fw UserPromptSubmit hook in a Claude settings file.

settings.json is a shared machine registry, not one tool's file: several tools
register hooks in it. This writes one pointer entry and never touches anything
else that lives there.
"""
import json
import sys


def entries(settings):
    return settings.setdefault("hooks", {}).setdefault("UserPromptSubmit", [])


def registered(settings, command):
    for group in entries(settings):
        if not isinstance(group, dict):
            continue
        for hook in group.get("hooks", []):
            if isinstance(hook, dict) and hook.get("command") == command:
                return True
    return False


def main():
    if len(sys.argv) < 3:
        print("usage: register-hook.py <settings.json> <command> [--check]", file=sys.stderr)
        return 2

    path, command = sys.argv[1], sys.argv[2]
    check_only = "--check" in sys.argv[3:]

    try:
        with open(path, encoding="utf-8") as fh:
            settings = json.load(fh)
    except FileNotFoundError:
        if check_only:
            print("absent")
            return 1
        settings = {}
    except json.JSONDecodeError as exc:
        print("unreadable: %s" % exc, file=sys.stderr)
        return 2

    if not isinstance(settings, dict):
        print("unreadable: top level is not an object", file=sys.stderr)
        return 2

    if registered(settings, command):
        print("registered")
        return 0

    if check_only:
        print("absent")
        return 1

    entries(settings).append({"hooks": [{"type": "command", "command": command}]})

    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(settings, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    print("added")
    return 0


if __name__ == "__main__":
    sys.exit(main())
