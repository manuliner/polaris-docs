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

# 2b. Provenance: record which SSOT version was vendored here. docs-defrag reads this on its
#     next run to decide whether the SSOT has a newer HEAD (pull-update trigger, Phase D).
SSOT_ROOT="$(git -C "$DOCS_INIT_ROOT" rev-parse --show-toplevel 2>/dev/null || echo "")"
if [[ -n "$SSOT_ROOT" ]]; then
  ssot_commit="$(git -C "$SSOT_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")"
  ssot_version="$(tr -d '[:space:]' < "$SSOT_ROOT/VERSION" 2>/dev/null || echo "0.0.0")"
  ssot_origin="$(git -C "$SSOT_ROOT" config --get remote.origin.url 2>/dev/null || echo "(local-only)")"
else
  ssot_commit="unknown"
  ssot_version="0.0.0"
  ssot_origin="(no-ssot-git)"
fi
{
  echo "# polaris-docs tooling provenance — do not edit by hand."
  echo "# Written by scaffold-repo-skills.sh; updated by docs-defrag after a pull-update."
  echo "ssot_commit=$ssot_commit"
  echo "ssot_version=$ssot_version"
  echo "ssot_origin=$ssot_origin"
} > "$DEST_BASE/.tooling-version"
echo "scaffold-repo-skills: stamped .tooling-version (version=$ssot_version commit=${ssot_commit:0:7})"

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
