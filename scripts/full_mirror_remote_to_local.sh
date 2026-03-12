#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_remote_db_env.sh"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

mkdir -p "$HOME/.docker/run"
ln -sf "$HOME/.colima/default/docker.sock" "$HOME/.docker/run/docker.sock"
export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"

mkdir -p .tmp_storage_sync
SNAPSHOT_FN_DIR="$ROOT_DIR/snapshot/functions"
mkdir -p "$SNAPSHOT_FN_DIR"

echo "[1/7] Pull remote snapshot (DB + Edge function source)..."
bash scripts/pull_remote_snapshot.sh

echo "[2/7] Start local stack..."
bash scripts/start_local_stack.sh

echo "[3/7] Restore DB snapshot to local (public+cron)..."
bash scripts/restore_local_db.sh

echo "[4/8] Verify auth parity (safe, non-destructive)..."
bash scripts/sync_auth_remote_to_local.sh

echo "[5/8] Sync pg_cron jobs..."
bash scripts/sync_cron_remote_to_local.sh

echo "[6/8] Sync storage binaries + metadata..."
bash scripts/sync_storage_remote_to_local.sh

echo "[7/8] Capture function metadata from remote..."
supabase functions list --project-ref "$SUPABASE_PROJECT_REF" --output json > .tmp_storage_sync/remote_functions.json

# Make verify_jwt/version visible in mirror repo for auditing and team visibility
jq '{generated_at: now|todate, functions: [.[] | {slug, verify_jwt, version, status}]}' \
  .tmp_storage_sync/remote_functions.json > "$SNAPSHOT_FN_DIR/functions_metadata.json"

echo "[8/8] Parity audit (key business domains)..."
REMOTE_PUBLIC_TABLES=$(psql "$REMOTE_URI" -qAtc "set role postgres; select count(*) from pg_tables where schemaname='public';")
REMOTE_PUBLIC_FUNCTIONS=$(psql "$REMOTE_URI" -qAtc "set role postgres; select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public';")
REMOTE_CRON_AVAILABLE=$(psql "$REMOTE_URI" -qAtc "set role postgres; select case when to_regclass('cron.job') is null then '0' else '1' end;")
if [[ "$REMOTE_CRON_AVAILABLE" == "1" ]]; then
  REMOTE_CRON_JOBS=$(psql "$REMOTE_URI" -qAtc "set role postgres; select count(*) from cron.job;")
else
  REMOTE_CRON_JOBS="0"
fi
REMOTE_AUTH_USERS=$(psql "$REMOTE_URI" -qAtc "set role postgres; select count(*) from auth.users;")
REMOTE_AUTH_IDENTITIES=$(psql "$REMOTE_URI" -qAtc "set role postgres; select count(*) from auth.identities;")
REMOTE_STORAGE_OBJECTS=$(psql "$REMOTE_URI" -qAtc "set role postgres; select count(*) from storage.objects;")

LOCAL_PUBLIC_TABLES=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select count(*) from pg_tables where schemaname='public';")
LOCAL_PUBLIC_FUNCTIONS=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public';")
LOCAL_CRON_AVAILABLE=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select case when to_regclass('cron.job') is null then '0' else '1' end;")
if [[ "$LOCAL_CRON_AVAILABLE" == "1" ]]; then
  LOCAL_CRON_JOBS=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select count(*) from cron.job;")
else
  LOCAL_CRON_JOBS="0"
fi
LOCAL_AUTH_USERS=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select count(*) from auth.users;")
LOCAL_AUTH_IDENTITIES=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select count(*) from auth.identities;")
LOCAL_STORAGE_OBJECTS=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select count(*) from storage.objects;")

REMOTE_COUNTS=$(
  cat <<EOF
public_tables=${REMOTE_PUBLIC_TABLES}
public_functions=${REMOTE_PUBLIC_FUNCTIONS}
cron_available=${REMOTE_CRON_AVAILABLE}
cron_jobs=${REMOTE_CRON_JOBS}
auth_users=${REMOTE_AUTH_USERS}
auth_identities=${REMOTE_AUTH_IDENTITIES}
storage_objects=${REMOTE_STORAGE_OBJECTS}
EOF
)

LOCAL_COUNTS=$(
  cat <<EOF
public_tables=${LOCAL_PUBLIC_TABLES}
public_functions=${LOCAL_PUBLIC_FUNCTIONS}
cron_available=${LOCAL_CRON_AVAILABLE}
cron_jobs=${LOCAL_CRON_JOBS}
auth_users=${LOCAL_AUTH_USERS}
auth_identities=${LOCAL_AUTH_IDENTITIES}
storage_objects=${LOCAL_STORAGE_OBJECTS}
EOF
)

printf "%s\n" "$REMOTE_COUNTS" > .tmp_storage_sync/remote_counts.txt
printf "%s\n" "$LOCAL_COUNTS" > .tmp_storage_sync/local_counts.txt

echo "--- remote counts ---"
cat .tmp_storage_sync/remote_counts.txt

echo "--- local counts ---"
cat .tmp_storage_sync/local_counts.txt

if ! diff -u .tmp_storage_sync/remote_counts.txt .tmp_storage_sync/local_counts.txt >/tmp/mirror_counts.diff; then
  echo "Mirror mismatch detected:" >&2
  cat /tmp/mirror_counts.diff >&2
  exit 1
fi

echo "FULL MIRROR OK (key domains matched): DB(public), Auth, Storage, Edge source+metadata [${REMOTE_CONNECTION_MODE}]"
