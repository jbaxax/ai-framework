#!/usr/bin/env python3
"""Pack files for agy and ask it a question, reporting cost and the answer.

The shell reads the files here, not the calling Claude session's context —
that is the entire point of this lane. Bulk text goes in on Google's quota;
only a short answer comes back. Measured against this repository: 27 files,
104 KB, 40,158 input tokens on agy's side, about 120 characters back.
"""
import argparse
import json
import os
import subprocess
import sys

EXCLUDE_DIRS = {
    "node_modules", ".git", "dist", "build", "coverage", ".next", ".nuxt",
    "__pycache__", ".venv", "venv", ".turbo", ".cache", "out",
}
LOCKFILES = {
    "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lock",
    "bun.lockb", "Cargo.lock", "go.sum", "poetry.lock",
}
SOURCE_EXTS = {
    ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".py", ".go", ".rs",
    ".java", ".rb", ".php", ".c", ".h", ".cpp", ".hpp", ".sh", ".md", ".mdx",
    ".json", ".yml", ".yaml", ".toml", ".css", ".scss", ".html", ".txt",
}

# A route that dies at the shell's own ARG_MAX with a bare error is not a lane
# either. These are checked before agy is ever called.
LIMIT_WARN = 400 * 1024
LIMIT_HARD = 1024 * 1024

# skills/delegation calls this "a cold agent over-asserts" — asked without file
# access, agy answered fluently and confidently about the wrong project. Every
# claim needs a file:line, and UNKNOWN is a valid answer when the packed text
# genuinely does not say.
BRIEF = """Answer only from the packed files below. Every claim must cite the \
exact file and line as `path:line`. Where the packed text does not answer, \
respond with exactly UNKNOWN for that part instead of guessing or reasoning \
from anything outside it. No preamble — answer the question directly.

QUESTION: {question}

"""


def is_binary(path):
    try:
        with open(path, "rb") as fh:
            chunk = fh.read(8192)
    except OSError:
        return True
    return b"\0" in chunk


def read_text(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except (UnicodeDecodeError, OSError):
        return None


def collect(paths):
    """Yield (relpath, text) for every file worth packing.

    A path given directly is trusted as given. A directory is walked and
    filtered instead, because a directory can hand back thousands of files
    nobody asked for — node_modules, lockfiles, binaries.
    """
    seen = set()
    for raw in paths:
        if os.path.isfile(raw):
            if raw in seen or is_binary(raw):
                continue
            seen.add(raw)
            text = read_text(raw)
            if text is not None:
                yield raw, text
            continue
        for root, dirs, files in os.walk(raw):
            dirs[:] = sorted(d for d in dirs if d not in EXCLUDE_DIRS)
            for name in sorted(files):
                if name in LOCKFILES:
                    continue
                if os.path.splitext(name)[1] not in SOURCE_EXTS:
                    continue
                path = os.path.join(root, name)
                if path in seen or is_binary(path):
                    continue
                seen.add(path)
                text = read_text(path)
                if text is not None:
                    yield path, text


def human(n):
    if n < 1024:
        return "%d B" % n
    if n < 1024 * 1024:
        return "%.0f KB" % (n / 1024)
    return "%.1f MB" % (n / (1024 * 1024))


def fmt_duration(seconds):
    if seconds < 10:
        return "%.1fs" % seconds
    return "%ds" % round(seconds)


def main():
    parser = argparse.ArgumentParser(prog="fw ask", add_help=False)
    parser.add_argument("question")
    parser.add_argument("paths", nargs="*", default=["."])
    parser.add_argument("--model", default="gemini-3.8-flash-medium")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    files = list(collect(args.paths))
    if not files:
        print("  ask: nothing to pack under %s" % ", ".join(args.paths), file=sys.stderr)
        return 1

    packed = "".join("=== FILE: %s\n%s\n" % (relpath, text) for relpath, text in files)
    size = len(packed.encode("utf-8"))

    print("  packed  %d files · %s" % (len(files), human(size)))

    if size > LIMIT_HARD:
        print("  ask: packed payload is %s, over the 1 MB ceiling for this lane" % human(size), file=sys.stderr)
        print("  narrow the paths — a subdirectory, not the whole tree", file=sys.stderr)
        return 1
    if size > LIMIT_WARN:
        print("  ask: %s is a lot for one question — narrowing the paths keeps the answer sharp" % human(size))

    if args.dry_run:
        print("  dry-run — agy was not called")
        return 0

    prompt = BRIEF.format(question=args.question) + packed
    try:
        # The prompt goes over stdin, never as an argv element. `-p "<prompt>"`
        # is bounded by the kernel's combined argv+environ budget, which is not
        # the packed payload's size alone — a shell carrying enough exported
        # variables can blow that budget on a payload under this file's own 1 MB
        # ceiling, and the failure is an opaque OSError, not this script's.
        proc = subprocess.run(
            ["agy", "--input-format", "text", "--output-format", "json", "--model", args.model],
            input=prompt, capture_output=True, text=True,
        )
    except FileNotFoundError:
        print("  ask: agy not found on PATH", file=sys.stderr)
        return 1

    if proc.returncode != 0:
        print("  ask: agy exited %d" % proc.returncode, file=sys.stderr)
        if proc.stderr.strip():
            print("  " + proc.stderr.strip(), file=sys.stderr)
        return 1

    try:
        data = json.loads(proc.stdout)
    except ValueError:
        print("  ask: agy did not return JSON", file=sys.stderr)
        print("  " + proc.stdout.strip()[:400], file=sys.stderr)
        return 1

    usage = data.get("usage") or {}
    tokens = usage.get("total_tokens")
    if tokens is None:
        tokens = (usage.get("input_tokens") or 0) + (usage.get("output_tokens") or 0)
    duration = data.get("duration_seconds") or 0

    print("  agy     %s · %s tok (Google) · %s" % (
        args.model, format(int(tokens), ","), fmt_duration(duration),
    ))

    status = data.get("status")
    if status != "SUCCESS":
        print("")
        print("  ask: agy did not succeed (status: %s)" % status, file=sys.stderr)
        detail = data.get("response") or data.get("error") or ""
        if detail:
            print("  " + str(detail), file=sys.stderr)
        return 1

    print("")
    for line in (data.get("response") or "").rstrip("\n").split("\n"):
        print("  " + line)
    print("")
    print("  spot-check a couple of these claims before trusting them")
    return 0


if __name__ == "__main__":
    sys.exit(main())
