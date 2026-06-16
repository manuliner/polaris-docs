# Cursor rules snippets (templates)

## docs-skills-always.mdc (example)

```yaml
alwaysApply: true
description: Prefer the three canonical doc skills only (docs-write, docs-verify, docs-defrag).
```

```markdown
## Documentation skills

- Use `.cursor/skills/_shared/scripts/` verification scripts before bulk doc edits.
- Do not create `hybrid`, `docs-update`, `docs-concepts`, or the legacy
  `docs-shared`/`docs-commit`/`docs-pr-check`/`docs-writer` skills.
```

## Repository-specific rule

Pin `DOC_SEARCH_ROOTS`, `DOC_FORBIDDEN_GLOBS`, and `DOC_PROFILE` in `.cursor/agent-profile.json` or env for `verify-docs.sh`.
