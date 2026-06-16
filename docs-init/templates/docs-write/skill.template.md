---
name: docs-write
description: Author NEW documentation — leaves, ADRs, runbooks — using MOC-first structure. The "adds" skill. Use docs-defrag to consolidate or remove, docs-verify to check.
---

# docs-write

The **adds** skill: creates new documentation. It does not consolidate or delete (that is
`docs-defrag`) and does not gate changes (that is `docs-verify`).

## Workflow

1. Read `_shared/reference/agent-doc-layout.md` — leaves under `docs/`, hubs link only.
2. Pick doc type via `_shared/reference/doc-type-selector.md`.
3. Create a leaf under `docs/`; add one line + link to `docs/README.md` (or layer codemap).
   For code-adjacent leaves (architecture, codemaps) set `sources:` front-matter so the
   self-healing drift check (`docs-defrag`) can track them.
4. Follow the patterns in `_shared/reference/patterns.yaml` (line-count, frontmatter, heading depth),
   then run `_shared/scripts/verify-patterns.sh` and `_shared/scripts/verify-docs.sh`
   (+ `check-auto-sections.sh` if the profile defines `autoSections`).

## Update mode (driven by docs-defrag)

When `docs-defrag` finds a stale leaf, it invokes docs-write in **update mode** with the code diff
of the leaf's `sources` as context, producing a patch *proposal* (never an auto-commit).

## Canonical set

One of **three** canonical skills (`docs-write`, `docs-verify`, `docs-defrag`) plus the `_shared`
asset folder.
