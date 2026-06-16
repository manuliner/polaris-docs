# Rollout stages

## Multi-repo (recommended)

1. **workspace-init full** — L0 `platform-harness/` (catalog, cross-service docs, clone/sync scripts)
2. **docs-init cursor full** — each L1 service repo (three skills + `_shared` + harness wiring)
3. **docs-write** — per service, generate `docs/AGENTS_ARCHITECTURE.md` and layer codemaps under `docs/`
4. **docs-defrag** — required gate after init

## docs-init phases (single repo)

1. **Bundle install** — `install.sh` installs `docs-init` + `workspace-init` globally
2. **Harness scan** — `detect-harness.sh` (parent dir or `HARNESS_PATH`)
3. **Scaffold** — three skills + `_shared` asset folder under `.cursor/skills/`
4. **Harness integrate** — `integrate-harness.sh` when `MODE=l1`
5. **Bridge** — symlinks into `~/.claude/skills/<name>`
6. **Structural verify** — `verify-docs.sh`
7. **Auto sections** — `check-auto-sections.sh` when profile defines them
8. **Team habits** — MOC-first navigation; periodic `docs-defrag`

Rollback: remove symlinks under `~/.claude/skills/` and optionally delete `.cursor/skills/` copies (keep backups).
