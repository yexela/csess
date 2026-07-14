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

## Requirements

- Docker
- Python 3
- [Claude Code](https://claude.com/claude-code) (`claude` on your PATH)
- `fzf` (optional, for `csess find`) — `brew install fzf`

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
| `CSESS_CONTAINER` | `claude-sessions-db` | Postgres container name |
| `CSESS_DB` | `sessions` | database name |
| `CSESS_DB_USER` | `postgres` | database user |
| `CSESS_WORKDIR` | `~/.cache/csess` | scratch dir for internal `claude -p` calls |
| `CLAUDE_PROJECTS_DIR` | `~/.claude/projects` | where Claude Code stores sessions |

## Security notes

- The database contains your **full session transcripts**, which can include
  secrets, code, and file contents. The container binds to `127.0.0.1` only.
- Nothing is uploaded anywhere. Everything stays on your machine.

## Roadmap

- Lift Postgres off-box (RDS / self-hosted) for **multi-machine** shared history
- Cross-machine `pull`
- Optional MCP tool so you can search sessions from inside a conversation

## License

MIT © Alexey Chernetsky
