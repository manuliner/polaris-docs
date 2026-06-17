# polaris-docs (short)

The **single source of truth** for our documentation tooling: one orchestrator (`docs-init`) + three
canonical doc skills. The long version with diagrams and rationale is in [`README.md`](README.md);
the agent-facing lookup is [`AGENTS.md`](AGENTS.md).

## The idea in one breath

A central git repo holds the tooling. Your machine gets it by **symlink** (repo = source, no
divergence). Project repos get a **vendored copy** (self-contained, locally tunable, stamped with its
provenance). Updates are **pulled** per repo, never pushed.

## The three skills

An agent reads `CLAUDE.md` → `@AGENTS.md` → the doc graph; the skills change that graph on invocation.

```
   AGENT ──reads──▶ CLAUDE.md ──@AGENTS.md──▶ docs/_index.md (hub) ──▶ leaves (content)
     │                                                                     ▲
     ├─ docs-write   ── adds ─────────────▶ new leaf + link into hub       │
     ├─ docs-verify  ── checks ───────────▶ gates structure (no writes)    │
     └─ docs-defrag  ── removes/merges ───▶ consolidate · self-update · fix drift
```

| Skill | Verb | Use when |
|-------|------|----------|
| `docs-write`  | adds | new leaf / ADR / runbook |
| `docs-verify` | checks | before commit (`--scope=staged`) or merge (`--scope=branch`) |
| `docs-defrag` | removes / merges | consolidate, prune, self-update tooling, drift check |

Typical flow: `docs-write` → `docs-verify`; periodic `docs-defrag`.

## Install

```bash
docs-init/install.sh                              # symlink onto this machine
docs-init/scripts/scaffold-repo-skills.sh <repo>  # vendor the skills into a project
```

## Updates (pull, not push)

Run `docs-defrag` in a repo. Step 0 compares the SSOT `HEAD` to the repo's `.tooling-version`, and on a
newer commit does a 3-way merge driven by `manifest.json`: `managed` files are taken from upstream,
`local-overridable` files are merged so **local edits survive**. Only that repo changes.

## Doc-to-code drift

A scaffolded repo gets a pre-commit hook: when a commit touches code that a leaf documents (`sources:`),
it **warns** (never blocks) and records it for the next `docs-defrag` to propose a `docs-write` update.

## Rules

Conventions are enforced from `patterns.yaml`: hub ≤ 40 lines, leaf ≤ 500, required frontmatter,
exactly the three canonical skills. One soft rule (one concept per leaf) is a judgment call, not a gate.
