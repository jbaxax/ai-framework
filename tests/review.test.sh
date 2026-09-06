#!/usr/bin/env bash
# Tests for `fw review`. CLAUDE.md §1.2 calls the dependency rule "verifiable,
# not aspirational", and until this command it was the one rule with no
# verifier. A checker that silently stops after the third finding, or that reads
# a comment as an import, is worse than none: it reports a clean run.
set -uo pipefail

FW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FW_SRC="${FW_REVIEW_BIN:-$FW_ROOT/bin/fw}"
FW_BIN="$(mktemp)"; tr -d '\r' < "$FW_SRC" > "$FW_BIN"; chmod +x "$FW_BIN"

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

fixture() {
  local d; d="$(mktemp -d)"
  git -C "$d" init -q
  git -C "$d" config user.email t@t.t
  git -C "$d" config user.name t
  mkdir -p "$d/src/features/diet/domain" "$d/src/features/diet/application" \
           "$d/src/features/diet/infrastructure" "$d/src/features/diet/presentation"
  printf 'base\n' > "$d/README.md"
  git -C "$d" add -A >/dev/null 2>&1; git -C "$d" commit -qm base >/dev/null 2>&1
  printf '%s' "$d"
}
write() { printf '%s\n' "$3" > "$1/$2"; }
run()   { ( cd "$1" && "$FW_BIN" review 2>&1 | sed 's/\x1b\[[0-9;]*m//g' ); }

F=src/features/diet

printf '\nfw review\n'

# --- the two patterns CLAUDE.md quotes as FORBIDDEN --------------------------
d=$(fixture)
write "$d" "$F/application/useMeals.ts" 'import { UpdateUserInput } from "../presentation/schemas/profileSchema";'
write "$d" "$F/domain/calories.ts" 'import { Tables } from "../../../lib/supabase/types";'
out=$(run "$d")
check "application importing a schema from presentation" "$out" "input types belong to domain"
check "database types leaking into domain" "$out" "it leaves domain/"
check "and the run fails" "$out" "**Verdict: FAIL**"

# --- the other two directions ------------------------------------------------
d=$(fixture)
write "$d" "$F/infrastructure/repo.ts" 'import { useMeals } from "../application/useMeals";'
write "$d" "$F/presentation/List.tsx" 'import { svc } from "../infrastructure/dietService";'
out=$(run "$d")
check "infrastructure importing application" "$out" "infrastructure may only depend on domain"
check "presentation importing infrastructure" "$out" "presentation goes through application"

# --- domain is pure of libraries too ----------------------------------------
d=$(fixture)
write "$d" "$F/domain/rules.ts" 'import { z } from "zod";'
out=$(run "$d")
check "domain importing a library is a finding" "$out" "domain declares its own types"

# --- and a domain file that obeys is silent ---------------------------------
d=$(fixture)
write "$d" "$F/domain/rules.ts" 'import { total } from "./calories";'
out=$(run "$d")
check "the clean file is still reviewed" "$out" "comparing against"
check "and passes" "$out" "**Verdict: PASS**"
refute "with no invented finding" "$out" "domain imports"

# --- §1.2: import statements, not text --------------------------------------
# The rule warns that a text search for HttpClient also matches the comment
# saying a file must never import it.
d=$(fixture)
write "$d" "$F/domain/rules.ts" 'export const n: number = 1;'
out=$(run "$d")
check "a domain file with no import passes" "$out" "**Verdict: PASS**"
refute "and nothing is read as an import" "$out" "domain imports"

# --- a feature barrel --------------------------------------------------------
d=$(fixture)
write "$d" "$F/index.ts" 'export * from "./domain/calories";'
out=$(run "$d")
check "a feature barrel is a finding" "$out" "hides dependency violations"

# --- any, and what merely contains those three letters ----------------------
d=$(fixture)
write "$d" "$F/application/a.ts" 'const cache: any = {};'
out=$(run "$d")
check "an any annotation is a finding" "$out" "use \`unknown\` and narrow"
d=$(fixture)
write "$d" "$F/application/b.ts" 'const company = "many things";'
out=$(run "$d")
check "the clean file is reviewed" "$out" "comparing against"
refute "and a word containing any is not one" "$out" "use \`unknown\` and narrow"

# --- comments, and the exceptions a tool reads ------------------------------
d=$(fixture)
write "$d" "$F/application/c.ts" '// esto calcula el total'
out=$(run "$d")
check "a comment is a finding" "$out" "rename or extract until the code"
d=$(fixture)
write "$d" "$F/application/d.ts" '// @ts-expect-error upstream types are wrong'
out=$(run "$d")
check "the file is reviewed" "$out" "comparing against"
refute "but a tool-read pragma is not a comment" "$out" "rename or extract until the code"

# --- tests are exempt --------------------------------------------------------
d=$(fixture)
write "$d" "$F/domain/rules.spec.ts" 'import { z } from "zod";'
out=$(run "$d")
check "the run happens" "$out" "comparing against"
refute "a spec may import whatever it needs" "$out" "domain declares its own types"

# --- only the added lines ----------------------------------------------------
# §4.4 forbids restructuring existing code as a side effect, so a violation that
# was already committed is not this change's business.
d=$(fixture)
write "$d" "$F/domain/old.ts" 'import { z } from "zod";'
git -C "$d" add -A >/dev/null 2>&1; git -C "$d" commit -qm "pre-existing" >/dev/null 2>&1
git -C "$d" push >/dev/null 2>&1 || true
write "$d" "$F/domain/new.ts" 'export const n = 1;'
out=$(run "$d")
check "the new file is reviewed" "$out" "comparing against"
refute "a pre-existing violation in an untouched file is not raised" "$out" "old.ts"

# --- nothing to review -------------------------------------------------------
d=$(fixture)
out=$(run "$d")
check "with nothing added it says so" "$out" "nothing to review"
refute "and reports no verdict" "$out" "Verdict:"

# --- every finding is reported, not just the first --------------------------
# A checker that stops early reports a clean run for everything after it.
d=$(fixture)
write "$d" "$F/domain/one.ts" 'import { z } from "zod";'
write "$d" "$F/domain/two.ts" 'import { y } from "yup";'
write "$d" "$F/application/three.ts" 'const c: any = 1;'
out=$(run "$d")
check "the first finding is reported" "$out" "one.ts"
check "and the second" "$out" "two.ts"
check "and the one after them" "$out" "three.ts"

rm -f "$FW_BIN"
printf '\n%s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
