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

echo "Exporting cron jobs from remote project ${REF}..."

PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h db."${REF}".supabase.co -p 5432 -U postgres -d postgres -t -A -c "
SELECT 
  'SELECT cron.schedule(' ||
  quote_literal(jobname) || ', ' ||
  quote_literal(schedule) || ', ' ||
  quote_literal(command) || ');'
FROM cron.job;
" > "$SNAPSHOT_DIR/cron_jobs_export.sql" 2>/dev/null || true

if [[ ! -s "$SNAPSHOT_DIR/cron_jobs_export.sql" ]]; then
  echo "# No cron jobs found" > "$SNAPSHOT_DIR/cron_jobs_export.sql"
  echo "No cron jobs found on remote."
else
  echo "Cron jobs exported to $SNAPSHOT_DIR/cron_jobs_export.sql"
fi
