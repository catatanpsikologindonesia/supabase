#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKDIR"

PSQL_BIN="/opt/homebrew/opt/libpq/bin/psql"
if [[ ! -x "$PSQL_BIN" ]]; then
  echo "Missing psql binary under /opt/homebrew/opt/libpq/bin" >&2
  exit 1
fi

mkdir -p snapshot/verification

# Remote connection via ephemeral credentials
REMOTE_EXPORTS="$(supabase db dump --linked --dry-run --workdir "$WORKDIR" 2>/dev/null | grep -E '^export PG(HOST|PORT|USER|PASSWORD|DATABASE)=')"
if [[ -z "$REMOTE_EXPORTS" ]]; then
  echo "Failed to obtain remote credentials" >&2
  exit 1
fi

eval "$REMOTE_EXPORTS"
export PGSSLMODE=require
export PGOPTIONS="-c role=postgres"
REMOTE_HOST="$PGHOST"
REMOTE_PORT="$PGPORT"
REMOTE_USER="$PGUSER"
REMOTE_DB="$PGDATABASE"
REMOTE_PASS="$PGPASSWORD"

STATUS_ENV="$(supabase status -o env --workdir "$WORKDIR")"
LOCAL_DB_URL="$(printf '%s\n' "$STATUS_ENV" | sed -n 's/^DB_URL=//p' | head -n1 | sed 's/^"//; s/"$//')"
if [[ -z "$LOCAL_DB_URL" ]]; then
  LOCAL_DB_URL="postgresql://postgres:postgres@127.0.0.1:55322/postgres"
fi
LOCAL_ADMIN_URL="postgresql://supabase_admin:postgres@127.0.0.1:55322/postgres?sslmode=disable"

echo "table|remote_count|local_count|match" > snapshot/verification/exact_count_compare.txt

TABLES="$($PSQL_BIN -h "$REMOTE_HOST" -p "$REMOTE_PORT" -U "$REMOTE_USER" -d "$REMOTE_DB" -At <<'SQL'
select format('%I.%I', schemaname, tablename)
from pg_tables
where schemaname in ('public','auth','storage','realtime','vault')
order by 1;
SQL
)"

while IFS= read -r table_name; do
  [[ "$table_name" == "SET" ]] && continue
  [[ -z "$table_name" ]] && continue
  remote_count="$($PSQL_BIN -h "$REMOTE_HOST" -p "$REMOTE_PORT" -U "$REMOTE_USER" -d "$REMOTE_DB" -At <<SQL
select count(*) from ${table_name};
SQL
)"

  local_count="$($PSQL_BIN "$LOCAL_ADMIN_URL" -At <<SQL
select count(*) from ${table_name};
SQL
)"

  if [[ "$remote_count" == "$local_count" ]]; then
    match="yes"
  else
    match="no"
  fi
  echo "${table_name}|${remote_count}|${local_count}|${match}" >> snapshot/verification/exact_count_compare.txt
done <<< "$TABLES"

awk -F'|' 'NR==1{next} $4=="no"{c++} END{print (c+0)}' snapshot/verification/exact_count_compare.txt > snapshot/verification/exact_count_mismatch_total.txt

echo "Exact count comparison complete."
