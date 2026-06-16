# Canonical repository structure (documentation skills)

## Required layout

```
AGENTS.md              # L1 agent entry (commands, invariants, doc map)
CLAUDE.md              # @AGENTS.md pointer (+ harness section when L1)
docs/
  README.md            # L1 hub (links only)
  AGENTS_ARCHITECTURE.md
  AGENTS_SERVER.md     # optional; create via docs-write when needed
  AGENTS_APP.md        # optional
  DEPLOYMENT.md        # optional ops runbook
  adr/                 # decision records
.cursor/
  skills/              # three skills (docs-write/docs-verify/docs-defrag) + _shared asset folder
  agent-profile.json
  rules/               # optional *.mdc
web/**/README.md       # optional one-liner per folder; link up to docs/AGENTS_*
```

## Agent doc rules

- **Audience:** agent context files target coding agents; root `README.md` is human onboarding, outside the agent MOC graph.
- **Leaves under `docs/`** — no root `ARCHITECTURE.md` or `DEPLOYMENT.md` (use `docs/AGENTS_ARCHITECTURE.md`, `docs/DEPLOYMENT.md`).
- **SSOT:** hubs link; one leaf owns each topic. See `templates/_shared/reference/agent-doc-layout.md`.

## Non-goals

- Do **not** introduce `hybrid`, `docs-update`, or `docs-concepts` top-level skills.
- Do not add a sixth skill folder; extend the five with scripts and references inside them.

## L1 / L3 contract (verification)

- **L1**: `AGENTS.md`, `CLAUDE.md`, `docs/README.md` (MOC hubs).
- **L3**: `docs/**/*.md` leaves linked from hubs.

`verify-docs.sh` enforces profile paths, forbidden root doc regressions, and skill integrity.
