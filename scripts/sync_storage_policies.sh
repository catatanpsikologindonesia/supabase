#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

echo "Syncing storage RLS policies to remote project ${REF}..."

LOCAL_DB_URL="postgresql://postgres:${SUPABASE_DB_PASSWORD}@127.0.0.1:55322/postgres"
REMOTE_DB_URL="postgresql://postgres:${SUPABASE_DB_PASSWORD}@db.${REF}.supabase.co:5432/postgres"

REMOTE_POLICIES=$(PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h db."${REF}".supabase.co -p 5432 -U postgres -d postgres -t -A -c "
SELECT json_agg(json_build_object(
  'tablename', tablename,
  'policyname', policyname,
  'cmd', cmd,
  'qual', COALESCE(qual, ''),
  'with_check', COALESCE(with_check, '')
))
FROM pg_policies
WHERE schemaname = 'storage';
" 2>/dev/null | tr -d ' \n' || echo "[]")

if [[ "$REMOTE_POLICIES" == "[]" || -z "$REMOTE_POLICIES" ]]; then
  echo "No existing remote policies, will create from local."
fi

LOCAL_POLICIES=$(PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h 127.0.0.1 -p 55322 -U postgres -d postgres -t -A -c "
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  cmd,
  COALESCE(qual, '')::text as qual,
  COALESCE(with_check, '')::text as with_check
FROM pg_policies
WHERE schemaname = 'storage'
ORDER BY tablename, policyname;
" 2>/dev/null || echo "")

if [[ -z "$LOCAL_POLICIES" ]]; then
  echo "No local storage policies found. Skipping."
  exit 0
fi

echo "Dropping existing remote storage policies..."
PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h db."${REF}".supabase.co -p 5432 -U postgres -d postgres -c "
DO \$\$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN 
    SELECT tablename, policyname 
    FROM pg_policies 
    WHERE schemaname = 'storage'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.%I', pol.policyname, pol.tablename);
  END LOOP;
END \$\$;
" 2>/dev/null || true

echo "Creating storage policies on remote..."
echo "$LOCAL_POLICIES" | while IFS='|' read -r schemaname tablename policyname permissive cmd qual with_check; do
  [[ -z "$tablename" || -z "$policyname" ]] && continue
  
  if [[ -n "$qual" && "$qual" != "NULL" ]]; then
    PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h db."${REF}".supabase.co -p 5432 -U postgres -d postgres -c "
    CREATE POLICY ${policyname} ON storage.${tablename}
    FOR ${cmd}
    USING ($(echo "$qual" | sed "s/'/''/g"))
    $(if [[ -n "$with_check" && "$with_check" != "NULL" ]]; then echo "WITH CHECK ($(echo "$with_check" | sed "s/'/''/g"))"; fi);
    " 2>/dev/null
  else
    PGPASSWORD="$SUPABASE_DB_PASSWORD" psql -h db."${REF}".supabase.co -p 5432 -U postgres -d postgres -c "
    CREATE POLICY ${policyname} ON storage.${tablename}
    FOR ${cmd};
    " 2>/dev/null
  fi
  
  echo "  Created: ${tablename}.${policyname}"
done

echo "Storage RLS policies synced to remote."
