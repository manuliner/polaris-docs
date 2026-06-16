#!/usr/bin/env bash
# Install polaris-docs onto this machine by SYMLINKING (SSOT = this repo, no copies).
#
# - docs-init (orchestrator) is symlinked into ~/.claude/skills AND ~/.cursor/skills.
# - The three doc skills are NOT symlinked globally here; they are vendored per repo by
#   scaffold-repo-skills.sh and bridged into ~/.claude/skills from the repo's vendored copy.
# - Legacy global symlinks from the pre-consolidation layout are removed.
set -euo pipefail

# Repo root = parent of this docs-init/ folder.
DOCS_INIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CLAUDE="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
CURSOR="${CURSOR_SKILLS_DIR:-$HOME/.cursor/skills}"

LEGACY=(docs-shared docs-sync docs-commit docs-pr-check docs-writer)

link_into() {
  local base="$1"
  local name="$2"
  local src="$3"
  local dest="$base/$name"
  mkdir -p "$base"
  if [[ -L "$dest" || -e "$dest" ]]; then
    rm -rf "$dest"
  fi
  ln -s "$src" "$dest"
  echo "install: $dest -> $src"
}

# 1. Orchestrator: symlink docs-init into both hosts (SSOT = repo).
link_into "$CLAUDE" docs-init "$DOCS_INIT"
link_into "$CURSOR" docs-init "$DOCS_INIT"

# 2. Remove legacy pre-consolidation global skill symlinks/dirs in both hosts.
for name in "${LEGACY[@]}"; do
  for base in "$CLAUDE" "$CURSOR"; do
    if [[ -L "$base/$name" || -e "$base/$name" ]]; then
      rm -rf "$base/$name"
      echo "install: removed legacy $base/$name"
    fi
  done
done

# 2b. Remove orphaned GLOBAL symlinks for the three current skills. These are bridged per-repo
#     by scaffold-repo-skills.sh (pointing at a repo's vendored copy), never globally. A global
#     one is a stale leftover (e.g. an old single-repo hub) and would shadow the correct per-repo link.
for name in docs-write docs-verify docs-defrag; do
  for base in "$CLAUDE" "$CURSOR"; do
    if [[ -L "$base/$name" ]]; then
      rm -f "$base/$name"
      echo "install: removed orphaned global skill symlink $base/$name"
    fi
  done
done

# 3. Make scripts executable in the repo (idempotent).
find "$DOCS_INIT/scripts" -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
find "$DOCS_INIT/templates" -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
chmod +x "$DOCS_INIT/install.sh" 2>/dev/null || true

echo "Done. docs-init symlinked from $DOCS_INIT."
echo "Next: scaffold a repo with scripts/scaffold-repo-skills.sh <repo-root> (vendors the 3 skills + _shared)."
