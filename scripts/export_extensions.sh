#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SNAPSHOT_DIR="$ROOT_DIR/snapshot/database"
mkdir -p "$SNAPSHOT_DIR"

if [[ -f "$ROOT_DIR/supabase/.temp/project-ref" ]]; then
  REF="$(tr -d '\r\n' < "$ROOT_DIR/supabase/.temp/project-ref")"
else
  echo "No linked project. Run 'supabase link' first or pull snapshot."
  exit 0
fi

source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1

echo "Exporting postgres extensions from remote project ${REF}..."

PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h db."${REF}".supabase.co -p 5432 -U postgres -d postgres -t -A -c "
SELECT 
  'CREATE EXTENSION IF NOT EXISTS ' || quote_ident(extname) || 
  CASE WHEN extversion IS NOT NULL THEN 
    ' VERSION ' || quote_literal(extversion) 
  ELSE '' END ||
  CASE WHEN extschema IS NOT NULL AND extschema != 'public' THEN 
    ' SCHEMA ' || quote_ident(extschema) 
  ELSE '' END ||
  ';'
FROM pg_extension
WHERE extname NOT IN ('plpgsql')
ORDER BY extname;
" > "$SNAPSHOT_DIR/extensions_export.sql" 2>/dev/null || true

if [[ ! -s "$SNAPSHOT_DIR/extensions_export.sql" ]]; then
  echo "-- No additional extensions found" > "$SNAPSHOT_DIR/extensions_export.sql"
  echo "No additional extensions found on remote."
else
  echo "Extensions exported to $SNAPSHOT_DIR/extensions_export.sql"
fi
