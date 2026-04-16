#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1

SNAPSHOT_DIR="$ROOT_DIR/snapshot/storage"
POLICIES_FILE="$SNAPSHOT_DIR/storage_policies_raw.txt"

if [[ ! -f "$POLICIES_FILE" || ! -s "$POLICIES_FILE" ]]; then
  echo "No storage policies file found. Run export first or pull from remote."
  exit 0
fi

REF="${SUPABASE_PROJECT_REF:-}"
if [[ -z "$REF" ]]; then
  REF="$(tr -d '\r\n' < "$ROOT_DIR/supabase/.temp/project-ref" 2>/dev/null || true)"
fi
if [[ -z "$REF" ]]; then
  echo "SUPABASE_PROJECT_REF is required." >&2
  exit 1
fi

echo "Applying storage policies to remote project ${REF}..."

PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h db."${REF}".supabase.co -p 5432 -U postgres -d postgres << 'EOF'
-- Drop existing storage policies
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN 
    SELECT schemaname, tablename, policyname 
    FROM pg_policies 
    WHERE schemaname = 'storage'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
  END LOOP;
END $$;

-- Apply storage policies from snapshot
\i snapshot/storage/storage_policies_raw.sql
EOF

echo "Storage policies applied."
