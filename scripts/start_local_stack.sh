#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
LOCAL_PSQL="postgresql://postgres:postgres@127.0.0.1:55322/postgres"
PROJECT_ID="$(awk -F= '/^project_id[[:space:]]*=/{gsub(/[ "\r]/, "", $2); print $2; exit}' supabase/config.toml)"

mkdir -p "$HOME/.docker/run"
rm -f "$HOME/.docker/run/docker.sock"
ln -sf "$HOME/.colima/default/docker.sock" "$HOME/.docker/run/docker.sock"
export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

AUTO_PREPARE_LOCAL_ON_START="${AUTO_PREPARE_LOCAL_ON_START:-0}"

if [[ -f ".env.local" ]]; then
  set -a
  # Load tracked local env so Supabase edge runtime secrets resolve during local start.
  source ".env.local"
  set +a
fi

cleanup_project_containers() {
  local mode="${1:-all}"
  local names=""

  if [[ "$mode" == "exited" ]]; then
    names="$(docker ps -a --format '{{.Names}} {{.Status}}' | awk -v project_id="$PROJECT_ID" '
      index($1, "supabase_") == 1 && $1 ~ ("_" project_id "$") && $2 == "Exited" { print $1 }
    ')"
  else
    names="$(docker ps -a --format '{{.Names}}' | awk -v project_id="$PROJECT_ID" '
      index($1, "supabase_") == 1 && $1 ~ ("_" project_id "$") { print }
    ')"
  fi

  if [[ -n "$names" ]]; then
    echo "Removing ${mode} local Supabase containers for project ${PROJECT_ID}..."
    while IFS= read -r container_name; do
      [[ -n "$container_name" ]] || continue
      docker rm -f "$container_name" >/dev/null
    done <<< "$names"
  fi
}

if [[ "$AUTO_PREPARE_LOCAL_ON_START" == "1" ]]; then
  echo "Preparing local DB baseline before starting full stack..."
  bash scripts/prepare_local_db.sh
else
  echo "Skipping local DB prepare to preserve current local data (set AUTO_PREPARE_LOCAL_ON_START=1 to enable)."
fi

status_output="$(supabase status 2>&1 || true)"
if [[ "$status_output" == *"Stopped services:"* ]]; then
  echo "Restarting local Supabase stack to enable API services..."
  supabase stop >/dev/null
fi

cleanup_project_containers exited

echo "Starting full local Supabase stack..."
start_output="$(supabase start 2>&1)" || {
  if [[ "$start_output" == *"failed to create docker container"* && "$start_output" == *"already in use by container"* ]]; then
    echo "Detected stale local Supabase containers for project ${PROJECT_ID}. Retrying once after cleanup..."
    cleanup_project_containers all
    supabase start >/dev/null
  else
    echo "$start_output" >&2
    exit 1
  fi
}

psql "$LOCAL_PSQL" -v ON_ERROR_STOP=1 -c \
  "CREATE SCHEMA IF NOT EXISTS graphql_public;" >/dev/null
psql "$LOCAL_PSQL" -v ON_ERROR_STOP=1 -c \
  "CREATE SCHEMA IF NOT EXISTS extensions;" >/dev/null
psql "$LOCAL_PSQL" -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;" >/dev/null
psql "$LOCAL_PSQL" -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA graphql_public TO postgres, anon, authenticated, service_role;" >/dev/null
psql "$LOCAL_PSQL" -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;" >/dev/null

