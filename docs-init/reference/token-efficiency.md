# Token efficiency and MOC pattern

## Map of Content (MOC)

Use **MOC** files as thin routing layers:

1. One short **hub** markdown file lists sections with one-line intents and relative links.
2. Agents load the hub first, then follow **only** the branch needed for the task.
3. Avoid duplicating prose from leaves into hubs; summarize and link.

Agent leaves belong under **`docs/`** (see `templates/_shared/reference/agent-doc-layout.md`).

## MOC in verification

`verify-docs-principles.sh` (in `_shared/scripts/`, used by `docs-verify` and `docs-defrag`) treats MOC files as mandatory index nodes when `DOC_MOC_PATHS` is set or when `.cursor/agent-profile.json` declares `documentation.mocPaths`.

## Practices

- Prefer bullet “signposts” over narrative in indexes.
- Keep `SKILL.md` front-matter minimal; deep detail lives in `reference/`.
- Run `verify-docs.sh` before large edits to catch forbidden paths early.
