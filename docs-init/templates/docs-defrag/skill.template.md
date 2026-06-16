---
name: docs-defrag
description: Consolidate, archive, merge, and prune documentation; remove orphaned paths while preserving MOC coherence. The "removes/merges" skill. Use docs-write to add, docs-verify to check.
---

# docs-defrag

The **removes/merges** skill: subtractive and structural cleanup. It does not author new leaves
(that is `docs-write`) and is not the pre-commit/merge gate (that is `docs-verify`).

## Workflow

1. Inventory leaves via MOC; mark candidates for merge/archive (see
   `_shared/reference/agent-doc-layout.md`).
2. Run `_shared/scripts/check-dead-paths.sh` after moves; fix broken relative links.
3. Re-run `_shared/scripts/verify-docs-principles.sh` to ensure hubs still resolve.
4. Flag root `ARCHITECTURE.md` / `DEPLOYMENT.md` or duplicated codemap prose as SSOT violations.
   (Detection is owned by `docs-verify`/`verify-docs.sh`; defrag acts on the findings.)

## Scripts

- `_shared/scripts/check-dead-paths.sh`
- `_shared/scripts/verify-docs-principles.sh`

> Phases F/G/I add to this skill: pattern audit (`verify-patterns.sh`), tooling self-update
> (HEAD-check + merge), and the doc-to-code drift loop (`check-doc-staleness.sh` → docs-write update
> proposal). Those steps are layered in by later phases, not Phase H.

## Canonical set

One of **three** canonical skills (`docs-write`, `docs-verify`, `docs-defrag`) plus the `_shared`
asset folder.
