#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

setup_docker_host() {
  mkdir -p "$HOME/.docker/run"
  rm -f "$HOME/.docker/run/docker.sock"
  ln -sf "$HOME/.colima/default/docker.sock" "$HOME/.docker/run/docker.sock"
  export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
}

setup_docker_host

count_migrations() {
  find "$ROOT_DIR/supabase/migrations" -maxdepth 1 -type f -name '*.sql' | wc -l | tr -d ' '
}

MIGRATION_COUNT="$(count_migrations)"
if [[ "$MIGRATION_COUNT" != "1" ]]; then
  echo "Guard failed: expected exactly 1 migration file, found ${MIGRATION_COUNT}." >&2
  echo "Fix required: squash migrations into one latest file before continuing." >&2
  exit 1
fi

CHANGED_SUPABASE_FILES="$(
  {
    git diff --name-only -- supabase
    git diff --cached --name-only -- supabase
    git ls-files --others --exclude-standard -- supabase
  } | awk 'NF' | sort -u
)"

if [[ -z "$CHANGED_SUPABASE_FILES" ]]; then
  echo "No local changes under supabase/. Guard check passed."
  exit 0
fi

echo "Detected supabase changes:"
echo "$CHANGED_SUPABASE_FILES" | sed 's/^/  - /'

HAS_MIGRATION_CHANGE=0
HAS_FUNCTION_CHANGE=0

if echo "$CHANGED_SUPABASE_FILES" | grep -qE '^supabase/migrations/'; then
  HAS_MIGRATION_CHANGE=1
fi
if echo "$CHANGED_SUPABASE_FILES" | grep -qE '^supabase/functions/'; then
  HAS_FUNCTION_CHANGE=1
fi

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry run mode: no local apply actions executed."
  if [[ "$HAS_MIGRATION_CHANGE" == "1" ]]; then
    echo "Would run: make prepare-local"
  fi
  if [[ "$HAS_FUNCTION_CHANGE" == "1" ]]; then
    echo "Would run: make start-local"
  fi
  exit 0
fi

if [[ "$HAS_MIGRATION_CHANGE" == "1" ]]; then
  echo "[guard] Migration change detected -> running make prepare-local"
  make prepare-local
fi

if [[ "$HAS_FUNCTION_CHANGE" == "1" ]]; then
  echo "[guard] Function change detected -> running make start-local"
  make start-local
fi

echo "[guard] Verifying local Supabase status"
supabase status >/dev/null

echo "GUARD OK: local sync policy applied."
