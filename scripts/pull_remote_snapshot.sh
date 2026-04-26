#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_remote_db_env.sh"

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

SNAPSHOT_DB_DIR="$ROOT_DIR/snapshot/database"
SNAPSHOT_FN_DIR="$ROOT_DIR/snapshot/functions"
mkdir -p supabase/functions "$SNAPSHOT_DB_DIR" "$SNAPSHOT_FN_DIR"

PULL_REMOTE_FUNCTIONS="${PULL_REMOTE_FUNCTIONS:-1}"
EXPECTED_PROJECT_REF="${EXPECTED_PROJECT_REF:-${SUPABASE_PROJECT_REF}}"

if [[ -z "${SUPABASE_PROJECT_REF:-}" ]]; then
  echo "SUPABASE_PROJECT_REF is not loaded. Aborting snapshot pull." >&2
  exit 1
fi

if [[ "${SUPABASE_PROJECT_REF}" != "${EXPECTED_PROJECT_REF}" ]]; then
  echo "Project ref mismatch. Expected ${EXPECTED_PROJECT_REF}, got ${SUPABASE_PROJECT_REF}." >&2
  exit 1
fi

# Pull schema through pg_dump
pg_dump --schema-only --no-owner --no-privileges \
  -d "$REMOTE_URI" \
  > "$SNAPSHOT_DB_DIR/schema_snapshot.sql"

# Full dump for restore flow
pg_dump -Fc --no-owner --no-privileges \
  -d "$REMOTE_URI" \
  -f "$SNAPSHOT_DB_DIR/db_full_snapshot.dump"

# Inventory files
psql "$REMOTE_URI" -Atc \
  "select schemaname||'.'||tablename from pg_tables where schemaname not in ('pg_catalog','information_schema') order by 1;" > "$SNAPSHOT_DB_DIR/db_tables.txt"
psql "$REMOTE_URI" -Atc \
  "select n.nspname||'.'||p.proname||'('||pg_get_function_identity_arguments(p.oid)||')' from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname not in ('pg_catalog','information_schema') order by 1;" > "$SNAPSHOT_DB_DIR/db_functions.txt"
psql "$REMOTE_URI" -Atc \
  "select schemaname||'.'||viewname from pg_views where schemaname not in ('pg_catalog','information_schema') order by 1;" > "$SNAPSHOT_DB_DIR/db_views.txt"
psql "$REMOTE_URI" -Atc \
  "select extname from pg_extension order by 1;" > "$SNAPSHOT_DB_DIR/db_extensions.txt"

psql "$REMOTE_URI" -Atc "
select 'project_ref=${SUPABASE_PROJECT_REF}';
select 'remote_connection_mode=${REMOTE_CONNECTION_MODE}';
select 'auth.users='||count(*) from auth.users;
select 'public.users='||count(*) from public.users;
select 'public.clinics='||count(*) from public.clinics;
select 'public.clinic_memberships='||count(*) from public.clinic_memberships;
select 'public.patients='||count(*) from public.patients;
select 'public.patient_invitations='||count(*) from public.patient_invitations;
" > "$SNAPSHOT_DB_DIR/db_counts.txt"

# Edge Functions
if [[ "$PULL_REMOTE_FUNCTIONS" == "1" ]]; then
  supabase functions list --project-ref "$SUPABASE_PROJECT_REF" --output json > "$SNAPSHOT_FN_DIR/functions_list.json"
  jq -r '.[].slug' "$SNAPSHOT_FN_DIR/functions_list.json" | while read -r slug; do
    [[ -z "$slug" ]] && continue
    supabase functions download "$slug" --project-ref "$SUPABASE_PROJECT_REF" --use-api >/dev/null
    echo "Downloaded function: $slug"
  done
else
  echo "Skipping remote edge function download (PULL_REMOTE_FUNCTIONS=0)."
fi

echo "Done. Snapshot updated in: $ROOT_DIR (remote connection: ${REMOTE_CONNECTION_MODE})"
