#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Colima compatibility for Supabase CLI Docker socket mount behavior.
mkdir -p "$HOME/.docker/run"
ln -sf "$HOME/.colima/default/docker.sock" "$HOME/.docker/run/docker.sock"
export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"

MIG_DIR="$ROOT_DIR/supabase/migrations"
PARKED_MIG_DIR="$MIG_DIR/.local_bootstrap_parked"
LOCAL_PSQL="postgresql://postgres:postgres@127.0.0.1:55322/postgres"
RESTORE_LOG="$(mktemp -t catatanpsikolog_prepare_local_restore.XXXXXX.log)"

mkdir -p "$PARKED_MIG_DIR"

restore_parked_migrations() {
  shopt -s nullglob
  local parked
  for parked in "$PARKED_MIG_DIR"/*.sql; do
    mv "$parked" "$MIG_DIR/"
  done
  shopt -u nullglob
  rmdir "$PARKED_MIG_DIR" 2>/dev/null || true
}
trap restore_parked_migrations EXIT

echo "[1/5] Parking migrations for deterministic local bootstrap..."
shopt -s nullglob
for migration in "$MIG_DIR"/*.sql; do
  mv "$migration" "$PARKED_MIG_DIR/"
done
shopt -u nullglob

echo "[2/5] Restoring local database snapshot..."
if ! bash scripts/restore_local_db.sh >"$RESTORE_LOG" 2>&1; then
  echo "Restore failed. Dumping restore log:" >&2
  cat "$RESTORE_LOG" >&2
  exit 1
fi

echo "[3/5] Re-applying migrations on top of restored snapshot..."
while IFS= read -r migration; do
  [[ -z "$migration" ]] && continue
  echo "  -> $(basename "$migration")"
  PGOPTIONS='-c client_min_messages=warning' \
    psql "$LOCAL_PSQL" -q -v ON_ERROR_STOP=1 -f "$migration" >/dev/null
done < <(find "$PARKED_MIG_DIR" -maxdepth 1 -type f -name '*.sql' | sort)

echo "[4/5] Verifying key local artifacts..."
PUBLIC_TABLES="$(psql "$LOCAL_PSQL" -Atc "select count(*) from pg_tables where schemaname='public';")"
if [[ -z "$PUBLIC_TABLES" || "$PUBLIC_TABLES" -lt 1 ]]; then
  echo "Verification failed: public schema appears empty after restore." >&2
  echo "Restore log follows:" >&2
  cat "$RESTORE_LOG" >&2
  exit 1
fi
echo "public_tables=${PUBLIC_TABLES}"

CORE_TABLES_PRESENT="$(psql "$LOCAL_PSQL" -Atc "select (to_regclass('public.users') is not null and to_regclass('public.clinics') is not null)::text;")"
if [[ "$CORE_TABLES_PRESENT" != "true" ]]; then
  echo "Verification failed: expected core tables public.users/public.clinics are missing." >&2
  exit 1
fi
echo "has_core_tables=true"

echo "[5/5] Restoring migration files..."
restore_parked_migrations
trap - EXIT
rm -f "$RESTORE_LOG"

echo "LOCAL DB READY: snapshot restored + migrations re-applied."
