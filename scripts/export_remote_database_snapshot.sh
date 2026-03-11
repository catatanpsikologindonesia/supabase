#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKDIR"

PSQL_BIN="/opt/homebrew/opt/libpq/bin/psql"
PG_DUMP_BIN="/opt/homebrew/opt/libpq/bin/pg_dump"
PG_DUMPALL_BIN="/opt/homebrew/opt/libpq/bin/pg_dumpall"

if [[ ! -x "$PSQL_BIN" || ! -x "$PG_DUMP_BIN" || ! -x "$PG_DUMPALL_BIN" ]]; then
  echo "Missing libpq binaries under /opt/homebrew/opt/libpq/bin" >&2
  exit 1
fi

mkdir -p snapshot/database snapshot/verification

# Reuse Supabase CLI login role bootstrap to obtain ephemeral DB credentials.
CREDENTIAL_EXPORTS="$(supabase db dump --linked --dry-run --workdir "$WORKDIR" 2>/dev/null | grep -E '^export PG(HOST|PORT|USER|PASSWORD|DATABASE)=')"
if [[ -z "$CREDENTIAL_EXPORTS" ]]; then
  echo "Failed to obtain remote DB credentials from Supabase CLI." >&2
  exit 1
fi

eval "$CREDENTIAL_EXPORTS"
export PGSSLMODE=require
export PGOPTIONS="-c role=postgres"

CONN_ARGS=("-h" "$PGHOST" "-p" "$PGPORT" "-U" "$PGUSER" "-d" "$PGDATABASE")
GLOBAL_CONN_ARGS=("-h" "$PGHOST" "-p" "$PGPORT" "-U" "$PGUSER")

echo "[1/6] Querying schema catalog..."
"$PSQL_BIN" "${CONN_ARGS[@]}" -At <<'SQL' > snapshot/verification/remote_schemas_catalog.txt
select nspname
from pg_namespace
where nspname !~ '^pg_'
  and nspname <> 'information_schema'
order by 1;
SQL

echo "[2/6] Querying table row estimates..."
"$PSQL_BIN" "${CONN_ARGS[@]}" -At <<'SQL' > snapshot/verification/remote_table_row_estimates.txt
select schemaname||'.'||relname||'|'||n_live_tup
from pg_stat_user_tables
order by schemaname, relname;
SQL

echo "[3/6] Dumping globals/roles..."
if ! "$PG_DUMPALL_BIN" "${GLOBAL_CONN_ARGS[@]}" --role=postgres --globals-only --no-role-passwords > snapshot/database/roles.sql; then
  echo "WARN: pg_dumpall globals failed, generating fallback roles snapshot from catalog views..."
  {
    echo "-- Fallback roles snapshot (password hashes are not available via this role)."
    echo "-- Generated from pg_roles and pg_auth_members."
    "$PSQL_BIN" "${CONN_ARGS[@]}" -At <<'SQL'
select
  'create role "' || rolname || '"'
  || case when rolcanlogin then ' login' else ' nologin' end
  || case when rolsuper then ' superuser' else ' nosuperuser' end
  || case when rolcreatedb then ' createdb' else ' nocreatedb' end
  || case when rolcreaterole then ' createrole' else ' nocreaterole' end
  || case when rolreplication then ' replication' else ' noreplication' end
  || case when rolbypassrls then ' bypassrls' else ' nobypassrls' end
  || ';'
from pg_roles
where rolname !~ '^pg_'
order by rolname;
SQL
    "$PSQL_BIN" "${CONN_ARGS[@]}" -At <<'SQL'
select
  'grant "' || granted.rolname || '" to "' || member.rolname || '"'
  || case when m.admin_option then ' with admin option' else '' end
  || ';'
from pg_auth_members m
join pg_roles granted on granted.oid = m.roleid
join pg_roles member on member.oid = m.member
where granted.rolname !~ '^pg_' and member.rolname !~ '^pg_'
order by granted.rolname, member.rolname;
SQL
  } > snapshot/database/roles.sql
fi

echo "[4/6] Dumping full schema (all non-system schemas)..."
"$PG_DUMP_BIN" "${CONN_ARGS[@]}" \
  --role=postgres \
  --schema-only \
  --quote-all-identifiers \
  --exclude-schema='pg_*' \
  --exclude-schema='information_schema' \
  > snapshot/database/schema_all.sql

echo "[5/6] Dumping full data (all non-system schemas)..."
"$PG_DUMP_BIN" "${CONN_ARGS[@]}" \
  --role=postgres \
  --data-only \
  --exclude-schema='pg_*' \
  --exclude-schema='information_schema' \
  > snapshot/database/data_all.sql

echo "[6/6] Dumping per-schema slices..."
for schema_name in auth public storage realtime supabase_functions; do
  if "$PSQL_BIN" "${CONN_ARGS[@]}" -Atc "select 1 from pg_namespace where nspname = '${schema_name}' limit 1;" | grep -q '^1$'; then
    "$PG_DUMP_BIN" "${CONN_ARGS[@]}" --role=postgres --schema-only --schema="$schema_name" > "snapshot/database/schema_${schema_name}.sql"
    "$PG_DUMP_BIN" "${CONN_ARGS[@]}" --role=postgres --data-only --schema="$schema_name" > "snapshot/database/data_${schema_name}.sql"
  fi
done

echo "Done. Snapshot files are under snapshot/database and snapshot/verification."
