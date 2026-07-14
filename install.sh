#!/usr/bin/env bash
# csess installer: start Postgres, apply schema, link the CLI, index existing sessions.
set -euo pipefail
cd "$(dirname "$0")"
REPO="$PWD"

command -v docker >/dev/null || { echo "docker is required"; exit 1; }

echo "==> Starting Postgres (docker compose)..."
docker compose up -d

echo "==> Waiting for Postgres to accept connections..."
for _ in $(seq 1 30); do
  docker compose exec -T db pg_isready -U postgres -d sessions >/dev/null 2>&1 && break
  sleep 1
done

echo "==> Applying schema..."
docker compose exec -T db psql -U postgres -d sessions -v ON_ERROR_STOP=1 < schema.sql

echo "==> Linking csess -> ~/.local/bin/csess ..."
mkdir -p "$HOME/.local/bin"
ln -sf "$REPO/csess" "$HOME/.local/bin/csess"

echo "==> Indexing existing sessions..."
"$REPO/csess" index

cat <<EOF

Done. Make sure ~/.local/bin is on your PATH.

For automatic turn-by-turn sync, add this to ~/.claude/settings.json (use the
absolute path, since hooks may run without ~/.local/bin on PATH):

  "hooks": {
    "Stop":       [{"hooks":[{"type":"command","command":"$HOME/.local/bin/csess hook >/dev/null 2>&1 || true"}]}],
    "SessionEnd": [{"hooks":[{"type":"command","command":"$HOME/.local/bin/csess hook >/dev/null 2>&1 || true"}]}]
  }

Then try:  csess find
EOF
