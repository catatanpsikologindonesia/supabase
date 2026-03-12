#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_remote_db_env.sh"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

VERIFY_ROOT="$ROOT_DIR/snapshot/verification"
mkdir -p "$VERIFY_ROOT"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="$VERIFY_ROOT/verify_local_remote_${TS}"
mkdir -p "$OUT_DIR"

REMOTE_PSQL="$REMOTE_URI"
LOCAL_PSQL="postgresql://postgres:postgres@127.0.0.1:55322/postgres"

echo "[1/8] Collect public tables..."
psql "$REMOTE_PSQL" -qAtc "set role postgres; select tablename from pg_tables where schemaname='public' order by 1;" > "$OUT_DIR/remote_public_tables.txt"
psql "$LOCAL_PSQL" -Atc "select tablename from pg_tables where schemaname='public' order by 1;" > "$OUT_DIR/local_public_tables.txt"

echo "[2/8] Collect public functions..."
psql "$REMOTE_PSQL" -qAtc "set role postgres; select p.proname||'('||pg_get_function_identity_arguments(p.oid)||')' from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' order by 1;" > "$OUT_DIR/remote_public_functions.txt"
psql "$LOCAL_PSQL" -Atc "select p.proname||'('||pg_get_function_identity_arguments(p.oid)||')' from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' order by 1;" > "$OUT_DIR/local_public_functions.txt"

echo "[3/8] Collect views..."
psql "$REMOTE_PSQL" -qAtc "set role postgres; select viewname from pg_views where schemaname='public' order by 1;" > "$OUT_DIR/remote_public_views.txt"
psql "$LOCAL_PSQL" -Atc "select viewname from pg_views where schemaname='public' order by 1;" > "$OUT_DIR/local_public_views.txt"

echo "[4/8] Collect cron jobs..."
REMOTE_CRON_AVAILABLE=$(psql "$REMOTE_PSQL" -qAtc "set role postgres; select case when to_regclass('cron.job') is null then '0' else '1' end;")
LOCAL_CRON_AVAILABLE=$(psql "$LOCAL_PSQL" -Atc "select case when to_regclass('cron.job') is null then '0' else '1' end;")
printf "%s\n" "$REMOTE_CRON_AVAILABLE" > "$OUT_DIR/remote_cron_available.txt"
printf "%s\n" "$LOCAL_CRON_AVAILABLE" > "$OUT_DIR/local_cron_available.txt"
if [[ "$REMOTE_CRON_AVAILABLE" == "1" ]]; then
  psql "$REMOTE_PSQL" -qAtc "set role postgres; select coalesce(jobname,'')||'|'||schedule||'|'||command from cron.job order by 1;" > "$OUT_DIR/remote_cron_jobs.txt"
else
  : > "$OUT_DIR/remote_cron_jobs.txt"
fi
if [[ "$LOCAL_CRON_AVAILABLE" == "1" ]]; then
  psql "$LOCAL_PSQL" -Atc "select coalesce(jobname,'')||'|'||schedule||'|'||command from cron.job order by 1;" > "$OUT_DIR/local_cron_jobs.txt"
else
  : > "$OUT_DIR/local_cron_jobs.txt"
fi

echo "[5/8] Collect storage objects..."
psql "$REMOTE_PSQL" -qAtc "set role postgres; select bucket_id||'/'||name from storage.objects order by 1;" > "$OUT_DIR/remote_storage_objects.txt"
psql "$LOCAL_PSQL" -Atc "select bucket_id||'/'||name from storage.objects order by 1;" > "$OUT_DIR/local_storage_objects.txt"

echo "[6/8] Collect auth counts..."
psql "$REMOTE_PSQL" -qAtc "set role postgres; select 'auth_users='||count(*) from auth.users; select 'auth_identities='||count(*) from auth.identities;" > "$OUT_DIR/remote_auth_counts.txt"
psql "$LOCAL_PSQL" -Atc "select 'auth_users='||count(*) from auth.users; select 'auth_identities='||count(*) from auth.identities;" > "$OUT_DIR/local_auth_counts.txt"

echo "[7/8] Collect edge functions..."
supabase functions list --project-ref "$SUPABASE_PROJECT_REF" --output json | jq -r '.[].slug' | sort > "$OUT_DIR/remote_functions_slugs.txt"
find supabase/functions -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort > "$OUT_DIR/local_functions_slugs.txt"

echo "[8/8] Compare..."
MISMATCH=0

compare_pair() {
  local left="$1"
  local right="$2"
  local label="$3"
  local diff_file="$OUT_DIR/diff_${label}.txt"
  if ! diff -u "$left" "$right" > "$diff_file"; then
    echo "Mismatch: ${label}"
    MISMATCH=1
  else
    rm -f "$diff_file"
    echo "OK: ${label}"
  fi
}

compare_pair "$OUT_DIR/remote_public_tables.txt" "$OUT_DIR/local_public_tables.txt" "public_tables"
compare_pair "$OUT_DIR/remote_public_functions.txt" "$OUT_DIR/local_public_functions.txt" "public_functions"
compare_pair "$OUT_DIR/remote_public_views.txt" "$OUT_DIR/local_public_views.txt" "public_views"
compare_pair "$OUT_DIR/remote_cron_available.txt" "$OUT_DIR/local_cron_available.txt" "cron_available"
compare_pair "$OUT_DIR/remote_cron_jobs.txt" "$OUT_DIR/local_cron_jobs.txt" "cron_jobs"
compare_pair "$OUT_DIR/remote_storage_objects.txt" "$OUT_DIR/local_storage_objects.txt" "storage_objects"
compare_pair "$OUT_DIR/remote_auth_counts.txt" "$OUT_DIR/local_auth_counts.txt" "auth_counts"
compare_pair "$OUT_DIR/remote_functions_slugs.txt" "$OUT_DIR/local_functions_slugs.txt" "edge_functions"

echo
echo "Verify output: $OUT_DIR"
echo "Remote connection mode: ${REMOTE_CONNECTION_MODE}"
if [[ "$MISMATCH" -eq 0 ]]; then
  echo "VERIFY OK: local and remote are aligned."
  exit 0
fi

echo "VERIFY MISMATCH: check diff_* files in $OUT_DIR"
exit 2
