#!/usr/bin/env python3
"""Name the installed skills whose triggers match a prompt.

Skills are a pull channel: something has to decide to open them, and across
three logged sessions that decision was made zero times out of four while four
skills were on topic. A mandate obeyed none of the time is a comment.

This reads the prompt on stdin and prints, for the matching skills, where to
read them. It never fails loudly: a router that eats a prompt is worse than a
router that stays quiet.
"""
import json
import os
import re
import sys
import unicodedata

# Naming more than a handful turns the injection into scenery. The failure being
# fixed is zero, and the failure mode of over-firing is the same silence with
# extra tokens.
MAX_SKILLS = 4

# Below this, a phrase is a fragment that appears inside unrelated words even
# with boundaries — and a router that fires on everything is ignored exactly
# like one that never fires.
MIN_PHRASE = 3


def fold(text):
    """Lowercase and strip accents, so 'qué sigo' matches 'que sigo'."""
    text = unicodedata.normalize("NFD", text.lower())
    return "".join(c for c in text if not unicodedata.combining(c))


def description_of(path):
    """The frontmatter description, quotes and folded continuation lines included."""
    try:
        with open(path, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
    except OSError:
        return ""
    if not lines or lines[0].strip() != "---":
        return ""
    value, collecting = "", False
    for line in lines[1:]:
        if line.strip() == "---":
            break
        if collecting:
            # A folded YAML scalar continues while the line is indented and
            # carries no new key.
            if line.startswith((" ", "\t")) and not re.match(r"^\s*[a-zA-Z_-]+:", line):
                value += " " + line.strip()
                continue
            break
        if line.startswith("description:"):
            value = line[len("description:"):].strip()
            collecting = True
    return value.strip().strip('"').strip("'")


def triggers_of(description):
    """The comma-separated phrases after `Trigger:`, up to the sentence that ends them."""
    match = re.search(r"trigger\s*:\s*(.*)", description, re.IGNORECASE | re.DOTALL)
    if not match:
        return []
    body = match.group(1)
    # The list ends at the first sentence break that is not inside a phrase.
    end = re.search(r"\.\s+[A-Z]", body)
    if end:
        body = body[: end.start()]
    phrases = []
    for raw in body.split(","):
        phrase = fold(raw.strip().strip("'\"").rstrip("."))
        if len(phrase) >= MIN_PHRASE:
            phrases.append(phrase)
    return phrases


def matches(prompt, phrase):
    """Word-boundary match, so `test` never fires on `latest`.

    The last word may carry a plural suffix. Measured against real prompts,
    `corré los tests` missed the trigger `test` and `mocks` missed `mock` —
    a router that only matches the dictionary form is a router nobody's actual
    typing reaches. This is a plural, not stemming: no other inflection is
    guessed, because guessing wrongly fires on unrelated words.
    """
    words = [re.escape(word) for word in phrase.split()]
    words[-1] += r"(?:e?s)?"
    pattern = r"\s+".join(words)
    return re.search(r"(?<!\w)" + pattern + r"(?!\w)", prompt) is not None


def skill_files(root):
    try:
        names = sorted(os.listdir(root))
    except OSError:
        return
    for name in names:
        if name.startswith((".", "_")):
            continue
        path = os.path.join(root, name, "SKILL.md")
        if os.path.isfile(path):
            yield name, path


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude"), "skills"
    )
    raw = sys.stdin.read()
    # The hook payload is a JSON envelope. Matching the whole envelope would
    # fire on its own fields: a cwd of `.../src/app/auth/login` matches the
    # `auth` skill's triggers without the person having typed anything about
    # auth, and a router that fires on the machine's own paths is noise.
    try:
        payload = json.loads(raw)
        raw = payload.get("prompt", "") if isinstance(payload, dict) else raw
    except (ValueError, TypeError):
        pass

    prompt = fold(raw)
    if not prompt.strip():
        return 0

    hits = []
    for name, path in skill_files(root):
        found = [p for p in triggers_of(description_of(path)) if matches(prompt, p)]
        if found:
            hits.append((len(found), name, found, path))

    if not hits:
        return 0

    hits.sort(key=lambda h: (-h[0], h[1]))
    shown, rest = hits[:MAX_SKILLS], hits[MAX_SKILLS:]

    print("fw — these installed skills declare a trigger this prompt matches.")
    print("Read each SKILL.md before answering. A skill you did not open is a rule")
    print("that did not apply, and nothing downstream will notice it was skipped.")
    print()
    print("| Skill | Matched on | Read |")
    print("|---|---|---|")
    for _, name, found, path in shown:
        on = ", ".join('"%s"' % p for p in found[:3])
        print("| %s | %s | `%s` |" % (name, on, path))
    if rest:
        print()
        print("%d more matched and were not listed: %s." % (
            len(rest), ", ".join(name for _, name, _, _ in rest)))
    print()
    print("Matching a trigger is not proof the skill applies — open it and say in")
    print("one line which one you used and which you ruled out, so the decision is")
    print("visible instead of implicit.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        # A prompt must survive any defect in here.
        sys.exit(0)
