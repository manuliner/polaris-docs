#!/usr/bin/env bash
# Scaffold the three canonical skills + the _shared asset folder under <repo>/.cursor/skills/.
# _shared holds the shared scripts/reference ONCE; skills reference it (no per-skill duplication).
set -euo pipefail

REPO_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
DOCS_INIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

DEST_BASE="$REPO_ROOT/.cursor/skills"
SHARED_SRC="$DOCS_INIT_ROOT/templates/_shared"

mkdir -p "$DEST_BASE"

# 1. Shared asset folder — copied ONCE, not into each skill.
rsync -a --delete "$SHARED_SRC/" "$DEST_BASE/_shared/"
echo "scaffold-repo-skills: installed _shared asset folder"

# 2. The three canonical skills — only their SKILL.md (scripts/reference live in _shared).
install_skill() {
  local name="$1"
  local template_dir="$2"
  local target="$DEST_BASE/$name"
  mkdir -p "$target"
  if [[ -f "$template_dir/skill.template.md" ]]; then
    cp -f "$template_dir/skill.template.md" "$target/SKILL.md"
  else
    echo "scaffold: missing skill.template.md in $template_dir" >&2
    exit 1
  fi
}

install_skill docs-write  "$DOCS_INIT_ROOT/templates/docs-write"
install_skill docs-verify "$DOCS_INIT_ROOT/templates/docs-verify"
install_skill docs-defrag "$DOCS_INIT_ROOT/templates/docs-defrag"

# 3. Seed docs/ hub if absent.
DOCS_TPL="$DOCS_INIT_ROOT/templates/docs"
mkdir -p "$REPO_ROOT/docs"
if [[ -f "$DOCS_TPL/README.template.md" && ! -f "$REPO_ROOT/docs/README.md" ]]; then
  cp -f "$DOCS_TPL/README.template.md" "$REPO_ROOT/docs/README.md"
  echo "scaffold-repo-skills: seeded $REPO_ROOT/docs/README.md"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
"$SCRIPT_DIR/link-claude-bridge.sh" "$REPO_ROOT"

echo "scaffold-repo-skills: three skills + _shared installed under $DEST_BASE"

"$SCRIPT_DIR/integrate-harness.sh" "$REPO_ROOT"
while IFS= read -r line; do
  [[ "$line" =~ ^([A-Z_]+)=(.*)$ ]] && export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
done < <(bash "$SCRIPT_DIR/detect-harness.sh" "$REPO_ROOT")
echo "scaffold-repo-skills: workspace MODE=$MODE harness=${HARNESS_REL:-none} listed=${LISTED:-n/a}"
