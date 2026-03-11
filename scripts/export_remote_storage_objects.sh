#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKDIR"

PSQL_BIN="/opt/homebrew/opt/libpq/bin/psql"
if [[ ! -x "$PSQL_BIN" ]]; then
  echo "Missing psql binary under /opt/homebrew/opt/libpq/bin" >&2
  exit 1
fi

mkdir -p snapshot/storage/objects snapshot/verification

CREDENTIAL_EXPORTS="$(supabase db dump --linked --dry-run --workdir "$WORKDIR" 2>/dev/null | grep -E '^export PG(HOST|PORT|USER|PASSWORD|DATABASE)=')"
if [[ -z "$CREDENTIAL_EXPORTS" ]]; then
  echo "Failed to obtain remote DB credentials from Supabase CLI." >&2
  exit 1
fi

eval "$CREDENTIAL_EXPORTS"
export PGSSLMODE=require
export PGOPTIONS="-c role=postgres"

CONN_ARGS=("-h" "$PGHOST" "-p" "$PGPORT" "-U" "$PGUSER" "-d" "$PGDATABASE")

"$PSQL_BIN" "${CONN_ARGS[@]}" -At <<'SQL' > snapshot/storage/buckets.txt
select id
from storage.buckets
order by id;
SQL

"$PSQL_BIN" "${CONN_ARGS[@]}" -At <<'SQL' > snapshot/storage/object_rows.txt
select bucket_id || '/' || name || '|' || coalesce(metadata::text, '{}')
from storage.objects
order by bucket_id, name;
SQL

: > snapshot/verification/storage_export_status.txt

if [[ ! -s snapshot/storage/buckets.txt ]]; then
  echo "no_buckets|remote storage has zero buckets" >> snapshot/verification/storage_export_status.txt
  echo "No storage buckets found."
  exit 0
fi

while IFS= read -r bucket; do
  [[ -z "$bucket" ]] && continue
  mkdir -p "snapshot/storage/objects/${bucket}"
  if supabase storage cp -r "ss:///${bucket}" "snapshot/storage/objects/${bucket}" --workdir "$WORKDIR" >"snapshot/storage/${bucket}.cp.log" 2>"snapshot/storage/${bucket}.cp.err"; then
    rm -f "snapshot/storage/${bucket}.cp.err"
    echo "ok|${bucket}" >> snapshot/verification/storage_export_status.txt
  else
    echo "failed|${bucket}|$(tr '\n' ' ' < "snapshot/storage/${bucket}.cp.err")" >> snapshot/verification/storage_export_status.txt
  fi
done < snapshot/storage/buckets.txt

echo "Storage export finished."
