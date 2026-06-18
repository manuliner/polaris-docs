# Changelog

## 1.3.0

Triage + routing, aligned with the [Routed Knowledge Format](https://gitlab.invers.com/Marko.Eisner/routed-knowledge-format)
(RKF, a superset of Google's OKF).

- **`load-when` is now a required leaf frontmatter field** — the second triage field (alongside
  `description`) that lets an agent decide whether to load a leaf from its header alone.
- **`type` is an optional leaf field** — OKF/RKF self-describing kind, making a Polaris bundle a valid
  OKF/RKF bundle.
- **New `docs/_router.md`** — a reserved router file mapping a task to the exact files to load
  (RKF §5). Seeded by `scaffold-repo-skills.sh`, excluded from leaf checks, and gated by its own
  patterns (`router-line-count`, `router-heading-depth`, `router-frontmatter`).
- **Router terminology disambiguated** — `docs/_router.md` is the canonical task→file router; the
  "task router" mentions in `AGENTS_ARCHITECTURE.md` are now the module/directory map.