api_port="$(awk -F= '
  /^\[api\]/ { in_api=1; next }
  /^\[/ { in_api=0 }
  in_api && $1 ~ /^port / { gsub(/[ "]/, "", $2); print $2; exit }
' supabase/config.toml)"
db_port="$(awk -F= '
  /^\[db\]/ { in_db=1; next }
  /^\[/ { in_db=0 }
  in_db && $1 ~ /^port / { gsub(/[ "]/, "", $2); print $2; exit }
' supabase/config.toml)"
studio_port="$(awk -F= '
  /^\[studio\]/ { in_studio=1; next }
  /^\[/ { in_studio=0 }
  in_studio && $1 ~ /^port / { gsub(/[ "]/, "", $2); print $2; exit }
' supabase/config.toml)"
inbucket_port="$(awk -F= '
  /^\[inbucket\]/ { in_inbucket=1; next }
  /^\[/ { in_inbucket=0 }
  in_inbucket && $1 ~ /^port / { gsub(/[ "]/, "", $2); print $2; exit }
' supabase/config.toml)"

status_env="$(supabase status -o env 2>/dev/null | awk '/^[A-Z_]+=\"?.*\"?$/')"
anon_key="$(echo "$status_env" | awk -F= '/^ANON_KEY=/{gsub(/"/,"",$2); print $2}')"
service_role_key="$(echo "$status_env" | awk -F= '/^SERVICE_ROLE_KEY=/{gsub(/"/,"",$2); print $2}')"
s3_access_key="$(echo "$status_env" | awk -F= '/^S3_ACCESS_KEY=/{gsub(/"/,"",$2); print $2}')"
s3_secret_key="$(echo "$status_env" | awk -F= '/^S3_SECRET_KEY=/{gsub(/"/,"",$2); print $2}')"

read_env_value() {
  local file="$1"
  local key="$2"
  [[ -f "$file" ]] || return 0
  awk -F= -v key="$key" '
    $1 == key {
      value=substr($0, index($0, "=") + 1)
      gsub(/^"/, "", value)
      gsub(/"$/, "", value)
      print value
      exit
    }
  ' "$file"
}

if [[ -z "$anon_key" ]]; then
  anon_key="$(read_env_value "../../catatan-psikolog-user-portal/scripts/.env.local" "NEXT_PUBLIC_SUPABASE_ANON_KEY_LOCAL")"
fi
if [[ -z "$service_role_key" ]]; then
  service_role_key="$(read_env_value ".env.local.keys" "LOCAL_SERVICE_ROLE_KEY")"
fi
if [[ -z "$s3_access_key" ]]; then
  s3_access_key="$(read_env_value ".env.local.keys" "LOCAL_S3_ACCESS_KEY")"
fi
if [[ -z "$s3_secret_key" ]]; then
  s3_secret_key="$(read_env_value ".env.local.keys" "LOCAL_S3_SECRET_KEY")"
fi

api_url="http://127.0.0.1:${api_port}"
db_url="postgresql://postgres:postgres@127.0.0.1:${db_port}/postgres"
studio_url="http://127.0.0.1:${studio_port}"
inbucket_url="http://127.0.0.1:${inbucket_port}"

echo
echo "Mode: DB baseline prepared (safe mode, avoids migration-chain init failure)."
echo

print_section() {
  local title="$1"
  shift
  clip() {
    local input="$1"
    local width="$2"
    if (( ${#input} > width )); then
      printf "%s..." "${input:0:width-3}"
    else
      printf "%s" "$input"
    fi
  }
  local title_view
  title_view="$(clip "$title" 75)"
  echo "╭───────────────────────────────────────────────────────────────────────────╮"
  printf "│ %-75s │\n" "$title_view"
  echo "├──────────────┬────────────────────────────────────────────────────────────┤"
  while (( "$#" )); do
    local key="$1"
    local value="$2"
    local key_view
    local value_view
    shift 2
    key_view="$(clip "$key" 12)"
    value_view="$(clip "$value" 58)"
    printf "│ %-12s │ %-58s │\n" "$key_view" "$value_view"
  done
  echo "╰──────────────┴────────────────────────────────────────────────────────────╯"
  echo
}

print_section "Development Tools" \
  "Studio" "${studio_url}" \
  "Mailpit" "${inbucket_url}" \
  "MCP" "${api_url}/mcp"

print_section "APIs" \
  "Project URL" "${api_url}" \
  "REST" "${api_url}/rest/v1" \
  "GraphQL" "${api_url}/graphql/v1" \
  "Edge Fn" "${api_url}/functions/v1"

print_section "Database" \
  "URL" "${db_url}"

print_section "Authentication Keys" \
  "Publishable" "${anon_key:-N/A}" \
  "Secret" "${service_role_key:-N/A}"

print_section "Storage (S3)" \
  "URL" "${api_url}/storage/v1/s3" \
  "Access Key" "${s3_access_key:-N/A}" \
  "Secret Key" "${s3_secret_key:-N/A}" \
  "Region" "local"
