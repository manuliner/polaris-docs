# Pre-commit integration

## Recommended hooks

All shared scripts live once under `.cursor/skills/_shared/scripts/` (no per-skill duplicates):

- `_shared/scripts/verify-docs.sh` — structural gate
- `_shared/scripts/verify-docs-principles.sh` — MOC/link principles
- `_shared/scripts/check-dead-paths.sh` — relative link scan in `docs/**`

## Example (local)

```yaml
repos:
  - repo: local
    hooks:
      - id: verify-docs
        name: verify-docs
        entry: bash .cursor/skills/_shared/scripts/verify-docs.sh
        language: system
        pass_filenames: false
```

The `docs-verify` skill wraps these gates with `--scope=staged|branch`; the hook above runs the
structural gate directly.
