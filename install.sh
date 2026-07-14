#!/usr/bin/env bash
# csess installer: start Postgres, apply schema, link the CLI, index existing sessions.
set -euo pipefail
cd "$(dirname "$0")"
REPO="$PWD"

have() { command -v "$1" >/dev/null 2>&1; }

# --- Homebrew (used to install everything else) ---
if ! have brew; then
  echo "Homebrew is required to auto-install dependencies."
  echo "  Install it from https://brew.sh  then re-run ./install.sh"
  exit 1
fi

# --- Python 3 ---
have python3 || { echo "==> Installing python3..."; brew install python; }

# --- fzf (powers 'csess find') ---
have fzf || { echo "==> Installing fzf..."; brew install fzf; }

# --- Docker engine + a running daemon ---
if ! docker info >/dev/null 2>&1; then
  if ! have docker; then
    echo "==> Installing Docker engine (Colima — headless, no GUI)..."
    brew install colima docker
  fi
  echo "==> Starting a Docker daemon..."
  if have colima; then
    colima start
  elif [ -d "/Applications/Docker.app" ]; then
    open -a Docker
    printf "   waiting for Docker Desktop"
    for _ in $(seq 1 60); do docker info >/dev/null 2>&1 && break; printf "."; sleep 2; done
    echo
  else
    echo "==> Installing Colima (headless Docker runtime)..."
    brew install colima docker && colima start
  fi
fi
docker info >/dev/null 2>&1 || {
  echo "Docker still isn't reachable. Try 'colima start' (or start Docker Desktop) and re-run."
  exit 1
}

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

# Ensure ~/.local/bin is on PATH (the #1 "csess: command not found" cause)
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;                       # already on PATH, nothing to do
  *)
    case "$(basename "${SHELL:-sh}")" in
      zsh)  rc="$HOME/.zshrc" ;;
      bash) rc="$HOME/.bashrc" ;;
      *)    rc="$HOME/.profile" ;;
    esac
    line='export PATH="$HOME/.local/bin:$PATH"'
    if ! grep -qsF "$line" "$rc" 2>/dev/null; then
      printf '\n# added by csess installer\n%s\n' "$line" >> "$rc"
      echo "   ~/.local/bin was not on PATH — added it to $rc"
    fi
    echo "   -> run:  source $rc   (or open a new terminal) before using csess"
    export PATH="$HOME/.local/bin:$PATH"                 # so this script's index works
    ;;
esac

echo "==> Indexing existing sessions..."
index_out="$("$REPO/csess" index)"
echo "   $index_out"

# --- optional: AI titles + tags for existing sessions ---
if [ -t 0 ] && have claude; then
  printf "\nGenerate AI titles + tags for your existing sessions now?\n"
  printf "  (uses Claude Haiku — one quick call per untitled session) [y/N] "
  read -r ans || ans=""
  case "$ans" in
    [Yy]*) "$REPO/csess" summarize ;;
    *)     echo "   Skipped — run 'csess summarize' anytime to add titles." ;;
  esac
fi

# --- success summary ---
case "$(docker context show 2>/dev/null)" in
  colima)        runtime="Colima (headless)" ;;
  desktop-linux) runtime="Docker Desktop" ;;
  *)             runtime="Docker" ;;
esac

cat <<EOF

──────────────────────────────────────────────
 ✓ csess setup complete
──────────────────────────────────────────────
 ✓ Docker      running via ${runtime}
 ✓ Postgres    container 'claude-sessions-db' up
 ✓ fzf         $(fzf --version 2>/dev/null | awk '{print $1}')
 ✓ csess       linked → ~/.local/bin/csess
 ✓ Sessions    ${index_out}

Next steps:
  • If 'csess' isn't found, open a new terminal (PATH was just updated).
  • Try it:  csess find
  • For auto-sync every turn, add this to ~/.claude/settings.json:

      "hooks": {
        "Stop":       [{"hooks":[{"type":"command","command":"$HOME/.local/bin/csess hook >/dev/null 2>&1 || true"}]}],
        "SessionEnd": [{"hooks":[{"type":"command","command":"$HOME/.local/bin/csess hook >/dev/null 2>&1 || true"}]}]
      }
EOF
