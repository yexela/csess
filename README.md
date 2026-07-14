# csess — a searchable, portable store for Claude Code sessions

Claude Code keeps every session as a JSONL file under
`~/.claude/projects/<encoded-cwd>/<uuid>.jsonl`. That means your history is
**bound to the folder** it was created in, keyed only by an opaque UUID, and
searchable only by grepping raw files.

`csess` mirrors that history into a local Postgres database so you can:

- 🔎 **Search the full text of every conversation** — not just the first line
- 🏷️ **Tag** sessions and browse by topic
- 🤖 **Auto-title + auto-tag** sessions with a cheap Haiku call
- 🎯 **Fuzzy-find** a session (`fzf`) and **resume it in *any* folder** — the
  folder binding becomes a client-side detail
- 🔁 **Auto-sync** every turn via a Claude Code hook (incremental — only new
  bytes are shipped, since JSONL is append-only)

Everything runs **locally**. The database is bound to `127.0.0.1` only.

![csess demo — list, full-content search, and the fuzzy find picker](docs/demo.gif)

```
   ~/.claude/projects/**/*.jsonl                Postgres (Docker, localhost)
   ┌───────────────────────────┐   index/push   ┌────────────────────────────┐
   │ session JSONL (per folder) │ ─────────────▶ │ metadata · tags · FTS      │
   └───────────────────────────┘                 │ full JSONL body (bytea)    │
             ▲  claude --resume                   └────────────────────────────┘
             │                                                 │ load
   ┌─────────┴───────────┐                                     ▼
   │ any folder, resumed  │ ◀───────────────  materialize session into cwd
   └─────────────────────┘
```

## Prerequisites

`install.sh` **auto-installs everything else for you** via Homebrew — Docker
(headless, via Colima), `fzf`, and `python3` — and starts the Docker daemon. So
you only need two things up front:

| Need | Why |
|------|-----|
| **[Homebrew](https://brew.sh)** | the installer uses it to fetch the rest |
| **[Claude Code](https://claude.com/claude-code)** | provides the sessions (`claude` on your PATH) |

Everything below is handled automatically by the installer:

| Auto-installed | Purpose |
|----------------|---------|
| Docker (Colima) | hosts the Postgres database, started headlessly |
| `fzf` | powers `csess find` |
| `python3` | runs the `csess` script |

> Already have Docker Desktop? The installer detects it and just starts it
> instead of installing Colima.

## Install

```bash
git clone https://github.com/yexela/csess.git
cd csess
./install.sh
```

This starts Postgres, applies the schema, links `csess` into `~/.local/bin`,
and indexes your existing sessions. Follow the printed instructions to add the
optional auto-sync hook.

## Usage

New here? Just run **`csess`** (or `csess start`) — it opens an interactive menu
of every action, so you don't have to memorize commands:

```
csess> ▏                type to filter · ↑↓ move · Enter select · Esc quit
❯ 🔎  find & resume a session
  📋  list recent sessions
  🔍  search sessions by text or tag
  🏷   add tags to a session
  🤖  generate AI titles + tags
  ⬆   back up session bodies
  🔄  re-scan sessions into the DB
```

Or call the commands directly:

```bash
csess find                 # interactive fuzzy picker → Enter resumes here
csess search testflight    # full-content search (matches anywhere in a convo)
csess list                 # recent sessions with titles + tags
csess summarize            # AI title + auto-tags for untitled sessions
csess tag <uuid> billing   # your own tags (UUID prefix is enough)
csess run <uuid>           # materialize into current folder + claude --resume
csess index                # re-scan metadata (also run by the hook)
csess push                 # store/refresh JSONL bodies (incremental)
```

### Resume anywhere

`csess load`/`run` copy the session's JSONL into the **current** folder's
project dir (preferring the body stored in Postgres, falling back to the
original file) and then call `claude --resume`. So a session created in project
A can be resumed from project B — or, once the DB lives on a server, from
another machine entirely.

## How it works

- **Metadata + FTS** — `csess index` parses each JSONL for cwd, branch,
  timestamps, message count, the first user message, and all conversational
  text. A Postgres generated `tsvector` over (summary + first message + content)
  powers `csess search`.
- **Bodies** — `csess push` stores the raw JSONL in a `bytea` column,
  **incrementally**: it tracks how many bytes are already stored and appends
  only the new tail each time (JSONL is append-only). This is what makes a
  session portable independent of `~/.claude`.
- **Auto-sync hook** — `csess hook` reads the `transcript_path` from the hook
  payload on stdin and indexes + pushes **only the current session**. Wired to
  `Stop` (every turn) and `SessionEnd`, so the DB tracks live sessions.

## Configuration

Environment variables (all optional):

| Var | Default | Purpose |
|-----|---------|---------|
| `CSESS_DSN` | _(unset)_ | Postgres connection string for a **remote** DB (see below); overrides the local container |
| `CSESS_CONTAINER` | `claude-sessions-db` | Postgres container name |
| `CSESS_DB` | `sessions` | database name |
| `CSESS_DB_USER` | `postgres` | database user |
| `CSESS_WORKDIR` | `~/.cache/csess` | scratch dir for internal `claude -p` calls |
| `CLAUDE_PROJECTS_DIR` | `~/.claude/projects` | where Claude Code stores sessions |

### Local vs. remote database

By default `csess` talks to the local Docker container — no host `psql` client
needed. To point it at a **remote** Postgres instead (e.g. a shared server so
several machines share one history), set a connection string:

```bash
export CSESS_DSN="postgresql://user:pass@db.example.com:5432/sessions"
csess index          # now reads/writes the remote DB
```

- With `CSESS_DSN` set, csess uses a host `psql` if present, otherwise routes
  through the local container as a client.
- Apply `schema.sql` to the remote database once before first use.
- Everything else is identical — indexing your local sessions and resuming them
  into folders works the same; only the storage moves off-box.
- Unset `CSESS_DSN` to switch back to local.

## Security notes

- The database contains your **full session transcripts**, which can include
  secrets, code, and file contents. The container binds to `127.0.0.1` only.
- Nothing is uploaded anywhere. Everything stays on your machine.

## Roadmap

- Lift Postgres off-box (RDS / self-hosted) for **multi-machine** shared history
- Cross-machine `pull`
- Optional MCP tool so you can search sessions from inside a conversation

## Troubleshooting

**`csess: command not found`** — make sure `~/.local/bin` is on your `PATH`.

**`psql error: ... connection refused`** — the database isn't running. Locally:
`docker compose up -d` (or `docker start claude-sessions-db`).

**`csess find` just prints a list** — install fzf: `brew install fzf`.

**Search returns nothing** — run `csess index` (metadata); AI titles need
`csess summarize`.

**Auto-sync hook isn't firing** — hooks load at session start, so they only
affect sessions started *after* you added them. Use the **absolute path** to
`csess` in `~/.claude/settings.json` (hooks may run without `~/.local/bin` on
PATH), and confirm the container is running.

**`load`: "no stored body and original file missing"** — that session's body was
never pushed and the original file isn't on this machine. Run `csess push` on the
machine that has it.

## License

MIT © Oleksii Chernetskyi
