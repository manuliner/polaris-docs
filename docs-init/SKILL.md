---
name: docs-init
description: Bootstrap and maintain the canonical four-skill documentation system (docs-write/docs-verify/docs-defrag/docs-commit + _shared asset folder; L0 parent scan, phased rollout, Claude bridge).
---

# docs-init

Global installer and orchestrator for **four** canonical repository skills under `.cursor/skills/`: `docs-write` (adds), `docs-verify` (checks, `--scope=staged|branch`), `docs-defrag` (removes/merges), and `docs-commit` (commits staged code via the agent + catches doc-to-code drift), plus the `_shared` asset folder (scripts + reference, not a selectable skill). No `hybrid`, `docs-update`, `docs-concepts`, or the legacy `docs-shared`/`docs-pr-check`/`docs-writer` layouts.

## When to use

- New repo or team adopting the canonical doc skill tree
- Refreshing global templates after `docs-init` updates
- Re-linking `~/.claude/skills/` bridge symlinks after clone or path changes

## Inputs

- Target repository root (optional; default: current working directory)
- Global bundle path: `~/.cursor/skills/docs-init` (or override via `DOCS_INIT_ROOT`)

## L0 — Parent scan (before any write)

1. Resolve **repository root** (`git rev-parse --show-toplevel` or explicit argument).
2. Run **`scripts/detect-harness.sh`** — sets workspace role: `l0` (harness repo), `l1` (service linked to sibling harness), or `standalone`.
3. Confirm `.cursor/` exists or create it; never write outside the repo root without explicit user consent.
4. Detect existing skills: if non-canonical names exist, **do not** auto-delete; report and let the user remove `hybrid` / legacy layouts manually.
5. Read `.cursor/agent-profile.json` if present for `autoSections` and verification gates.
6. After scaffold, run **`scripts/integrate-harness.sh`** when `MODE=l1` (writes L1 profile + `CLAUDE.md` Workspace section if missing).

Does **not** create the harness — use **`workspace-init full`** first for multi-repo setups. See `reference/harness-integration.md`.

## Six phases

| Phase | Goal |
| ----- | ------ |
| **1 — Install bundle** | Run `install.sh` to sync `~/.cursor/skills/docs-init` and mirror `~/.claude/skills/docs-init` when paths differ. |
| **2 — Scaffold skills** | Run `scripts/scaffold-repo-skills.sh <repo-root>`; installs the `_shared` asset folder + four skills, runs `integrate-harness.sh`, reports workspace MODE. |
| **3 — Bridge** | Run `scripts/link-claude-bridge.sh <repo-root>` (also invoked by scaffold); symlink each of the four skills into `~/.claude/skills/<name>`. |
| **4 — Verify** | Execute `templates/_shared/scripts/verify-docs.sh` from the repo-skills copy (profile, L1/L3, skills, rules, forbidden paths, Claude symlinks). |
| **5 — Auto sections** | Run `check-auto-sections.sh` where agent profiles define `autoSections`. |
| **6 — Rollout** | Follow `reference/rollout-stages.md` and `token-efficiency.md` (MOC pattern) for staged adoption. |

## Commands (reference)

```bash
/path/to/docs-init/install.sh
DOCS_INIT_ROOT=~/.cursor/skills/docs-init "$DOCS_INIT_ROOT/scripts/scaffold-repo-skills.sh" /path/to/repo
"$HOME/.cursor/skills/docs-init/scripts/link-claude-bridge.sh" /path/to/repo
```

## Boundaries

- **Three skills only** (`docs-write`, `docs-verify`, `docs-defrag`) + the `_shared` asset folder; extend behavior via scripts in `_shared`, not new top-level skill folders.
- Token-efficient navigation: use Maps of Content (MOC) in docs and in verification output (see `reference/token-efficiency.md`).
- Forbidden paths and symlink targets are enforced by `verify-docs.sh` (see templates).

## References

- `reference/canonical-structure.md` — repo tree contract
- `reference/token-efficiency.md` — MOC + skimming
- `reference/rollout-stages.md` — phased adoption
- `reference/research.md` — how to gather external doc sources
- `reference/harness-integration.md` — L0/L1 harness detection and wiring
- `reference/rules-templates.md` — Cursor rules snippets
