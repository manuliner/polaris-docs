#!/usr/bin/env bash
# self-check.sh — the SSOT repo dogfoods its own rules. READ-ONLY, exit-code.
# Run by the pre-commit hook; a commit that violates the tooling's own rules or whose registry has
# drifted from reality is blocked before it can ever reach origin/HEAD and distribute to satellites.
#
# Part A: apply the pattern engine to the SSOT's OWN files (patterns.ssot.yaml scope).
# Part B: self-consistency of the registries (patterns.yaml / patterns.ssot.yaml / manifest.json).
set -euo pipefail

SSOT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$SSOT_ROOT"
SHARED="docs-init/templates/_shared"
PATTERNS="$SHARED/reference/patterns.yaml"
SSOT_PATTERNS="patterns.ssot.yaml"
MANIFEST="manifest.json"

ERRORS=0
err() { echo "self-check [ERROR]: $*" >&2; ERRORS=$((ERRORS + 1)); }
ok()  { echo "self-check: $*"; }

# ---- Part A: patterns on our own files -------------------------------------------------
if [[ -x "$SHARED/scripts/verify-patterns.sh" && -f "$SSOT_PATTERNS" ]]; then
  if REPO_ROOT="$SSOT_ROOT" PATTERNS_FILE="$SSOT_ROOT/$SSOT_PATTERNS" \
       bash "$SHARED/scripts/verify-patterns.sh"; then
    ok "Part A: SSOT files obey patterns.ssot.yaml"
  else
    err "Part A: SSOT files violate patterns.ssot.yaml (see above)"
  fi
else
  err "Part A: missing verify-patterns.sh or patterns.ssot.yaml"
fi

# ---- Part B: registry self-consistency -------------------------------------------------
command -v python3 >/dev/null 2>&1 || { err "python3 required for Part B"; }

if command -v python3 >/dev/null 2>&1; then
  B_OUT="$(SSOT_ROOT="$SSOT_ROOT" PATTERNS="$PATTERNS" SSOT_PATTERNS="$SSOT_PATTERNS" \
           MANIFEST="$MANIFEST" python3 "$SSOT_ROOT/scripts/self-check-registry.py")" || true
  TAB=$'\t'
  if [[ -n "$B_OUT" ]]; then
    while IFS= read -r line; do
      [[ "$line" == "DRIFT${TAB}"* ]] && err "Part B: ${line#DRIFT${TAB}}"
    done <<< "$B_OUT"
  else
    ok "Part B: registries consistent (canonical-skills, refs, manifest coverage)"
  fi
fi

if [[ $ERRORS -gt 0 ]]; then
  echo "self-check: FAILED ($ERRORS error(s))"
  exit 1
fi
echo "self-check: PASS"
