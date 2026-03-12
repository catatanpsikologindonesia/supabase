#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Reuse inherited remote connection from parent script when available.
if [[ -n "${REMOTE_URI:-}" ]] && psql "$REMOTE_URI" -Atc "select 1;" >/dev/null 2>&1; then
  export REMOTE_URI
  export REMOTE_CONNECTION_MODE="${REMOTE_CONNECTION_MODE:-inherited}"
  if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 0
  fi
  exit 0
fi

REMOTE_URI=""
REMOTE_CONNECTION_MODE=""

# Optional fast path: use pooler URL + explicit DB password if provided.
POOLER_FILE="$ROOT_DIR/supabase/.temp/pooler-url"
if [[ -f "$POOLER_FILE" && -n "${SUPABASE_DB_PASSWORD:-}" ]]; then
  POOLER_URL="$(tr -d '\r\n' < "$POOLER_FILE")"
  POOLER_URL_NO_SCHEME="${POOLER_URL#postgresql://}"
  POOLER_USER="${POOLER_URL_NO_SCHEME%@*}"
  POOLER_HOST_PORT_DB="${POOLER_URL_NO_SCHEME#*@}"
  POOLER_HOST="${POOLER_HOST_PORT_DB%%:*}"
  POOLER_PORT_DB="${POOLER_HOST_PORT_DB#*:}"
  POOLER_PORT="${POOLER_PORT_DB%%/*}"
  POOLER_DB="${POOLER_PORT_DB#*/}"
  CANDIDATE_URI="postgresql://${POOLER_USER}:${SUPABASE_DB_PASSWORD}@${POOLER_HOST}:${POOLER_PORT}/${POOLER_DB}?sslmode=require"
  if psql "$CANDIDATE_URI" -Atc "select 1;" >/dev/null 2>&1; then
    REMOTE_URI="$CANDIDATE_URI"
    REMOTE_CONNECTION_MODE="pooler"
  fi
fi

# Preferred fallback: derive ephemeral login credentials from Supabase CLI linked context.
# Important: clear SUPABASE_DB_PASSWORD here so CLI does not reuse placeholder env values.
if [[ -z "$REMOTE_URI" ]]; then
  REMOTE_EXPORTS="$(
    SUPABASE_DB_PASSWORD= supabase db dump --linked --dry-run --workdir "$ROOT_DIR" 2>/dev/null \
      | grep -E '^export PG(HOST|PORT|USER|PASSWORD|DATABASE)='
  )"
  if [[ -n "$REMOTE_EXPORTS" ]]; then
    eval "$REMOTE_EXPORTS"
    CANDIDATE_URI="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}?sslmode=require"
    if psql "$CANDIDATE_URI" -Atc "select 1;" >/dev/null 2>&1; then
      REMOTE_URI="$CANDIDATE_URI"
      REMOTE_CONNECTION_MODE="cli-linked"
    fi
  fi
fi

if [[ -z "$REMOTE_URI" ]] || ! psql "$REMOTE_URI" -Atc "select 1;" >/dev/null 2>&1; then
  echo "Failed to connect remote DB via pooler and CLI-linked fallback." >&2
  exit 1
fi

export REMOTE_URI REMOTE_CONNECTION_MODE
