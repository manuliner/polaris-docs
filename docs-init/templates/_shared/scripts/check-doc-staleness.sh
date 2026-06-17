#!/usr/bin/env bash
# check-doc-staleness.sh — READ-ONLY. Detect doc-to-code drift (self-healing loop, Phase I).
#
# For each leaf under docs/ that declares `sources:` + `sources_stamp:` in its frontmatter, compare
# the git history of those source paths against the stamped commit. If a source has commits newer
# than the stamp, the leaf is STALE: its documented code moved on. Prints one block per stale leaf:
#     STALE <leaf>
#       sources: <paths>
#       range:   <stamp>..HEAD
#       commits: <n>
# Leaves without `sources` are skipped silently (no false alarm). Exit 0 always (advisory, not a gate);
# the count of stale leaves is printed on the last line as `stale=<n>` for the caller (docs-defrag).
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
cd "$REPO_ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "check-doc-staleness: not a git repo — staleness detection unavailable. stale=0"
  exit 0
fi

DOCS="${DOC_DOCS_DIR:-docs}"
if [[ ! -d "$DOCS" ]]; then
  echo "check-doc-staleness: no $DOCS/ directory. stale=0"
  exit 0
fi

stale=0

# Pull `sources:` (inline list) and `sources_stamp:` from a file's frontmatter via python (robust).
read_fm() {
  FM_FILE="$1" python3 - <<'PY'
import os, re, sys
txt = open(os.environ["FM_FILE"], encoding="utf-8", errors="replace").read()
m = re.match(r"^---\n(.*?)\n---", txt, re.S)
if not m:
    sys.exit(0)
fm = m.group(1)
src = re.search(r"^sources:\s*\[([^\]]*)\]", fm, re.M)
stamp = re.search(r"^sources_stamp:\s*(\S+)", fm, re.M)
if src:
    paths = [p.strip() for p in src.group(1).split(",") if p.strip()]
    print("SOURCES\t" + "\t".join(paths))
if stamp:
    print("STAMP\t" + stamp.group(1).strip())
PY
}

while IFS= read -r leaf; do
  rel="${leaf#"$REPO_ROOT"/}"
  out="$(read_fm "$leaf")"
  [[ "$out" == *"SOURCES"* ]] || continue          # no sources → skip silently

  sources=()
  stamp=""
  while IFS= read -r line; do
    case "$line" in
      SOURCES*) IFS=$'\t' read -r _ rest <<< "$line"; IFS=$'\t' read -r -a sources <<< "$rest" ;;
      STAMP*)   stamp="${line#STAMP$'\t'}" ;;
    esac
  done <<< "$out"

  if [[ -z "$stamp" ]]; then
    echo "STALE $rel"
    echo "  sources: ${sources[*]}"
    echo "  range:   (no sources_stamp — never verified against code)"
    stale=$((stale + 1))
    continue
  fi

  # Count commits touching any source path since the stamp.
  if ! git cat-file -e "$stamp^{commit}" 2>/dev/null; then
    echo "STALE $rel"
    echo "  sources: ${sources[*]}"
    echo "  range:   (sources_stamp '$stamp' not a known commit — re-stamp needed)"
    stale=$((stale + 1))
    continue
  fi
  n="$(git rev-list --count "$stamp"..HEAD -- "${sources[@]}" 2>/dev/null || echo 0)"
  if [[ "${n:-0}" -gt 0 ]]; then
    echo "STALE $rel"
    echo "  sources: ${sources[*]}"
    echo "  range:   ${stamp:0:9}..HEAD"
    echo "  commits: $n"
    stale=$((stale + 1))
  fi
done < <(find "$DOCS" -name '*.md' -not -name '_index.md' -not -path '*/.git/*' | sort)

echo "check-doc-staleness: stale=$stale"
