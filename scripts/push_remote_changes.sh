#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

EXPECTED_PROJECT_REF="${EXPECTED_PROJECT_REF:-ixwaaziifteubxkxtdwj}"
if [[ "${SUPABASE_PROJECT_REF}" != "${EXPECTED_PROJECT_REF}" ]]; then
  echo "Project ref mismatch. Expected ${EXPECTED_PROJECT_REF}, got ${SUPABASE_PROJECT_REF}." >&2
  exit 1
fi

mkdir -p .tmp_push
SNAPSHOT_DB_DIR="$ROOT_DIR/snapshot/database"
SCHEMA_FILE="$SNAPSHOT_DB_DIR/schema_snapshot.sql"
DUMP_FILE="$SNAPSHOT_DB_DIR/db_full_snapshot.dump"
if [[ ! -f "$SCHEMA_FILE" && -f "$ROOT_DIR/schema_snapshot.sql" ]]; then
  SCHEMA_FILE="$ROOT_DIR/schema_snapshot.sql"
fi
if [[ ! -f "$DUMP_FILE" && -f "$ROOT_DIR/db_full_snapshot.dump" ]]; then
  DUMP_FILE="$ROOT_DIR/db_full_snapshot.dump"
fi

echo "[0/10] Ensure linked context..."
CURRENT_LINKED_REF=""
if [[ -f "$ROOT_DIR/supabase/.temp/project-ref" ]]; then
  CURRENT_LINKED_REF="$(tr -d '\r\n' < "$ROOT_DIR/supabase/.temp/project-ref")"
fi
if [[ "$CURRENT_LINKED_REF" == "$SUPABASE_PROJECT_REF" ]]; then
  echo "Linked project already set: ${CURRENT_LINKED_REF}"
else
  supabase link --project-ref "$SUPABASE_PROJECT_REF" --password "$SUPABASE_DB_PASSWORD" >/dev/null
fi

echo "[1/10] Verify local vs remote state..."
set +e
bash scripts/verify_local_remote_diff.sh
VERIFY_EXIT=$?
set -e

if [[ "$VERIFY_EXIT" -eq 2 ]]; then
  echo
  echo "Warning: mismatch found between local and remote."
  if [[ "${AUTO_APPROVE_PUSH:-0}" == "1" ]]; then
    echo "AUTO_APPROVE_PUSH=1 -> continue push."
  else
    read -r -p "Tetap lanjut push ke ${SUPABASE_PROJECT_REF}? (yes/no): " PUSH_CONFIRM
    if [[ "$PUSH_CONFIRM" != "yes" ]]; then
      echo "Push dibatalkan."
      exit 1
    fi
  fi
elif [[ "$VERIFY_EXIT" -ne 0 ]]; then
  echo "Verify gagal dijalankan. Push dibatalkan." >&2
  exit 1
fi

echo "[2/10] Backup remote snapshot before push..."
bash scripts/pull_remote_snapshot.sh
BACKUP_TS="$(date +%Y%m%d_%H%M%S)"
cp -f "$SCHEMA_FILE" ".tmp_push/schema_snapshot.before_push.${BACKUP_TS}.sql"
cp -f "$DUMP_FILE" ".tmp_push/db_full_snapshot.before_push.${BACKUP_TS}.dump"

echo "[3/10] Push DB migrations..."
supabase db push

echo "[3.5/12] Sync postgres extensions (pg_cron, etc.)..."
bash scripts/sync_extensions.sh

echo "[3.6/12] Sync cron jobs..."
bash scripts/sync_cron_jobs.sh

echo "[4/12] Sync storage binaries + bucket metadata..."
bash scripts/sync_storage_local_to_remote.sh

echo "[5/12] Sync storage RLS policies..."
bash scripts/sync_storage_policies.sh

echo "[6/12] Push project config (auth, realtime, etc.)..."
supabase config push --project-ref "$SUPABASE_PROJECT_REF" --yes 2>/dev/null || echo "  config push skipped (may not be supported on this plan)"

echo "[7/12] Push edge function secrets..."
EDGE_FUNCTION_SECRETS=$(grep -E '^(MAIL_|SMS_|WEBHOOK_|AUTH_|JWT_)' "$ENV_FILE" | grep -v '^#' || true)
if [[ -n "$EDGE_FUNCTION_SECRETS" ]]; then
  SECRET_COUNT=0
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      key="$(echo "$line" | cut -d '=' -f1)"
      value="${line#*=}"
      echo "  - set ${key}"
      supabase secrets set "${key}=${value}" --project-ref "$SUPABASE_PROJECT_REF" >/dev/null 2>&1 || true
      SECRET_COUNT=$((SECRET_COUNT + 1))
    fi
  done <<<"$EDGE_FUNCTION_SECRETS"
  echo "  Secrets updated for ${SECRET_COUNT} keys."
else
  echo "  No edge function secrets found in ${ENV_FILE}."
fi

echo "[8/12] Deploy edge functions..."
if [[ -d "supabase/functions" ]]; then
  while IFS= read -r fn_dir; do
    slug="$(basename "$fn_dir")"
    echo "  - deploy ${slug}"
    supabase functions deploy "$slug" --project-ref "$SUPABASE_PROJECT_REF"
  done < <(find supabase/functions -mindepth 1 -maxdepth 1 -type d ! -name "_*" | sort)
fi

echo "[9/12] Verify deployed functions..."
supabase functions list --project-ref "$SUPABASE_PROJECT_REF" --output json > .tmp_push/remote_functions_after_push.json

LOCAL_FUNCTIONS_SORTED="$(find supabase/functions -mindepth 1 -maxdepth 1 -type d ! -name "_*" -exec basename {} \; | sort || true)"
REMOTE_FUNCTIONS_SORTED="$(jq -r '.[].slug' .tmp_push/remote_functions_after_push.json | sort || true)"

if [[ -n "$LOCAL_FUNCTIONS_SORTED" ]]; then
  while IFS= read -r local_fn; do
    if ! grep -qx "$local_fn" <<<"$REMOTE_FUNCTIONS_SORTED"; then
      echo "Function deploy verify failed: ${local_fn} not found on remote." >&2
      exit 1
    fi
  done <<<"$LOCAL_FUNCTIONS_SORTED"
fi

echo "[10/12] Export remote cron jobs to local (backup)..."
bash scripts/export_cron_jobs.sh

echo "[11/12] Export remote extensions to local (backup)..."
bash scripts/export_extensions.sh

echo "[12/12] Verify key parity counts (public tables/functions + storage objects)..."
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_remote_db_env.sh"
REMOTE_COUNTS=$(psql "$REMOTE_URI" -Atc "
select 'public_tables='||count(*) from pg_tables where schemaname='public';
select 'public_functions='||count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public';
select 'storage_objects='||count(*) from storage.objects where name <> '.emptyFolderPlaceholder' and name !~ '/\\.emptyFolderPlaceholder$';
")
printf "%s\n" "$REMOTE_COUNTS" > .tmp_push/remote_counts_after_push.txt
cat .tmp_push/remote_counts_after_push.txt

echo "PUSH OK: local changes applied to remote project ${SUPABASE_PROJECT_REF}"
