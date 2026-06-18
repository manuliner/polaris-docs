#!/usr/bin/env bash
# Scaffold the four canonical skills + the _shared asset folder under <repo>/.cursor/skills/.
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

# 2. The four canonical skills — only their SKILL.md (scripts/reference live in _shared).
install_skill() {
  local name="$1"
  local template_dir="$2"
  local target="$DEST_BASE/$name"
  mkdir -p "$target"
  # A canonical skill holds ONLY SKILL.md; scripts/reference live once in _shared. If this skill
  # pre-exists from the old per-skill-duplicated layout, drop its stale scripts/reference/README.shared.
  for stale in scripts reference README.shared.md; do
    if [[ -e "$target/$stale" ]]; then
      find "$target/$stale" -depth -delete 2>/dev/null || true
      echo "scaffold: pruned stale $name/$stale (lives in _shared now)"
    fi
  done
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
install_skill docs-commit "$DOCS_INIT_ROOT/templates/docs-commit"

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

# 3. Seed docs/ hub if absent. The hub is docs/_index.md (the underscore marks it a structure file,
#    not the human-facing root README — they must not be conflated).
DOCS_TPL="$DOCS_INIT_ROOT/templates/docs"
mkdir -p "$REPO_ROOT/docs"
if [[ -f "$DOCS_TPL/_index.template.md" && ! -f "$REPO_ROOT/docs/_index.md" ]]; then
  cp -f "$DOCS_TPL/_index.template.md" "$REPO_ROOT/docs/_index.md"
  echo "scaffold-repo-skills: seeded $REPO_ROOT/docs/_index.md"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
"$SCRIPT_DIR/link-claude-bridge.sh" "$REPO_ROOT"

echo "scaffold-repo-skills: four skills + _shared installed under $DEST_BASE"

"$SCRIPT_DIR/integrate-harness.sh" "$REPO_ROOT"
while IFS= read -r line; do
  [[ "$line" =~ ^([A-Z_]+)=(.*)$ ]] && export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
done < <(bash "$SCRIPT_DIR/detect-harness.sh" "$REPO_ROOT")
echo "scaffold-repo-skills: workspace MODE=$MODE harness=${HARNESS_REL:-none} listed=${LISTED:-n/a}"

# 4. Install the pre-commit staleness hook (always, only in git repos). It WARNS when a commit touches
#    code a doc leaf documents; it never blocks. We insert a marker-bounded block into the repo's
#    native .git/hooks/pre-commit instead of setting core.hooksPath, so it coexists with any existing
#    hook manager (husky/lefthook/etc.). Idempotent: the block is added at most once.
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # The vendored hook script must be executable (it has no .sh suffix, so generic chmod passes miss it).
  chmod +x "$DEST_BASE/_shared/scripts/hooks/pre-commit-staleness" 2>/dev/null || true
  HOOK_PATH="$REPO_ROOT/$(git -C "$REPO_ROOT" rev-parse --git-path hooks/pre-commit)"
  MARK_BEGIN="# >>> polaris-docs staleness (managed) >>>"
  MARK_END="# <<< polaris-docs staleness <<<"
  HOOK_CALL='"$(git rev-parse --show-toplevel)/.cursor/skills/_shared/scripts/hooks/pre-commit-staleness" || true'

  mkdir -p "$(dirname "$HOOK_PATH")"
  if [[ ! -f "$HOOK_PATH" ]]; then
    {
      echo "#!/usr/bin/env bash"
      echo "$MARK_BEGIN"
      echo "$HOOK_CALL"
      echo "$MARK_END"
    } > "$HOOK_PATH"
    chmod +x "$HOOK_PATH"
    echo "scaffold-repo-skills: created .git/hooks/pre-commit with staleness hook"
  elif ! grep -qF "$MARK_BEGIN" "$HOOK_PATH"; then
    {
      echo ""
      echo "$MARK_BEGIN"
      echo "$HOOK_CALL"
      echo "$MARK_END"
    } >> "$HOOK_PATH"
    chmod +x "$HOOK_PATH"
    echo "scaffold-repo-skills: appended staleness hook to existing .git/hooks/pre-commit"
  else
    echo "scaffold-repo-skills: staleness hook already present in .git/hooks/pre-commit"
  fi

  # If the repo routes hooks elsewhere, our insert into .git/hooks/ may not run. Warn so the user can
  # wire the call into their active hooks path manually.
  HP="$(git -C "$REPO_ROOT" config --get core.hooksPath || true)"
  if [[ -n "$HP" ]]; then
    echo "scaffold-repo-skills: NOTE core.hooksPath='$HP' is set — the native .git/hooks/pre-commit"
    echo "  may be bypassed. Add this line to your active pre-commit hook to keep the warning:"
    echo "    $HOOK_CALL"
  fi

  # Keep the marker file out of version control (repo-local agent signal, not committed).
  EXCL="$REPO_ROOT/$(git -C "$REPO_ROOT" rev-parse --git-path info/exclude)"
  mkdir -p "$(dirname "$EXCL")"
  if [[ ! -f "$EXCL" ]] || ! grep -qF '.cursor/skills/.staleness-pending' "$EXCL"; then
    echo '.cursor/skills/.staleness-pending' >> "$EXCL"
  fi
fi
