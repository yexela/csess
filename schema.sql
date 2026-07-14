-- Claude Code session index
CREATE TABLE IF NOT EXISTS sessions (
    uuid          text PRIMARY KEY,
    project_dir   text NOT NULL,          -- encoded dir name under ~/.claude/projects
    cwd           text,                   -- original working directory
    git_branch    text,
    first_message text,
    content       text,                   -- all conversational text (for full-content FTS)
    summary       text,                   -- AI-generated one-line title
    msg_count     integer,
    size_bytes    bigint,
    created_at    timestamptz,            -- first record timestamp
    updated_at    timestamptz,            -- last record timestamp
    file_path     text NOT NULL,
    body          bytea,                  -- full JSONL body (portability); NULL until pushed
    body_size     bigint,                 -- octet_length(body) at last push, for change detection
    fts           tsvector GENERATED ALWAYS AS (to_tsvector('english',
                     coalesce(summary,'')||' '||coalesce(first_message,'')||' '||coalesce(content,''))) STORED
);
CREATE INDEX IF NOT EXISTS sessions_fts_idx     ON sessions USING gin(fts);
CREATE INDEX IF NOT EXISTS sessions_project_idx ON sessions(project_dir);

CREATE TABLE IF NOT EXISTS tags (
    id   serial PRIMARY KEY,
    name text UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS session_tags (
    session_uuid text REFERENCES sessions(uuid) ON DELETE CASCADE,
    tag_id       integer REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (session_uuid, tag_id)
);
