#!/usr/bin/env bash
# Detect L0 workspace harness relative to a service repo.
# Output: KEY=value lines suitable for eval (MODE, REPO_NAME, HARNESS_ABS, HARNESS_REL, LISTED).
set -euo pipefail

REPO_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
PARENT="$(cd "$REPO_ROOT/.." && pwd -P)"
REPO_NAME="$(basename "$REPO_ROOT")"

HARNESS_NAMES=(platform-harness workspace-harness harness)
MODE=standalone
HARNESS_ABS=""
HARNESS_REL=""
LISTED=no

if [[ -n "${HARNESS_PATH:-}" ]]; then
  candidate="$(cd "$REPO_ROOT" && cd "$HARNESS_PATH" 2>/dev/null && pwd -P)" || candidate=""
  if [[ -n "$candidate" && -f "$candidate/WORKSPACE.md" ]]; then
    HARNESS_ABS="$candidate"
    HARNESS_REL="$(python3 -c "import os; print(os.path.relpath('$HARNESS_ABS', '$REPO_ROOT'))")"
    MODE=l1
  fi
fi

if [[ -f "$REPO_ROOT/WORKSPACE.md" ]] && [[ -f "$REPO_ROOT/.cursor/agent-profile.json" ]]; then
  role="$(jq -r '.role // empty' "$REPO_ROOT/.cursor/agent-profile.json" 2>/dev/null || true)"
  wm="$(jq -r '.workspaceMode // empty' "$REPO_ROOT/.cursor/agent-profile.json" 2>/dev/null || true)"
  if [[ "$role" == "l0" || "$wm" == "harness" ]]; then
    echo "MODE=l0"
    echo "REPO_NAME=$REPO_NAME"
    echo "HARNESS_ABS=$REPO_ROOT"
    echo "HARNESS_REL=."
    echo "LISTED=n/a"
    exit 0
  fi
fi

if [[ "$MODE" == "standalone" ]]; then
  for name in "${HARNESS_NAMES[@]}"; do
    candidate="$PARENT/$name"
    [[ -f "$candidate/WORKSPACE.md" ]] || continue
    role="$(jq -r '.role // empty' "$candidate/.cursor/agent-profile.json" 2>/dev/null || true)"
    wm="$(jq -r '.workspaceMode // empty' "$candidate/.cursor/agent-profile.json" 2>/dev/null || true)"
    if [[ "$role" == "l0" || "$wm" == "harness" || ( -z "$role" && -z "$wm" ) ]]; then
      HARNESS_ABS="$candidate"
      HARNESS_REL="$(python3 -c "import os; print(os.path.relpath('$HARNESS_ABS', '$REPO_ROOT'))")"
      MODE=l1
      break
    fi
  done
fi

if [[ "$MODE" == "l1" && -n "$HARNESS_ABS" ]]; then
  if grep -qF "../${REPO_NAME}/" "$HARNESS_ABS/WORKSPACE.md" 2>/dev/null \
     || grep -qE "\\| ${REPO_NAME} \\|" "$HARNESS_ABS/WORKSPACE.md" 2>/dev/null; then
    LISTED=yes
  fi
fi

echo "MODE=$MODE"
echo "REPO_NAME=$REPO_NAME"
echo "HARNESS_ABS=$HARNESS_ABS"
echo "HARNESS_REL=$HARNESS_REL"
echo "LISTED=$LISTED"
