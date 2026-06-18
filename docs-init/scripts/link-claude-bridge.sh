#!/usr/bin/env bash
# Symlink repo .cursor/skills/<canonical-four> → ~/.claude/skills/<name>
# _shared is an asset folder (no SKILL.md), not bridged as a selectable skill.
set -euo pipefail

REPO_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
SKILLS_DIR="$REPO_ROOT/.cursor/skills"
CLAUDE_SKILLS="${CLAUDE_SKILLS:-$HOME/.claude/skills}"

CANON=(
  docs-write
  docs-verify
  docs-defrag
  docs-commit
)

mkdir -p "$CLAUDE_SKILLS"
for name in "${CANON[@]}"; do
  src="$SKILLS_DIR/$name"
  dest="$CLAUDE_SKILLS/$name"
  if [[ ! -d "$src" ]]; then
    echo "link-claude-bridge: missing $src — run scaffold-repo-skills.sh first" >&2
    exit 1
  fi
  if [[ -L "$dest" ]] || [[ -e "$dest" ]]; then
    rm -rf "$dest"
  fi
  ln -s "$src" "$dest"
  echo "link-claude-bridge: $dest -> $src"
done
