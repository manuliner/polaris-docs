# Harness integration (L0 / L1)

Multi-repo workspaces use a two-layer doc model:

| Layer | Repo | Role | Key files |
|-------|------|------|-----------|
| **L0** | `platform-harness/` (or `workspace-harness/`, `harness/`) | Catalog + cross-service architecture | `WORKSPACE.md`, `docs/AGENTS_ARCHITECTURE.md`, `AGENTS.md` |
| **L1** | Each service repo | Local architecture + skills | `CLAUDE.md`, `docs/AGENTS_ARCHITECTURE.md`, `.cursor/agent-profile.json` |

## Rollout order

1. **`workspace-init full`** — create or refresh L0 harness under the parent of sibling git repos
2. **`docs-init cursor full`** — on each L1 service repo listed in `WORKSPACE.md`
3. **`/docs-bootstrap`** — per service, after docs-init

`docs-init` does **not** create or modify the harness. It **detects** an existing harness and wires the service repo.

## Detection (`scripts/detect-harness.sh`)

Scans the parent directory of the target repo for harness candidates with `WORKSPACE.md`. Accepts `HARNESS_PATH` env override.

| MODE | Meaning |
|------|---------|
| `l0` | Current repo is the harness |
| `l1` | Sibling harness found |
| `standalone` | No harness |

## Integration (`scripts/integrate-harness.sh`)

When `MODE=l1`: write L1 profile (if missing), patch `CLAUDE.md` Workspace section (if missing), warn if not listed in catalog.
