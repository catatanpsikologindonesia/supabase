#!/usr/bin/env bash
# scripts/restore_local_db.sh (Catatan Psikolog Version)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# New default location is snapshot/database, keep backward compatibility.
DUMP_FILE="${1:-snapshot/database/db_full_snapshot.dump}"
if [[ ! -f "$DUMP_FILE" && "$DUMP_FILE" == "snapshot/database/db_full_snapshot.dump" && -f "db_full_snapshot.dump" ]]; then
  DUMP_FILE="db_full_snapshot.dump"
fi
if [[ ! -f "$DUMP_FILE" ]]; then
  echo "Dump file not found: $DUMP_FILE" >&2
  exit 1
fi

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PGOPTIONS='-c client_min_messages=warning'
PROJECT_ID="$(awk -F= '/^project_id[[:space:]]*=/{gsub(/[ "\r]/, "", $2); print $2; exit}' supabase/config.toml)"
COUNTS_FILE="$ROOT_DIR/snapshot/database/db_counts.txt"
RESTORE_ERR_LOG="$ROOT_DIR/.tmp_restore_local_db.err.log"
DB_CONTAINER_NAME="supabase_db_${PROJECT_ID}"
CONTAINER_DUMP_PATH="/tmp/codex_restore_db_full_snapshot.dump"
RESTORE_AUTH_SNAPSHOT_AFTER_FULL_RESTORE="${RESTORE_AUTH_SNAPSHOT_AFTER_FULL_RESTORE:-0}"

# Colima compatibility for Supabase CLI Docker socket mount behavior.
mkdir -p "$HOME/.docker/run"
rm -f "$HOME/.docker/run/docker.sock"
ln -sf "$HOME/.colima/default/docker.sock" "$HOME/.docker/run/docker.sock"
export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"

cleanup_project_containers() {
  local mode="${1:-all}"
  local names=""
  if [[ "$mode" == "exited" ]]; then
    names="$(docker ps -a --format '{{.Names}} {{.Status}}' | awk -v project_id="$PROJECT_ID" '
      index($1, "supabase_") == 1 && $1 ~ ("_" project_id "$") && $2 == "Exited" { print $1 }
    ')"
  else
    names="$(docker ps -a --format '{{.Names}}' | awk -v project_id="$PROJECT_ID" '
      index($1, "supabase_") == 1 && $1 ~ ("_" project_id "$") { print }
    ')"
  fi

  if [[ -n "$names" ]]; then
    echo "Removing ${mode} local Supabase containers for project ${PROJECT_ID}..."
    while IFS= read -r container_name; do
      [[ -n "$container_name" ]] || continue
      docker rm -f "$container_name" >/dev/null
    done <<< "$names"
  fi
}

run_supabase_start_quiet() {
  local output status
  set +e
  # Start with minimum services needed for DB restore
  output="$(supabase start -x gotrue,realtime,storage-api,imgproxy,kong,mailpit,postgrest,postgres-meta,studio,edge-runtime,logflare,vector,supavisor 2>&1)"
  status=$?
  set -e

  if [[ $status -ne 0 ]]; then
     if [[ "$output" == *"already running"* || "$output" == *"exited"* || "$output" == *"failed to create docker container"* ]]; then
        echo "Detected stale Supabase state. Performing deep cleanup and retrying..."
        supabase stop --no-backup >/dev/null 2>&1 || true
        cleanup_project_containers all
        supabase start -x gotrue,realtime,storage-api,imgproxy,kong,mailpit,postgrest,postgres-meta,studio,edge-runtime,logflare,vector,supavisor >/dev/null
        return 0
     fi
     echo "$output" >&2
     return $status
  fi
  return 0
}

# Start local DB only if needed
run_supabase_start_quiet >/dev/null

# Ensure pg_cron exists locally before restore so cron schema/data can be imported.
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -c \
  "CREATE EXTENSION IF NOT EXISTS pg_cron;"

# Restore strategy:
# - Run pg_restore inside the local Postgres container instead of from the host.
# - This avoids mismatched client behavior and ownership/clean anomalies seen
#   when the host binary restores into the active Supabase local database.
# - We still capture stderr to a workspace log for post-failure diagnosis.
rm -f "$RESTORE_ERR_LOG"
docker cp "$DUMP_FILE" "${DB_CONTAINER_NAME}:${CONTAINER_DUMP_PATH}"
docker exec "$DB_CONTAINER_NAME" sh -lc "
  pg_restore \
    --clean --if-exists \
    --no-owner --no-privileges \
    -U postgres -d postgres \
    '${CONTAINER_DUMP_PATH}' \
    >/tmp/codex_restore_local_db.out 2>/tmp/codex_restore_local_db.err || true
"
docker exec "$DB_CONTAINER_NAME" sh -lc "cat /tmp/codex_restore_local_db.err" >"$RESTORE_ERR_LOG" || true

CRON_FILE="$ROOT_DIR/snapshot/database/cron_jobs_export.sql"
if [[ -f "$CRON_FILE" && -s "$CRON_FILE" ]]; then
  # Only attempt restore if the file contains actual SELECT/INSERT/CREATE commands, 
  # and not just a placeholder comment like "# No cron jobs found"
  if grep -qiE "(SELECT|INSERT|CREATE|UPDATE)" "$CRON_FILE"; then
    psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -c \
      "select cron.unschedule(jobid) from cron.job order by jobid;" >/dev/null || true
    psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -f "$CRON_FILE" >/dev/null
  fi
