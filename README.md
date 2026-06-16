# polaris-docs

**The single source of truth (SSOT) for the documentation tooling.** Like the Pole Star, this repo
is the fixed reference point that every satellite repo aligns to.

It holds the doc-orchestration skill (`docs-init`) and the three canonical doc skills consumed by
Claude Code and Cursor. Satellite repos vendor copies of the skills and pull updates from here.

## What's inside

```
VERSION              # semver of the tooling (human-readable marker)
docs-init/           # the orchestrator skill + installer
  install.sh         #   symlinks docs-init into ~/.claude/skills and ~/.cursor/skills
  scripts/           #   scaffold, bridge, harness detection/integration
  reference/         #   orchestrator docs (canonical structure, rollout, token-efficiency, ...)
  templates/
    _shared/         #   shared scripts + reference (asset folder, NOT a selectable skill)
    docs-write/      #   adds    — new leaves, ADRs, runbooks
    docs-verify/     #   checks  — structural + MOC gate (--scope=staged|branch)
    docs-defrag/     #   removes/merges — consolidate, archive, drift audit
    docs/            #   docs/README.md hub template
```

## Canonical skills (three + asset folder)

| Skill | Verb | Use when |
|-------|------|----------|
| `docs-write` | adds | new leaf / ADR / codemap |
| `docs-verify` | checks | pre-commit / pre-merge gate (`--scope=staged\|branch`) |
| `docs-defrag` | removes/merges | consolidate, archive, dead paths, drift audit |
| `_shared` | (asset) | shared scripts + reference; not selectable |

No `hybrid`, `docs-update`, `docs-concepts`, or the legacy
`docs-shared`/`docs-commit`/`docs-pr-check`/`docs-writer` skills.

## Install (this machine)

```bash
docs-init/install.sh        # symlink docs-init into ~/.claude/skills + ~/.cursor/skills
```

## Distribution model

- **This machine:** `docs-init` is symlinked into `~/.claude/skills` and `~/.cursor/skills` (SSOT = this repo).
- **Satellite repos:** vendor the three skills + `_shared` via `scaffold-repo-skills.sh`; record the
  installed version in `.cursor/skills/.tooling-version`.
- **Updates:** a satellite's `docs-defrag` checks this repo's HEAD/VERSION and context-merges changes,
  preserving local edits (see the tooling plan).
