#!/usr/bin/env bash
# Install or refresh docs-init + workspace-init global skill bundles.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SRC_WORKSPACE="$(dirname "$SRC")/workspace-init"
CURSOR="${CURSOR_SKILLS_DIR:-$HOME/.cursor/skills}"
CLAUDE="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

realpath_safe() { (cd "$1" 2>/dev/null && pwd -P) || echo "$1"; }

install_bundle() {
  local name="$1" src="$2"
  local src_real dest_cursor dest_claude
  src_real="$(realpath_safe "$src")"
  dest_cursor="$CURSOR/$name"
  dest_claude="$CLAUDE/$name"
  if [[ "$(realpath_safe "$dest_cursor")" != "$src_real" ]]; then
    mkdir -p "$CURSOR"
    rsync -a --delete "$src/" "$dest_cursor/"
    echo "docs-init: installed $name → $dest_cursor"
  else
    echo "docs-init: in place $name → $dest_cursor"
  fi
  mkdir -p "$CLAUDE"
  rsync -a --delete "$dest_cursor/" "$dest_claude/"
  echo "docs-init: mirrored $name → $dest_claude"
  chmod +x "$dest_cursor/install.sh" 2>/dev/null || true
  find "$dest_cursor/scripts" -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  find "$dest_cursor/templates" -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
}

install_bundle docs-init "$SRC"
if [[ -d "$SRC_WORKSPACE" ]]; then
  install_bundle workspace-init "$SRC_WORKSPACE"
else
  echo "docs-init [WARN]: workspace-init not found at $SRC_WORKSPACE — harness bootstrap unavailable"
fi
echo "Done. Multi-repo: workspace-init full, then docs-init cursor full per service repo."
