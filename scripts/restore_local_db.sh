#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# New default location is snapshot/database, keep backward compatibility.
DUMP_FILE="${1:-snapshot/database/db_full_snapshot.dump}"
if [[ ! -f "$DUMP_FILE" && "$DUMP_FILE" == "snapshot/database/db_full_snapshot.dump" && -f "db_full_snapshot.dump" ]]; then
  DUMP_FILE="db_full_snapshot.dump"
fi
if [[ ! -f "$DUMP_FILE" ]]; then
  echo "Dump file not found: $DUMP_FILE" >&2
  exit 1
fi

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Colima compatibility for Supabase CLI Docker socket mount behavior.
mkdir -p "$HOME/.docker/run"
ln -sf "$HOME/.colima/default/docker.sock" "$HOME/.docker/run/docker.sock"
export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"

# Start local DB only if needed
supabase start -x gotrue,realtime,storage-api,imgproxy,kong,mailpit,postgrest,postgres-meta,studio,edge-runtime,logflare,vector,supavisor >/dev/null

# Align pg_cron local extension with remote snapshot state.
EXT_FILE="snapshot/database/db_extensions.txt"
REMOTE_HAS_PG_CRON=0
if [[ -f "$EXT_FILE" ]] && grep -qx "pg_cron" "$EXT_FILE"; then
  REMOTE_HAS_PG_CRON=1
fi

if [[ "$REMOTE_HAS_PG_CRON" -eq 1 ]]; then
  psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
    "CREATE EXTENSION IF NOT EXISTS pg_cron;"
else
  psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
    "DROP EXTENSION IF EXISTS pg_cron CASCADE;" >/dev/null || true
fi

# Restore public + cron to avoid managed schema ownership conflicts in auth/storage internals.
export PGPASSWORD="postgres"
pg_restore \
  --clean --if-exists \
  --no-owner --no-privileges \
  -n public -n cron \
  -h 127.0.0.1 -p 55322 -U postgres -d postgres \
  "$DUMP_FILE" || true

# Realtime service expects _realtime schema to exist.
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
  "CREATE SCHEMA IF NOT EXISTS _realtime; GRANT ALL ON SCHEMA _realtime TO supabase_admin;"

# Ensure system schemas required by PostgREST/Supabase exist.
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
  "CREATE SCHEMA IF NOT EXISTS graphql_public;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
  "CREATE SCHEMA IF NOT EXISTS extensions;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA graphql_public TO postgres, anon, authenticated, service_role;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;"

# Quick verify
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc \
  "select 'public_tables='||count(*) from pg_tables where schemaname='public';"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc \
  "select 'pg_cron_enabled='||(exists(select 1 from pg_extension where extname='pg_cron'));"

echo "Done. Local DB restored from $DUMP_FILE"
