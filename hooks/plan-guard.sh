#!/usr/bin/env bash
set -uo pipefail

# UserPromptSubmit. Anything printed here is injected into the agent's context
# before it answers. Never exit non-zero: a broken guard must not eat a prompt.

payload="$(cat 2>/dev/null || true)"

PLAN_REQUEST='(elabor|hac|haz|arm|cre|prepar)[^[:space:]]*[[:space:]]+(un[[:space:]]+)?plan([^a-zA-Z]|$)|make[[:space:]]+a[[:space:]]+plan([^a-zA-Z]|$)'

printf '%s' "$payload" | grep -qiE "$PLAN_REQUEST" || exit 0

cat <<'REMINDER'
fw — a plan was requested. Before writing any step, say in one line which row
applies. A plan whose target was never restated is a list of steps toward a goal
nobody wrote down.

| The request is | The plan opens with |
|---|---|
| New capability — a doc, an image, a pasted case, prose | Acceptance criteria and a user story on disk: `skills/requirements`, then `fw product hu <epic>`. Steps come after and cite the criteria by number |
| A bug, a correction, something broken | `skills/diagnosis` — a red reproduction before any theory of the cause. No user story |
| Maintenance or refactor of existing code | Read it first. Approval tests before production code is touched; `skills/testing` decides the mode |

Name the blast radius before proposing steps. Where `graphify-out/` exists, ask
the graph instead of grepping: `graphify affected "<file or symbol>"` returns the
real dependents from the AST with file and line, at zero tokens, and was measured
more accurate than grep. Also `graphify explain "<X>"` for callers and
definition, `graphify god-nodes` for what is load-bearing, `graphify update
<path>` when the graph is stale. Use it to choose which files to open, then open
them — a node list is a map, not an explanation. No graph in the repository? Say
so in the same line: an unmeasured blast radius is an assumption, not a finding.

Interface work — layout, hierarchy, empty and error states, error copy,
accessibility — belongs to the `impeccable` skill. These rules decide where a
file goes and what it may import; they say nothing about whether the screen
works.

Questions are the exception, not the ritual. If the backend document or the
prompt already settles something, do not ask it — write the story and ask only
whether the story itself is right. Ask only where nothing you were given answers,
and never fill a gap with a plausible default. One question at a time.

The story is the frontend's half of the contract. A backend document says what
the API returns; it never says what the user may do, what happens with zero
results, who is allowed in, or what the screen shows while it waits. Writing it
down is how the project ends up documented on the side that had no document.

Close every plan with proof, not with the last step of the work: `fw evidence`,
and `fw mutate` on the files the criteria depend on. A criterion carrying a green
check and no killed mutant is not proven — it is unverified.
REMINDER
