#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_remote_db_env.sh"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

mkdir -p .tmp_storage_sync
REMOTE_ROWS=".tmp_storage_sync/remote_cron_rows.tsv"

REMOTE_HAS_CRON=$(psql "$REMOTE_URI" -qAtc "set role postgres; select case when to_regclass('cron.job') is null then '0' else '1' end;")
LOCAL_HAS_CRON=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select case when to_regclass('cron.job') is null then '0' else '1' end;")

# Align local pg_cron extension presence with remote.
if [[ "$REMOTE_HAS_CRON" == "0" && "$LOCAL_HAS_CRON" == "1" ]]; then
  psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "drop extension if exists pg_cron cascade;" >/dev/null || true
  LOCAL_HAS_CRON=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select case when to_regclass('cron.job') is null then '0' else '1' end;")
elif [[ "$REMOTE_HAS_CRON" == "1" && "$LOCAL_HAS_CRON" == "0" ]]; then
  psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "create extension if not exists pg_cron;" >/dev/null || true
  LOCAL_HAS_CRON=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select case when to_regclass('cron.job') is null then '0' else '1' end;")
fi

if [[ "$REMOTE_HAS_CRON" == "1" ]]; then
  psql "$REMOTE_URI" -qAtF $'\t' -c \
  "set role postgres; select coalesce(jobname,''), schedule, command, database, username, case when active then 'true' else 'false' end from cron.job order by jobid" > "$REMOTE_ROWS"
else
  : > "$REMOTE_ROWS"
fi

# Clear local cron jobs
if [[ "$LOCAL_HAS_CRON" == "1" ]]; then
  psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc \
  "select cron.unschedule(jobid) from cron.job order by jobid;" >/dev/null || true
fi

while IFS=$'\t' read -r jobname schedule command database username active; do
  [[ -z "${schedule:-}" ]] && continue

  esc_jobname=${jobname//\'/\'\'}
  esc_schedule=${schedule//\'/\'\'}
  esc_command=${command//\'/\'\'}
  esc_database=${database//\'/\'\'}
  esc_username=${username//\'/\'\'}

  if [[ -n "$jobname" ]]; then
    NEW_ID=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc \
      "select cron.schedule('$esc_jobname', '$esc_schedule', '$esc_command');")
  else
    NEW_ID=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc \
      "select cron.schedule('$esc_schedule', '$esc_command');")
  fi

  psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc \
    "select cron.alter_job(job_id => ${NEW_ID}, active => ${active});" >/dev/null
done < "$REMOTE_ROWS"

if [[ "$REMOTE_HAS_CRON" == "1" ]]; then
  REMOTE_COUNT=$(psql "$REMOTE_URI" -qAtc "set role postgres; select count(*) from cron.job;")
else
  REMOTE_COUNT="0"
fi

if [[ "$LOCAL_HAS_CRON" == "1" ]]; then
  LOCAL_COUNT=$(psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -Atc "select count(*) from cron.job;")
else
  LOCAL_COUNT="0"
fi

echo "remote_has_cron=${REMOTE_HAS_CRON}"
echo "local_has_cron=${LOCAL_HAS_CRON}"
echo "remote_cron_jobs=${REMOTE_COUNT}"
echo "local_cron_jobs=${LOCAL_COUNT}"

if [[ "$REMOTE_HAS_CRON" != "$LOCAL_HAS_CRON" || "$REMOTE_COUNT" != "$LOCAL_COUNT" ]]; then
  echo "ERROR: cron sync mismatch" >&2
  exit 1
fi

echo "Cron sync OK"
