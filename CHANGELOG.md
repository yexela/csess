# Changelog

All notable changes to csess are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Check your installed version with `csess version`.

## [Unreleased]

### Changed
- Demo GIF now showcases fuzzy find + the interactive menu, and moved to the top
  of the README.

## [0.3.0] — 2026-07-14

### Added
- **Installer offers `summarize`** — after indexing, `install.sh` asks whether to
  generate AI titles + tags for existing sessions (uses Claude Haiku). Prompt is
  skipped automatically when non-interactive or when `claude` isn't on PATH.

### Fixed
- `csess update` now flushes its progress line so output stays in order even when
  piped (non-TTY).

## [0.2.0] — 2026-07-14

### Added
- **Interactive menu** — running `csess` with no arguments (or `csess start` /
  `csess menu`) opens an fzf-powered home screen listing every action; pick one,
  it runs, and you return to the menu. No need to memorize commands.
- Reusable `pick_session()` helper (shared by `find` and the menu's tag action).
- **`csess update`** — git-pulls the latest version in place (also in the menu).

### Changed
- Bare `csess` in a terminal now opens the menu. When output is piped or `fzf`
  isn't installed, it falls back to printing the usage/help text as before.

## [0.1.0] — 2026-07-14

First release. A local, searchable, portable store for Claude Code sessions.

### Added
- **Index** — mirror `~/.claude` session transcripts into Postgres (metadata +
  full-conversation text) with `csess index`.
- **Search** — `csess search <tag|text>` matches tags, first message, and the
  full conversation via a Postgres full-text index.
- **Tags** — `csess tag` / `csess untag`, plus `csess list`.
- **AI titles** — `csess summarize` generates a one-line title and topic tags
  per session using a cheap Haiku call.
- **Fuzzy find** — `csess find` opens an fzf picker with a live preview
  (`csess show`) and resumes the chosen session.
- **Resume anywhere** — `csess load` / `csess run` materialize a session into
  the current folder (from the stored body or disk) and run `claude --resume`,
  so any session can be resumed from any folder.
- **Portable bodies** — full JSONL stored in a Postgres `bytea` column,
  appended **incrementally** (append-only JSONL → ship only the new tail).
- **Auto-sync hook** — `csess hook` for `Stop`/`SessionEnd`, indexing and
  pushing only the current session each turn, with guards against indexing its
  own `claude -p` calls.
- **Local or remote database** — default local Docker container, or point at any
  Postgres with `CSESS_DSN`.
- **One-command install** — `install.sh` auto-installs dependencies (Docker via
  Colima, fzf, python), starts the daemon, links `csess`, wires `PATH`, and
  prints a setup summary. Friendly errors when Docker or the container is down.
- **`csess version`**.

[Unreleased]: https://github.com/yexela/csess/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/yexela/csess/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/yexela/csess/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yexela/csess/releases/tag/v0.1.0
