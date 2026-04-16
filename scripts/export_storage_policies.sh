#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1

REF="${SUPABASE_PROJECT_REF:-}"
if [[ -z "$REF" ]]; then
  REF="$(tr -d '\r\n' < "$ROOT_DIR/supabase/.temp/project-ref" 2>/dev/null || true)"
fi
if [[ -z "$REF" ]]; then
  echo "SUPABASE_PROJECT_REF is required." >&2
  exit 1
fi

SNAPSHOT_DIR="$ROOT_DIR/snapshot/storage"
mkdir -p "$SNAPSHOT_DIR"

PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h db."${REF}".supabase.co -p 5432 -U postgres -d postgres -t -A -c "
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'storage'
ORDER BY schemaname, tablename, policyname;
" > "$SNAPSHOT_DIR/storage_policies_raw.txt" 2>/dev/null || true

if [[ ! -s "$SNAPSHOT_DIR/storage_policies_raw.txt" ]]; then
  echo "No storage policies found or connection failed."
  exit 0
fi

cat "$SNAPSHOT_DIR/storage_policies_raw.txt"

echo "Storage policies exported to $SNAPSHOT_DIR/storage_policies_raw.txt"
