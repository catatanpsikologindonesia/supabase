#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SNAPSHOT_DIR="$ROOT_DIR/snapshot/database"
mkdir -p "$SNAPSHOT_DIR"

source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1
source "$ROOT_DIR/scripts/load_remote_db_env.sh"

echo "Exporting postgres extensions from remote project ${SUPABASE_PROJECT_REF}..."

psql "$REMOTE_URI" -t -A -c "
SELECT 
  'CREATE EXTENSION IF NOT EXISTS ' || quote_ident(extname) || 
  CASE WHEN extversion IS NOT NULL THEN 
    ' VERSION ' || quote_literal(extversion) 
  ELSE '' END ||
  CASE WHEN n.nspname IS NOT NULL AND n.nspname != 'public' THEN 
    ' SCHEMA ' || quote_ident(n.nspname) 
  ELSE '' END ||
  ';'
FROM pg_extension e
LEFT JOIN pg_namespace n ON n.oid = e.extnamespace
WHERE extname NOT IN ('plpgsql')
ORDER BY extname;
" > "$SNAPSHOT_DIR/extensions_export.sql"

if [[ ! -s "$SNAPSHOT_DIR/extensions_export.sql" ]]; then
  echo "-- No additional extensions found" > "$SNAPSHOT_DIR/extensions_export.sql"
  echo "No additional extensions found on remote."
else
  echo "Extensions exported to $SNAPSHOT_DIR/extensions_export.sql"
fi
