#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# Load project ref + db password from local secrets helper
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_remote_db_env.sh"

if [[ -z "${SUPABASE_PROJECT_REF:-}" ]]; then
  echo "SUPABASE_PROJECT_REF is required" >&2
  exit 1
fi

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
mkdir -p .tmp_storage_sync
AUTH_DUMP=".tmp_storage_sync/auth_data_remote.dump"

echo "[1/4] Count remote auth rows..."
REMOTE_USERS=$(psql "$REMOTE_URI" -qAtc "set role postgres; select count(*) from auth.users;")
REMOTE_IDENTITIES=$(psql "$REMOTE_URI" -qAtc "set role postgres; select count(*) from auth.identities;")

echo "[2/4] Count local auth rows..."
export PGPASSWORD="postgres"
LOCAL_USERS=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select count(*) from auth.users;")
LOCAL_IDENTITIES=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select count(*) from auth.identities;")

echo "[3/4] Compare auth row counts..."
echo "remote_auth_users=${REMOTE_USERS}"
echo "local_auth_users=${LOCAL_USERS}"
echo "remote_auth_identities=${REMOTE_IDENTITIES}"
echo "local_auth_identities=${LOCAL_IDENTITIES}"

if [[ "$REMOTE_USERS" != "$LOCAL_USERS" || "$REMOTE_IDENTITIES" != "$LOCAL_IDENTITIES" ]]; then
  if [[ "${ALLOW_DESTRUCTIVE_AUTH_SYNC:-0}" != "1" ]]; then
    echo "ERROR: auth parity mismatch (safe mode)." >&2
    echo "To force legacy destructive auth restore, re-run with ALLOW_DESTRUCTIVE_AUTH_SYNC=1." >&2
    echo "Warning: legacy restore can cascade-delete public data through FK from auth.users." >&2
    exit 1
  fi
  echo "Auth mismatch detected. Running legacy destructive auth restore..."
  echo "[4/4] Dump + restore auth data (destructive mode)..."
  pg_dump -Fc --data-only --no-owner --no-privileges \
    --role "postgres" \
    --exclude-table-data=auth.schema_migrations \
    -n auth \
    -d "$REMOTE_URI" \
    -f "$AUTH_DUMP"

  export PGPASSWORD="postgres"
  psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 <<'SQL'
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'auth'
      AND tablename <> 'schema_migrations'
  LOOP
    EXECUTE format('TRUNCATE TABLE auth.%I CASCADE;', r.tablename);
  END LOOP;
END $$;
SQL
  pg_restore --clean --if-exists --no-owner --no-privileges -n auth \
    -h 127.0.0.1 -p 55322 -U postgres -d postgres \
    "$AUTH_DUMP"
fi

echo "Auth parity OK: 1:1 for auth.users and auth.identities"
