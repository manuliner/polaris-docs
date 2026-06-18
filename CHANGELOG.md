# Changelog

## 1.4.0

Agentic **doc migration** in `docs-defrag` (step 0f) — closes the gap where a tooling update changed
the *rules* but left existing `docs/` leaves non-conforming.

- **New `docs-defrag` step 0f** — after the tooling merge and before the pattern audit, the satellite's
  leaves are migrated to match the new spec (backfill newly required fields, seed new reserved files,
  adjust to changed rules), preserving local edits. Always a **proposal, never an auto-commit** —
  the counterpart to the code-drift loop (steps 6-8).
- **New read-only helper `diff-spec.sh`** — surfaces the spec delta (`patterns.yaml` rules, reserved
  templates, layout prose) between the vendored base and the SSOT HEAD, with coarse `TAG` hints the
  agent interprets.
- **New reference `spec-migration.md`** — the change→action method for deriving doc changes from a
  spec delta.
- **BASE-capture fix** — step 0a now captures the old `ssot_commit` before 0e re-stamps it, and passes
  it to `diff-spec.sh` as `BASE_COMMIT`, so the delta is not empty.

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
