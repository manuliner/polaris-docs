# Agent doc layout (L1 service repos)

**Audience:** coding agents only. Human onboarding may use root `README.md`; that file is **not** part of the agent doc graph.

## Principles

1. **Leaves live under `docs/`** — architecture, codemaps, runbooks, ADRs, test plans.
2. **Hubs summarize and link** — no duplicated prose from leaves (see `token-efficiency.md`).
3. **One SSOT per topic** — path lists and runbook steps appear in exactly one leaf.

## Standard paths

| Path | Role |
| ---- | ---- |
| `AGENTS.md` | L1 entry: commands, stack, invariants, doc map |
| `CLAUDE.md` | Pointer to `AGENTS.md` (+ harness workspace section when L1) |
| `docs/README.md` | L1 hub: links only |
| `docs/AGENTS_ARCHITECTURE.md` | System diagram + directory tree + task router |
| `docs/AGENTS_SERVER.md` | Server/API/middleware/import path SSOT |
| `docs/AGENTS_APP.md` | UI/composable path SSOT |
| `docs/DEPLOYMENT.md` | Deploy/rollback/ops runbook (when applicable) |
| `docs/adr/*.md` | Durable decisions |
| `web/**/README.md` | One-liner per folder; link up to `docs/AGENTS_*` |

## Do not create

| Path | Why |
| ---- | --- |
| Root `ARCHITECTURE.md` | Use `docs/AGENTS_ARCHITECTURE.md` instead |
| Root `DEPLOYMENT.md` | Use `docs/DEPLOYMENT.md` instead |
| Duplicate codemaps | Extend the existing `docs/AGENTS_*` leaf |

Profile `documentation.forbiddenGlobs` should include `ARCHITECTURE.md` and `DEPLOYMENT.md` (repo root) to catch regressions.

## Layering (load order)

1. `AGENTS.md` / `CLAUDE.md`
2. `docs/README.md`
3. One branch: `docs/AGENTS_ARCHITECTURE.md` → `AGENTS_SERVER` / `AGENTS_APP` as needed
4. `web/**/README.md` only when working inside that folder
