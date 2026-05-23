#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_remote_db_env.sh"

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

EXPECTED_PROJECT_REF="${EXPECTED_PROJECT_REF:-ixwaaziifteubxkxtdwj}"
if [[ "${SUPABASE_PROJECT_REF}" != "${EXPECTED_PROJECT_REF}" ]]; then
  echo "Project ref mismatch. Expected ${EXPECTED_PROJECT_REF}, got ${SUPABASE_PROJECT_REF}." >&2
  exit 1
fi

rm -rf .tmp_push_local_data
mkdir -p .tmp_push_local_data/public

LOCAL_DB_URL="$(supabase status 2>/dev/null | awk '/^[[:space:]]*│ URL[[:space:]]*│ postgresql:/{print $4; exit}')"
if [[ -z "$LOCAL_DB_URL" ]]; then
  echo "Failed to detect local DB URL from 'supabase status'." >&2
  exit 1
fi

echo "[0/7] Patch missing remote public columns from local schema..."
LOCAL_COLUMN_SQL="$(psql "$LOCAL_DB_URL" -v ON_ERROR_STOP=1 -Atc "
  SELECT table_name || '|' || column_name || '|' || data_type
  FROM information_schema.columns
  WHERE table_schema = 'public'
  ORDER BY table_name, ordinal_position;
")"
REMOTE_COLUMN_KEYS="$(psql "$REMOTE_URI" -v ON_ERROR_STOP=1 -Atc "
  SELECT table_name || '|' || column_name
  FROM information_schema.columns
  WHERE table_schema = 'public'
  ORDER BY table_name, ordinal_position;
")"

while IFS='|' read -r table_name column_name data_type; do
  [[ -z "$table_name" || -z "$column_name" || -z "$data_type" ]] && continue
  if ! grep -Fxq "${table_name}|${column_name}" <<<"$REMOTE_COLUMN_KEYS"; then
    echo "  - add public.${table_name}.${column_name} ${data_type}"
    psql "$REMOTE_URI" -v ON_ERROR_STOP=1 -c "ALTER TABLE public.\"${table_name}\" ADD COLUMN IF NOT EXISTS \"${column_name}\" ${data_type};" >/dev/null
  fi
done <<<"$LOCAL_COLUMN_SQL"

LOCAL_TABLE_LIST=()
while IFS= read -r line; do
  [[ -n "$line" ]] && LOCAL_TABLE_LIST+=("$line")
done < <(
  psql "$LOCAL_DB_URL" -v ON_ERROR_STOP=1 -Atc "
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename NOT IN ('edge_rate_limit_events', 'otp_verifications')
    ORDER BY tablename;
  "
)

REMOTE_TABLE_LIST=()
while IFS= read -r line; do
  [[ -n "$line" ]] && REMOTE_TABLE_LIST+=("$line")
done < <(
  psql "$REMOTE_URI" -v ON_ERROR_STOP=1 -Atc "
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
    ORDER BY tablename;
  "
)

SYNC_TABLE_LIST=()
for table_name in "${LOCAL_TABLE_LIST[@]}"; do
  for remote_table in "${REMOTE_TABLE_LIST[@]}"; do
    if [[ "$table_name" == "$remote_table" ]]; then
      SYNC_TABLE_LIST+=("$table_name")
      break
    fi
  done
done

PUBLIC_TABLES=""
for table_name in "${SYNC_TABLE_LIST[@]}"; do
  if [[ -z "$PUBLIC_TABLES" ]]; then
    PUBLIC_TABLES="public.${table_name}"
  else
    PUBLIC_TABLES+=" , public.${table_name}"
  fi
done

if [[ -z "$PUBLIC_TABLES" ]]; then
  echo "No public tables found to sync." >&2
  exit 1
fi

echo "[1/7] Dump public tables per-table from local..."
while IFS= read -r table_name; do
  [[ -z "$table_name" ]] && continue
  echo "  - dump public.${table_name}"
  pg_dump --data-only --column-inserts --no-owner --no-privileges \
    --rows-per-insert=100 \
    -d "$LOCAL_DB_URL" \
    -t "public.${table_name}" \
    -f ".tmp_push_local_data/public/${table_name}.sql"
done < <(printf '%s\n' "${SYNC_TABLE_LIST[@]}")

echo "[2/7] Dump auth.users + auth.identities from local..."
pg_dump --data-only --column-inserts --no-owner --no-privileges \
  --rows-per-insert=100 \
  -d "$LOCAL_DB_URL" \
  -t 'auth.users' \
  -t 'auth.identities' \
  -f ".tmp_push_local_data/auth.sql"

echo "[3/7] Truncate remote public + auth tables..."
psql "$REMOTE_URI" -v ON_ERROR_STOP=1 -c "
  SET session_replication_role = replica;
  TRUNCATE TABLE ${PUBLIC_TABLES} CASCADE;
  TRUNCATE TABLE auth.identities CASCADE;
  TRUNCATE TABLE auth.users CASCADE;
" >/dev/null

echo "[4/7] Apply public table dumps to remote..."
while IFS= read -r table_file; do
  [[ -z "$table_file" ]] && continue
  table_basename="$(basename "$table_file")"
  echo "  - restore ${table_basename}"
  psql "$REMOTE_URI" -v ON_ERROR_STOP=1 \
    -c "SET session_replication_role = replica;" \
    -f "$table_file" \
    -c "SET session_replication_role = origin;" >/dev/null
done < <(ls .tmp_push_local_data/public/*.sql | sort)

echo "[5/7] Apply auth dump to remote..."
psql "$REMOTE_URI" -v ON_ERROR_STOP=1 \
  -c "SET session_replication_role = replica;" \
  -f ".tmp_push_local_data/auth.sql" \
  -c "SET session_replication_role = origin;" >/dev/null

echo "[6/7] Reset session replication role..."
psql "$REMOTE_URI" -v ON_ERROR_STOP=1 -c "SET session_replication_role = origin;" >/dev/null

echo "[7/7] Verify key counts..."
psql "$REMOTE_URI" -v ON_ERROR_STOP=1 -Atc "
  select 'auth.users='||count(*) from auth.users;
  select 'public.clinics='||count(*) from public.clinics;
  select 'public.users='||count(*) from public.users;
  select 'public.address_postal_code='||count(*) from public.address_postal_code;
"

echo "PUSH LOCAL DATA OK: ${SUPABASE_PROJECT_REF}"
