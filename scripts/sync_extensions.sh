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
source "$ROOT_DIR/scripts/load_remote_db_env.sh"

echo "Syncing postgres extensions to remote project ${SUPABASE_PROJECT_REF}..."

psql "$REMOTE_URI" -f "$EXT_FILE"

echo "Extensions synced to remote."