fi

# Restore auth data from local snapshot only by explicit opt-in.
# The full snapshot now includes auth schema+data, so truncating auth.* CASCADE
# after the main restore can wipe dependent public business data through FK chains.
AUTH_DUMP="$ROOT_DIR/snapshot/database/auth_snapshot.dump"
if [[ "$RESTORE_AUTH_SNAPSHOT_AFTER_FULL_RESTORE" == "1" && -f "$AUTH_DUMP" ]]; then
  psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 <<'SQL' || true
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'auth' AND tablename <> 'schema_migrations'
  LOOP
    EXECUTE format('TRUNCATE TABLE auth.%I CASCADE;', r.tablename);
  END LOOP;
END $$;
SQL
  pg_restore --clean --if-exists --no-owner --no-privileges -n auth \
    -h 127.0.0.1 -p 55322 -U postgres -d postgres \
    "$AUTH_DUMP" 2>/dev/null || true
elif [[ -f "$AUTH_DUMP" ]]; then
  echo "Skipping auth snapshot restore by default. Set RESTORE_AUTH_SNAPSHOT_AFTER_FULL_RESTORE=1 to force it."
fi

# Realtime service expects _realtime schema to exist.
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -c \
  "CREATE SCHEMA IF NOT EXISTS _realtime; GRANT ALL ON SCHEMA _realtime TO supabase_admin;"

# Ensure system schemas required by PostgREST/Supabase exist.
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -c \
  "CREATE SCHEMA IF NOT EXISTS graphql_public;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -c \
  "CREATE SCHEMA IF NOT EXISTS extensions;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA graphql_public TO postgres, anon, authenticated, service_role;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;"

# Resync sequences so we don't hit duplicate primary key errors
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -c "
DO \$\$
DECLARE
  seq_row record;
  max_value bigint;
BEGIN
  FOR seq_row IN
    SELECT
      format('%I.%I', seq_ns.nspname, seq.relname) AS seq_name,
      format('%I.%I', tbl_ns.nspname, tbl.relname) AS table_name,
      attr.attname AS column_name
    FROM pg_class seq
    JOIN pg_namespace seq_ns ON seq_ns.oid = seq.relnamespace
    JOIN pg_depend dep ON dep.objid = seq.oid AND dep.deptype = 'a'
    JOIN pg_class tbl ON tbl.oid = dep.refobjid
    JOIN pg_namespace tbl_ns ON tbl_ns.oid = tbl.relnamespace
    JOIN pg_attribute attr ON attr.attrelid = tbl.oid AND attr.attnum = dep.refobjsubid
    WHERE seq.relkind = 'S'
      AND tbl_ns.nspname IN ('auth', 'public', 'cron')
  LOOP
    EXECUTE format('SELECT COALESCE(MAX(%I), 0) FROM %s', seq_row.column_name, seq_row.table_name)
      INTO max_value;

    IF max_value > 0 THEN
      EXECUTE format('SELECT setval(%L, %s, true)', seq_row.seq_name, max_value);
    ELSE
      EXECUTE format('SELECT setval(%L, 1, false)', seq_row.seq_name);
    END IF;
  END LOOP;
END
\$\$;
"

# Remove local-only helper functions so explicit mirror runs stay 1:1 with remote.
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -c \
  "DROP FUNCTION IF EXISTS public.debug_auth();"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -v ON_ERROR_STOP=1 -c \
  "DROP FUNCTION IF EXISTS public.get_my_uid();"

# Quick verify
read_count_expectation() {
  local key="$1"
  [[ -f "$COUNTS_FILE" ]] || return 1
  awk -F= -v key="$key" '$1 == key { print $2; exit }' "$COUNTS_FILE"
}

assert_count_matches() {
  local label="$1"
  local sql="$2"
  local expected="$3"
  local actual
  actual="$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "$sql")"
  echo "${label}=${actual}"
  if [[ -n "$expected" && "$actual" != "$expected" ]]; then
    echo "Restore verification failed for ${label}: expected ${expected}, got ${actual}." >&2
    exit 1
  fi
}

assert_count_matches "public_tables" \
  "select count(*) from pg_tables where schemaname='public';" \
  ""
assert_count_matches "auth_users" \
  "select count(*) from auth.users;" \
  "$(read_count_expectation "auth.users" || true)"
assert_count_matches "public_users" \
  "select count(*) from public.users;" \
  "$(read_count_expectation "public.users" || true)"
assert_count_matches "public_clinics" \
  "select count(*) from public.clinics;" \
  "$(read_count_expectation "public.clinics" || true)"
assert_count_matches "public_clinic_memberships" \
  "select count(*) from public.clinic_memberships;" \
  "$(read_count_expectation "public.clinic_memberships" || true)"
assert_count_matches "public_patients" \
  "select count(*) from public.patients;" \
  "$(read_count_expectation "public.patients" || true)"
assert_count_matches "public_patient_invitations" \
  "select count(*) from public.patient_invitations;" \
  "$(read_count_expectation "public.patient_invitations" || true)"
assert_count_matches "pg_cron_enabled" \
  "select case when exists(select 1 from pg_extension where extname='pg_cron') then '1' else '0' end;" \
  ""

if [[ -f "$RESTORE_ERR_LOG" && -s "$RESTORE_ERR_LOG" ]]; then
  echo "Restore warnings logged to $RESTORE_ERR_LOG"
fi

echo "Done. Local DB restored from $DUMP_FILE"
