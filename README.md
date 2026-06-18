# polaris-docs

**The single source of truth (SSOT) for our documentation tooling.** Like the Pole Star, this repo is
the one fixed point that every other repo aligns to: it holds the doc-orchestration skill and the four
canonical doc skills that Claude Code and Cursor use to write, check, commit, and clean up documentation
across projects.

This README explains *why* the system is built the way it is. If you want the terse lookup reference
(skill matrix, install one-liner), read [`AGENTS.md`](AGENTS.md) — that file is the agent-facing entry
point; this one is for humans getting their bearings.

---

## What this is

Three moving parts:

- **`docs-init`** — the orchestrator skill. It is repo-independent: it knows how to scaffold a repo,
  detect a workspace harness, and route to the right doc skill. It lives here and is symlinked onto your
  machine.
- **Four canonical skills** — `docs-write` (adds), `docs-verify` (checks), `docs-defrag`
  (removes/merges), `docs-commit` (commits staged code via the agent + catches doc-to-code drift). One
  verb each, no overlap. These get *vendored* (copied) into each project repo.
- **`_shared`** — an asset folder, not a selectable skill. It holds the shared scripts and reference
  prose (including `patterns.yaml`) once, so the four skills don't each carry a copy.

The deliberate constraint: there are **exactly four skills plus one asset folder**. No `hybrid`, no
`docs-update`, no resurrected legacy names. A wider menu only makes a selecting LLM guess.

---

## Two distribution paths (the core idea)

The architecture is asymmetric on purpose, because "get the tooling onto my laptop" and "get the tooling
into a project repo" are different problems with different best answers.

### Repo → your machine: **symlink**

`install.sh` symlinks `docs-init` into `~/.claude/skills/docs-init` and `~/.cursor/skills/docs-init`,
both pointing back at this repo. This is the GNU-Stow dotfiles pattern: the repo *is* the source, the
links are just views onto it. Pull the repo, and your machine is instantly up to date — divergence is
impossible because there is no copy.

### Repo → a project repo: **vendoring with provenance**

Project repos ("satellites") don't symlink the four skills. They get a **copy** under
`<repo>/.cursor/skills/`, checked into the repo. This is the OpenTitan `vendor.py` pattern, and the copy
is intentional:

- **Self-contained.** The repo's docs tooling works even if this SSOT isn't on the machine. Clone the
  project anywhere and the skills are right there.
- **Locally tunable.** A repo can adapt the parts meant to be adapted (skill wording, reference prose)
  without forking the whole system.
- **Tracked.** Each vendored copy carries a `.tooling-version` stamp recording exactly which SSOT commit
  it came from — so an update knows its starting point (see below).

