#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKDIR"

PSQL_BIN="/opt/homebrew/opt/libpq/bin/psql"
if [[ ! -x "$PSQL_BIN" ]]; then
  echo "Missing psql binary under /opt/homebrew/opt/libpq/bin" >&2
  exit 1
fi

if [[ ! -f snapshot/database/schema_public.sql || ! -f snapshot/database/data_public.sql ]]; then
  echo "Schema/data snapshot files missing. Run scripts/export_remote_database_snapshot.sh first." >&2
  exit 1
fi

mkdir -p snapshot/verification

# Ensure local stack is up.
supabase start --exclude vector,logflare --workdir "$WORKDIR" >/tmp/supabase-start.log 2>&1 || {
  cat /tmp/supabase-start.log >&2
  exit 1
}

STATUS_ENV="$(supabase status -o env --workdir "$WORKDIR")"
LOCAL_DB_URL="$(printf '%s\n' "$STATUS_ENV" | sed -n 's/^DB_URL=//p' | head -n1 | sed 's/^\"//; s/\"$//')"
if [[ -z "$LOCAL_DB_URL" ]]; then
  LOCAL_DB_URL="postgresql://postgres:postgres@127.0.0.1:55322/postgres"
fi

ADMIN_DB_URL="$(printf '%s' "$LOCAL_DB_URL" | sed 's#postgresql://postgres:postgres@#postgresql://supabase_admin:postgres@#')"
if [[ "$ADMIN_DB_URL" == "$LOCAL_DB_URL" ]]; then
  ADMIN_DB_URL="postgresql://supabase_admin:postgres@127.0.0.1:55322/postgres"
fi

echo "Local DB URL: $LOCAL_DB_URL" > snapshot/verification/local_restore.log
echo "Admin DB URL: $ADMIN_DB_URL" >> snapshot/verification/local_restore.log

echo "[1/6] Applying role snapshot (best-effort)..." | tee -a snapshot/verification/local_restore.log
if [[ -f snapshot/database/roles.sql ]]; then
  "$PSQL_BIN" "$ADMIN_DB_URL" -v ON_ERROR_STOP=0 -f snapshot/database/roles.sql >> snapshot/verification/local_restore.log 2>&1 || true
fi

echo "[2/6] Dropping non-system schemas in local DB..." | tee -a snapshot/verification/local_restore.log
"$PSQL_BIN" "$ADMIN_DB_URL" -v ON_ERROR_STOP=1 <<'SQL' >> snapshot/verification/local_restore.log 2>&1
DO $$
DECLARE
  target_schema text;
BEGIN
  FOR target_schema IN
    SELECT unnest(array[
      'public',
      'auth',
      'storage',
      'realtime',
      'extensions',
      'graphql',
      'graphql_public',
      'pgbouncer',
      'supabase_functions'
    ]::text[])
  LOOP
    EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', target_schema);
  END LOOP;
END $$;
SQL

echo "[3/6] Restoring schema..." | tee -a snapshot/verification/local_restore.log
# Pass 1: bootstrap auth helpers (auth.uid(), etc) without hard-stop to break circular refs.
if [[ -f snapshot/database/schema_auth.sql ]]; then
  "$PSQL_BIN" "$ADMIN_DB_URL" -v ON_ERROR_STOP=0 -f snapshot/database/schema_auth.sql >> snapshot/verification/local_restore.log 2>&1 || true
fi

# Pass 2: restore public schema once auth helpers exist.
if [[ -f snapshot/database/schema_public.sql ]]; then
  "$PSQL_BIN" "$ADMIN_DB_URL" -v ON_ERROR_STOP=1 -f snapshot/database/schema_public.sql >> snapshot/verification/local_restore.log 2>&1
fi

# Pass 3: re-apply auth strictly now that public schema exists.
if [[ -f snapshot/database/schema_auth.sql ]]; then
  "$PSQL_BIN" "$ADMIN_DB_URL" -v ON_ERROR_STOP=0 -f snapshot/database/schema_auth.sql >> snapshot/verification/local_restore.log 2>&1 || true
fi

if [[ -f snapshot/database/schema_storage.sql ]]; then
  "$PSQL_BIN" "$ADMIN_DB_URL" -v ON_ERROR_STOP=1 -f snapshot/database/schema_storage.sql >> snapshot/verification/local_restore.log 2>&1
fi

if [[ -f snapshot/database/schema_realtime.sql ]]; then
  "$PSQL_BIN" "$ADMIN_DB_URL" -v ON_ERROR_STOP=1 -f snapshot/database/schema_realtime.sql >> snapshot/verification/local_restore.log 2>&1
fi

# Ensure vault schema/table exists for parity checks (managed service table is not fully dumpable).
"$PSQL_BIN" "$ADMIN_DB_URL" -v ON_ERROR_STOP=1 <<'SQL' >> snapshot/verification/local_restore.log 2>&1
CREATE SCHEMA IF NOT EXISTS vault;
CREATE TABLE IF NOT EXISTS vault.secrets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text,
  description text NOT NULL DEFAULT ''::text,
  secret text NOT NULL,
  key_id uuid,
  nonce bytea,
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
SQL

echo "[4/6] Restoring data (replica mode for FK cycles)..." | tee -a snapshot/verification/local_restore.log
{
  echo "SET session_replication_role = replica;"
  for data_file in \
    snapshot/database/data_auth.sql \
    snapshot/database/data_storage.sql \
    snapshot/database/data_realtime.sql \
    snapshot/database/data_public.sql
  do
    if [[ -f "$data_file" ]]; then
      cat "$data_file"
    fi
  done
  echo "SET session_replication_role = origin;"
} | "$PSQL_BIN" "$ADMIN_DB_URL" -v ON_ERROR_STOP=1 >> snapshot/verification/local_restore.log 2>&1

echo "[5/6] Syncing storage binary objects into local storage API..." | tee -a snapshot/verification/local_restore.log
if [[ -s snapshot/storage/buckets.txt ]]; then
  while IFS= read -r bucket; do
    [[ -z "$bucket" ]] && continue
    src_dir="snapshot/storage/objects/${bucket}"
    if [[ -d "$src_dir" ]] && [[ -n "$(find "$src_dir" -type f -mindepth 1 -maxdepth 99 2>/dev/null || true)" ]]; then
      supabase --experimental storage cp -r "$src_dir" "ss:///${bucket}" --local --workdir "$WORKDIR" >> snapshot/verification/local_restore.log 2>&1
    fi
  done < snapshot/storage/buckets.txt
fi

echo "[6/6] Capturing local row estimates for verification..." | tee -a snapshot/verification/local_restore.log
"$PSQL_BIN" "$ADMIN_DB_URL" -At <<'SQL' > snapshot/verification/local_table_row_estimates.txt
select schemaname||'.'||relname||'|'||n_live_tup
from pg_stat_user_tables
order by schemaname, relname;
SQL

echo "Local restore complete." | tee -a snapshot/verification/local_restore.log
