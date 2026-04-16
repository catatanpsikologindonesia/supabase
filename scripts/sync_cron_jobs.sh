#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SNAPSHOT_DIR="$ROOT_DIR/snapshot/database"
CRON_FILE="$SNAPSHOT_DIR/cron_jobs_export.sql"

if [[ ! -f "$CRON_FILE" || ! -s "$CRON_FILE" ]]; then
  echo "No cron jobs file found. Skipping."
  exit 0
fi

if grep -q "No cron jobs found" "$CRON_FILE" 2>/dev/null; then
  echo "No cron jobs to sync. Skipping."
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

echo "Syncing cron jobs to remote project ${REF}..."

echo "Dropping existing cron jobs..."
PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h db."${REF}".supabase.co -p 5432 -U postgres -d postgres -c "
SELECT cron.unschedule(jobid) FROM cron.job;
" 2>/dev/null || true

echo "Creating cron jobs..."
PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h db."${REF}".supabase.co -p 5432 -U postgres -d postgres -f "$CRON_FILE" 2>/dev/null || true

echo "Cron jobs synced to remote."
