---
name: docs-defrag
description: Consolidate, archive, merge, and prune documentation; remove orphaned paths while preserving MOC coherence. The "removes/merges" skill. Use docs-write to add, docs-verify to check.
---

# docs-defrag

The **removes/merges** skill: subtractive and structural cleanup. It does not author new leaves
(that is `docs-write`) and is not the pre-commit/merge gate (that is `docs-verify`).

## Step 0 — Tooling self-update (run FIRST, before any doc work)

The tooling lives in a central SSOT repo; this satellite vendored a copy. Before defragging docs,
check whether the SSOT advanced and, if so, pull the update into THIS repo only (pull model, never
pushed). All steps below are read-only until the explicit merge in 0d.

**0a. Locate the SSOT and compare HEADs.**
- Resolve the SSOT repo: `realpath ~/.claude/skills/docs-init` → its git toplevel.
- If a remote exists: `git -C <ssot> fetch --quiet` then read `git -C <ssot> rev-parse origin/HEAD`.
  No remote (origin = `(local-only)` in `.tooling-version`): fall back to local `HEAD`.
- Read `ssot_commit` from `<repo>/.cursor/skills/.tooling-version`.
- **Equal → no update.** Skip to the doc workflow (step 1). Report "tooling up to date".

**0b. Survey the delta (read-only).** Run the diff helper; it classifies every vendored file:
```
SSOT_ROOT=<ssot> REPO_ROOT=<repo> .cursor/skills/_shared/scripts/diff-tooling.sh
```
Each line is `<relpath>\t<class>\t<status>`. Class comes from the SSOT `manifest.json`
(`managed` = take upstream hard; `local-overridable` = preserve local edits + merge upstream).
Status is `same | upstream-changed | local-changed | both-changed | new-upstream | removed-upstream`.

**0c. Decide per file (context-sensitive, do NOT blindly copy):**
| class | status | action |
|-------|--------|--------|
| any | `same` / `local-changed` (no upstream change) | leave the local file untouched |
| `managed` | `upstream-changed` / `new-upstream` | take the SSOT version hard (`git -C <ssot> show HEAD:<src>`) |
| `local-overridable` | `upstream-changed` | take upstream (no local edit to preserve) |
| `local-overridable` | `both-changed` | **merge semantically**: keep the local adaptation, fold in the upstream improvement. Read both versions, reconcile by intent. A genuine conflict you cannot reconcile is **reported to the human, not overwritten**. |
| `managed` | `local-changed` | local fork of a contract file → report it, then overwrite with upstream (managed wins) |
| any | `removed-upstream` | report; remove only after confirming it is not locally relied on |

**0d. Apply** the decided changes to the satellite's `.cursor/skills/` (the only write in step 0).
The SSOT-path for a vendored file: `_shared/*` ← `docs-init/templates/_shared/*`;
`<skill>/SKILL.md` ← `docs-init/templates/<skill>/skill.template.md`.

**0e. Re-stamp + verify.** Rewrite `.cursor/skills/.tooling-version` `ssot_commit` to the new HEAD
(keep the file's format), then run `_shared/scripts/verify-docs.sh` so the update did not break the
structural gate. Report what was taken-hard, merged, and any conflicts left for the human.

> Only this satellite is updated; other repos stay put until their own defrag runs.

## Workflow

1. Inventory leaves via MOC; mark candidates for merge/archive (see
   `_shared/reference/agent-doc-layout.md`).
2. Run `_shared/scripts/check-dead-paths.sh` after moves; fix broken relative links.
3. Re-run `_shared/scripts/verify-docs-principles.sh` to ensure hubs still resolve.
4. Flag root `ARCHITECTURE.md` / `DEPLOYMENT.md` or duplicated codemap prose as SSOT violations.
   (Detection is owned by `docs-verify`/`verify-docs.sh`; defrag acts on the findings.)

## Scripts

- `_shared/scripts/diff-tooling.sh` (step 0, read-only 3-way classify vs. SSOT)
- `_shared/scripts/check-dead-paths.sh`
- `_shared/scripts/verify-docs-principles.sh`
- `_shared/scripts/verify-docs.sh` (step 0e re-verify)

> Phases F/I still add to this skill: pattern audit (`verify-patterns.sh`) and the doc-to-code drift
> loop (`check-doc-staleness.sh` → docs-write update proposal). The tooling self-update (step 0) is
> already in place.

## Canonical set

One of **three** canonical skills (`docs-write`, `docs-verify`, `docs-defrag`) plus the `_shared`
asset folder.
