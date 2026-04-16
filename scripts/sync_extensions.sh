#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SNAPSHOT_DIR="$ROOT_DIR/snapshot/database"
EXT_FILE="$SNAPSHOT_DIR/extensions_export.sql"

if [[ ! -f "$EXT_FILE" || ! -s "$EXT_FILE" ]]; then
  echo "No extensions file found. Skipping."
  exit 0
fi

if grep -q "No additional extensions found" "$EXT_FILE" 2>/dev/null; then
  echo "No extensions to sync. Skipping."
  exit 0
fi

source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1

REF="${SUPABASE_PROJECT_REF:-}"
if [[ -z "$REF" ]]; then
  if [[ -f "$ROOT_DIR/supabase/.temp/project-ref" ]]; then
    REF="$(tr -d '\r\n' < "$ROOT_DIR/supabase/.temp/project-ref")"
  fi
fi
if [[ -z "$REF" ]]; then
  echo "SUPABASE_PROJECT_REF is required." >&2
  exit 1
fi

echo "Syncing postgres extensions to remote project ${REF}..."

PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h db."${REF}".supabase.co -p 5432 -U postgres -d postgres -f "$EXT_FILE" 2>/dev/null || true

echo "Extensions synced to remote."
