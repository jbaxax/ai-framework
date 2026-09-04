#!/usr/bin/env bash
set -uo pipefail

# UserPromptSubmit. Anything printed here is injected into the agent's context
# before it answers. Never exit non-zero: a broken guard must not eat a prompt.

payload="$(cat 2>/dev/null || true)"

PLAN_REQUEST='(elabor|hac|haz|arm|cre|prepar)[^[:space:]]*[[:space:]]+(un[[:space:]]+)?plan([^a-zA-Z]|$)|make[[:space:]]+a[[:space:]]+plan([^a-zA-Z]|$)'

printf '%s' "$payload" | grep -qiE "$PLAN_REQUEST" || exit 0

cat <<'REMINDER'
fw — a plan was requested. Before writing any step, state in one line which row
applies. A plan whose target was never restated is a list of steps toward a goal
nobody wrote down.

| The request is | The plan opens with |
|---|---|
| New capability — a doc, an image, a pasted case, prose | Acceptance criteria and a user story on disk. `skills/requirements`, then `fw product hu <epic>`. Steps come after, and reference the criteria by number |
| A bug, a correction, something broken | `skills/diagnosis` — a red reproduction before any theory of the cause. No user story |
| Maintenance or refactor of existing code | Read it first. Approval tests before production code is touched. `skills/testing` decides the mode |

Do not invent a criterion to fill a gap. List the gap as a question.
Say which row you chose and why, in that one line, before the plan.
REMINDER
