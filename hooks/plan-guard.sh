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
