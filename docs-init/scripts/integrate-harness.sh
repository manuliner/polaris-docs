#!/usr/bin/env bash
# Wire an L1 service repo to a detected L0 harness (profile + CLAUDE.md Workspace section).
set -euo pipefail

REPO_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOCS_INIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
TPL="$DOCS_INIT_ROOT/templates"

eval "$(bash "$SCRIPT_DIR/detect-harness.sh" "$REPO_ROOT")"

case "$MODE" in
  l0)
    echo "integrate-harness: L0 harness repo — skip L1 wiring"
    exit 0
    ;;
  standalone)
    echo "integrate-harness: standalone — no harness under parent (run workspace-init full first for multi-repo)"
    exit 0
    ;;
  l1) ;;
  *)
    echo "integrate-harness: unknown MODE=$MODE" >&2
    exit 1
    ;;
esac

PROFILE="$REPO_ROOT/.cursor/agent-profile.json"
CLAUDE="$REPO_ROOT/CLAUDE.md"

if [[ ! -f "$PROFILE" ]]; then
  command -v jq >/dev/null 2>&1 || { echo "integrate-harness: jq required" >&2; exit 1; }
  mkdir -p "$REPO_ROOT/.cursor"
  jq --arg hp "$HARNESS_REL" '.harnessPath = $hp' "$TPL/agent-profile.service.json" > "$PROFILE"
  echo "integrate-harness: wrote $PROFILE (harnessPath=$HARNESS_REL)"
else
  echo "integrate-harness: profile exists — skipped ($PROFILE)"
fi

if [[ "$LISTED" == "no" ]]; then
  echo "integrate-harness [WARN]: $REPO_NAME not listed in $HARNESS_ABS/WORKSPACE.md — run workspace-init sync"
fi

WORKSPACE_SECTION="$TPL/claude-workspace-section.md"
if [[ ! -f "$CLAUDE" ]]; then
  cat > "$CLAUDE" <<EOF
# $REPO_NAME

Service repository in the \`privat/\` workspace.

$(sed "s|{{HARNESS_PATH}}|$HARNESS_REL|g" "$WORKSPACE_SECTION")

## Doc Skills

| Skill | Verb | When to use |
|-------|------|-------------|
| \`/docs-write\` | adds | New leaf under \`docs/\`, ADR, or refresh \`docs/AGENTS_*.md\` |
| \`/docs-verify\` | checks | Pre-commit/merge gate, layout + SSOT (\`--scope=staged\\|branch\`) |
| \`/docs-defrag\` | removes/merges | Consolidate, archive, dead paths, drift audit |

(\`_shared\` is an asset folder, not a selectable skill.)
EOF
  echo "integrate-harness: created $CLAUDE with Workspace section"
  exit 0
fi

if grep -q '^## Workspace' "$CLAUDE" 2>/dev/null; then
  echo "integrate-harness: CLAUDE.md already has ## Workspace — skipped"
  exit 0
fi

python3 <<PY
from pathlib import Path
repo = Path("$REPO_ROOT")
claude = repo / "CLAUDE.md"
section = Path("$WORKSPACE_SECTION").read_text().replace("{{HARNESS_PATH}}", "$HARNESS_REL")
text = claude.read_text()
markers = ["\n## Invariants", "\n## Doc Skills", "\n## Commands"]
insert_at = len(text)
for m in markers:
    i = text.find(m)
    if i != -1:
        insert_at = min(insert_at, i)
if insert_at == len(text):
    text = text.rstrip() + "\n\n" + section.strip() + "\n"
else:
    text = text[:insert_at].rstrip() + "\n\n" + section.strip() + "\n" + text[insert_at:].lstrip("\n")
claude.write_text(text)
print("integrate-harness: patched CLAUDE.md with ## Workspace")
PY