Cursor reads the vendored copy directly. Claude reaches it through a per-repo bridge symlink
(`~/.claude/skills/<skill>` → the repo's vendored copy). Same files, both tools.

```
                          ┌─────────────────────────────────────────────┐
                          │   polaris-docs   (SSOT · git repo · remote)   │
                          │                                               │
                          │   docs-init/        (orchestrator)            │
                          │   templates/_shared + 4 skill templates       │
                          │   manifest.json · patterns · VERSION          │
                          └─────────────────────────────────────────────┘
                                 │                              │
              SYMLINK (docs-init)│                              │ VENDOR = copy (4 skills + _shared)
              SSOT is the source │                              │ stamped with .tooling-version
                 ┌───────────────┴───────────────┐              │
                 ▼                                ▼              ▼
       ~/.claude/skills/docs-init      ~/.cursor/skills/docs-init     <satellite-repo>/.cursor/skills/
            (Claude, global)               (Cursor, global)            ├── docs-write/   docs-verify/
                                                                       ├── docs-defrag/  docs-commit/
                                                                       ├── _shared/
                                                                       └── .tooling-version  (← which
                                                                                  SSOT commit this came from)
```

`docs-init` is *symlinked* (the repo stays the source, so divergence is impossible). The four skills are
*copied* into each satellite repo — self-contained, locally tunable, and stamped with their provenance.

Inside a satellite, that one vendored copy is the single source for both tools:

```
   <satellite-repo>/
   └── .cursor/skills/                     ◀── vendored copy (checked into the repo)
         ├── docs-write/  docs-verify/  docs-defrag/  docs-commit/   _shared/
         └── .tooling-version
                 ▲                      ▲
                 │                      │
   Cursor reads  │                      │  Claude reaches it via a per-repo
   directly ─────┘                      └───── BRIDGE SYMLINK:
   (no symlink                                 ~/.claude/skills/<skill> ──▶ <repo>/.cursor/skills/<skill>
    needed)
```

Cursor reads it directly; Claude reaches it through a per-repo bridge symlink. Only the
repo-independent orchestrator `docs-init` is symlinked globally — the four skills never are.

---

## Install

**On your machine (once):**

```bash
docs-init/install.sh
```

This symlinks `docs-init` into both Claude and Cursor, removes any legacy pre-consolidation skill links,
and — when run inside this SSOT repo — arms the dogfooding pre-commit hook via
`git config core.hooksPath scripts/hooks` (so the repo can't commit something that breaks its own
rules).

**Onto a project repo (vendor the skills):**

```bash
docs-init/scripts/scaffold-repo-skills.sh <repo-root>
```

This copies `_shared` plus the four skills into `<repo>/.cursor/skills/`, writes the `.tooling-version`
provenance stamp, bridges the skills to Claude, and seeds a `docs/_index.md` hub if the repo doesn't
have one yet.

---

## How updates work (pull, not push)

Nothing is ever pushed onto a satellite. A repo pulls a tooling update *when it runs `docs-defrag`*, and
only that repo is touched. The merge is context-sensitive, so local adaptations survive.

```
   SSOT advances ──▶ new commit on origin/HEAD
                              │
                              │   (nothing is pushed onto satellites)
                              ▼
   In a satellite you run:  docs-defrag
                              │
                              ▼
   ┌─ Step 0a ─ compare:  SSOT HEAD   vs.   .tooling-version (ssot_commit)
   │              equal ──▶ no update, defrag continues
   │              newer ──▶ ▼
   │
   ├─ Step 0b ─ diff-tooling.sh (read-only) 3-way compare per file:
   │                  base (SSOT@stamp) · local copy · upstream (SSOT HEAD)
   │
   ├─ Step 0c ─ classify via manifest.json + merge per file:
   │                  managed            + upstream-changed ─▶ take SSOT hard
   │                  local-overridable  + both-changed     ─▶ merge semantically
   │                                                            (local edit preserved)
   │                  any                + local-only        ─▶ leave untouched
   │
   └─ Step 0e ─ re-stamp .tooling-version ──▶ verify-docs.sh
                   only THIS repo changes; others wait for their own defrag
```

The mechanism, run as **step 0** of every `docs-defrag`:

1. **Locate the SSOT and compare.** Resolve this repo through the `docs-init` symlink, fetch (if it has
   a remote), and compare its `HEAD` to the `ssot_commit` recorded in the satellite's `.tooling-version`.
   Equal → nothing to do, defrag continues normally.
2. **Three-way diff** (`diff-tooling.sh`, read-only). For each vendored file it compares three versions:
   the **base** (the SSOT at the recorded commit), the **local** copy, and the **upstream** SSOT `HEAD`.
   Having the base is what lets it tell a local edit apart from an upstream change.
3. **Classify and merge per file**, driven by `manifest.json`. Every file is either `managed` or
   `local-overridable`:

   | Class | What changed | Action |
   |-------|--------------|--------|
   | any | nothing upstream (or only locally) | leave the local file alone |
   | `managed` | upstream changed | take the SSOT version hard — these are contract files |
   | `managed` | locally forked | report the fork, then overwrite (managed wins) |
   | `local-overridable` | only upstream changed | take upstream (no local edit to keep) |
   | `local-overridable` | **both** changed | **merge semantically**: keep the local adaptation, fold in the upstream improvement; a genuine conflict is reported, never silently overwritten |

   `managed` = the tooling contract (shared scripts, provenance). `local-overridable` = the parts a repo
   is meant to tune (skill wording, reference prose). **Repo-specific changes are preserved.**
4. **Re-stamp and verify.** Update `.tooling-version` to the new commit, run `verify-docs.sh` to confirm
   nothing structural broke, and report what was taken hard, what was merged, and any conflict left for
   you to resolve.

---

## The four skills — when to use which

An agent reads `CLAUDE.md` at session start; its `@AGENTS.md` pointer leads into the doc graph
(`docs/_index.md` as the hub, which links to the leaves). Reading is passive. The graph only *changes*
when one of the four skills is invoked.

```
   ┌─────────┐   reads at session start
   │  AGENT  │ ────────────────────────────────┐
   │ (Claude │                                  ▼
   │ /Cursor)│                          ┌───────────────┐
   └─────────┘                          │   CLAUDE.md    │  @AGENTS.md
        │                               └───────┬───────┘
        │ skills available                      │ points into the doc graph
        │ (vendored in repo)                    ▼
        │                               ┌───────────────┐
        │                               │ docs/_index.md │  (hub · links only)
        │                               └───────┬───────┘
        │                                       │ links to leaves
        │                            ┌──────────┴──────────┐
        │                            ▼                      ▼
        │                     docs/AGENTS_*.md        docs/adr/*.md …
        │                       (leaves · the actual content)
        │                                       ▲
        │   on invocation, the four skills act on the doc graph:
        │                                       │
        ├─ docs-write   ── adds ─────────▶ new leaf + link into hub
        ├─ docs-verify  ── checks ───────▶ gates structure / MOC (writes nothing)
        ├─ docs-defrag  ── removes/merges▶ consolidates, prunes, self-updates, fixes drift
        └─ docs-commit  ── commits ──────▶ commits staged code, proposes doc updates on drift
```

| Skill | Verb | Use it when |
|-------|------|-------------|
| **`docs-write`** | adds | you're creating a new leaf, ADR, or runbook. It links the leaf into the hub and never deletes or gates. |
| **`docs-verify`** | checks | you're about to commit or merge doc changes. It runs the structural + MOC gates and writes nothing. |
| **`docs-defrag`** | removes / merges | you're consolidating, archiving, or pruning docs — and it also self-updates the tooling (step 0) and runs the drift check. |
| **`docs-commit`** | commits | you ask the agent to commit. It checks the staged code against doc `sources`, proposes a `docs-write` update on drift (preview, your call), then commits. It proposes, never gates. |

Typical sequences:

- **New documentation:** `docs-write` → `docs-verify`.
- **Before a commit:** `docs-verify --scope=staged` (the staged files).
- **Committing through the agent:** `docs-commit` — catches doc drift at commit time and proposes the fix.
- **Before a merge / on a PR:** `docs-verify --scope=branch` (everything the branch touched).
- **Periodic cleanup:** `docs-defrag` — pulls any tooling update, prunes/merges leaves, audits patterns,
  and flags docs that have drifted from the code.

### Self-healing loop

`docs-defrag` can detect when documentation has fallen behind the code. A code-adjacent leaf records
`sources:` (the files it documents) and a `sources_stamp` (the commit it was last verified against). The
staleness check flags any leaf whose sources have newer commits, then drafts a **patch proposal** (never
an auto-commit) via `docs-write` for you to review. Accept it, re-verify, re-stamp — loop closed.

The loop also has a **commit-time trigger**, on two layers. When you commit *through the agent*,
`docs-commit` runs the staged staleness check, reads the code diff, and proposes the doc update *before*
the commit — the live, full-fidelity path, because the agent can call an LLM. For a plain `git commit`
in the terminal, scaffolding installs a pre-commit hook that runs the same staged check; if a commit
touches code a leaf documents, the hook **warns** (it never blocks) and records the stale leaves in
`.cursor/skills/.staleness-pending` for the next `docs-defrag` to propose the update. (A git hook can't
call an LLM, so it can only warn and hand off — hence the agent-driven `docs-commit` for the live case.)
The hook is inserted marker-bounded into the native `.git/hooks/pre-commit`, so it coexists with husky
or lefthook (see `_shared/reference/precommit-integration.md`).

---

## Patterns (the rules, and why)

The doc conventions aren't prose suggestions; they're a declarative registry in
[`docs-init/templates/_shared/reference/patterns.yaml`](docs-init/templates/_shared/reference/patterns.yaml),
enforced by `verify-patterns.sh`.

| Rule | Limit | Why |
|------|-------|-----|
| **hub line count** | `docs/_index.md` ≤ 40 lines | a hub routes; it links, it doesn't hold content. Long hubs hide the map. |
| **leaf line count** | each leaf ≤ 500 lines | a leaf that grows past this is two topics wearing one file. |
| **hub heading depth** | ≤ H2 | hubs are flat tables of contents. |
| **leaf heading depth** | ≤ H3 | deeper nesting means the leaf is really several leaves. |
| **skill frontmatter** | `name`, `description` | both Claude and Cursor select skills by these fields. |
| **leaf frontmatter** | `audience`, `category`, `last_verified` | metadata makes leaves findable and lets staleness be reasoned about. |
| **canonical skills** | exactly `docs-write`, `docs-verify`, `docs-defrag`, `docs-commit` | a self-consistency check: the skill set must not drift. |
| **one concept per leaf** | *soft* | judged by `docs-defrag`, not a hard gate — a leaf covering several independent topics is a split candidate. |

Everything except *one-concept-per-leaf* is a hard machine check (non-zero exit fails the gate). The
soft rule is deliberately a human/LLM judgment to avoid false alarms.

---

## Repo layout

```
VERSION                 semver marker of the tooling
AGENTS.md               agent-facing quick reference (this repo's own L1 entry)
CLAUDE.md               pointer: @AGENTS.md
manifest.json           managed vs. local-overridable classification (drives the update merge)
patterns.ssot.yaml      the patterns applied to THIS repo's own files (dogfooding)
scripts/                self-check.sh + the pre-commit hook that gates every SSOT commit
docs-init/
  install.sh            symlink onto this machine, arm the hook
  scripts/              scaffold, bridge, harness detection/integration
  reference/            orchestrator docs (canonical structure, rollout, token efficiency, ...)
  templates/
    _shared/            shared scripts + reference (asset folder; holds patterns.yaml)
    docs-write/         the "adds" skill template
    docs-verify/        the "checks" skill template
    docs-defrag/        the "removes/merges" skill template
    docs-commit/        the "commits" skill template
    docs/               the docs/_index.md hub template
```

For the terse lookup view, see [`AGENTS.md`](AGENTS.md). For the deeper rationale on layout, rollout,
and token efficiency, see [`docs-init/reference/`](docs-init/reference/).
