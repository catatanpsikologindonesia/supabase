#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/load_local_secrets.sh" >/dev/null 2>&1

REF="${SUPABASE_PROJECT_REF:-}"
if [[ -z "$REF" && -f "$ROOT_DIR/supabase/.temp/project-ref" ]]; then
  REF="$(tr -d '\r\n' < "$ROOT_DIR/supabase/.temp/project-ref")"
fi
if [[ -z "$REF" ]]; then
  echo "SUPABASE_PROJECT_REF is required (or link project so supabase/.temp/project-ref exists)." >&2
  exit 1
fi

REMOTE_URL="https://${REF}.supabase.co"
LOCAL_URL="${LOCAL_SUPABASE_URL:-http://127.0.0.1:55321}"
TMP_DIR="${ROOT_DIR}/.tmp_storage_push"
mkdir -p "$TMP_DIR"

REMOTE_CURL_BASE=(curl -sS --fail --show-error --ipv4 --http1.1 --connect-timeout 10 --max-time 90)
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  REMOTE_CURL_BASE=(docker run --rm curlimages/curl:8.8.0 -sS --fail --show-error --ipv4 --http1.1 --connect-timeout 10 --max-time 90)
fi

retry_cmd() {
  local attempts=0
  local max_attempts="${1:-5}"
  shift || true
  local delay=2
  local rc=0
  while (( attempts < max_attempts )); do
    set +e
    "$@"
    rc=$?
    set -e
    if [[ $rc -eq 0 ]]; then
      return 0
    fi
    attempts=$((attempts + 1))
    echo "retry ${attempts}/${max_attempts} failed (rc=${rc}), waiting ${delay}s..." >&2
    sleep "$delay"
    delay=$((delay * 2))
  done
  return "$rc"
}

remote_http() {
  "${REMOTE_CURL_BASE[@]}" "$@"
}

remote_upload_file() {
  curl -sS --fail --show-error --ipv4 --http1.1 --connect-timeout 10 --max-time 180 "$@"
}

json_get_remote() {
  local url="$1"
  local key="$2"
  local outfile="$3"
  retry_cmd 5 remote_http \
    -H "apikey: ${key}" \
    -H "Authorization: Bearer ${key}" \
    "$url" > "$outfile"
}

json_get_local() {
  local url="$1"
  local key="$2"
  local outfile="$3"
  retry_cmd 5 curl -sS --fail --show-error --connect-timeout 10 --max-time 90 \
    -H "apikey: ${key}" \
    -H "Authorization: Bearer ${key}" \
    "$url" > "$outfile"
}

resolve_remote_service_role_key() {
  local out
  out="$(retry_cmd 5 remote_http \
    -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
    "https://api.supabase.com/v1/projects/${REF}/api-keys?reveal=true")" || return 1

  echo "$out" | jq -r '.[] | select(.id=="service_role") | .api_key'
}

REMOTE_SERVICE_ROLE_KEY="${REMOTE_SERVICE_ROLE_KEY:-}"
if [[ -z "$REMOTE_SERVICE_ROLE_KEY" ]]; then
  REMOTE_SERVICE_ROLE_KEY="$(resolve_remote_service_role_key || true)"
fi
if [[ -z "$REMOTE_SERVICE_ROLE_KEY" || "$REMOTE_SERVICE_ROLE_KEY" == "null" ]]; then
  echo "Failed to resolve REMOTE_SERVICE_ROLE_KEY from project ${REF}" >&2
  exit 1
fi

LOCAL_SERVICE_ROLE_KEY="${LOCAL_SERVICE_ROLE_KEY:-$(supabase status -o env | awk -F= '/^SERVICE_ROLE_KEY=/{gsub(/"/,"",$2); print $2}')}"
if [[ -z "$LOCAL_SERVICE_ROLE_KEY" ]]; then
  echo "Failed to resolve LOCAL_SERVICE_ROLE_KEY from supabase status" >&2
  exit 1
fi

urlencode_path() {
  python3 - <<'PY' "$1"
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe='/'))
PY
}

ensure_remote_buckets() {
  local remote_buckets_json local_buckets_json
  remote_buckets_json="${TMP_DIR}/remote_buckets.json"
  local_buckets_json="${TMP_DIR}/local_buckets.json"

  echo "Fetching local and remote buckets..."
  json_get_remote "${REMOTE_URL}/storage/v1/bucket" "$REMOTE_SERVICE_ROLE_KEY" "$remote_buckets_json"
  json_get_local "${LOCAL_URL}/storage/v1/bucket" "$LOCAL_SERVICE_ROLE_KEY" "$local_buckets_json"

  echo "Ensuring buckets exist on remote..."
  while IFS= read -r bucket_b64; do
    local bucket_json bucket_id bucket_name bucket_public bucket_limit bucket_mime payload
    bucket_json="$(echo "$bucket_b64" | base64 --decode)"
    bucket_id="$(echo "$bucket_json" | jq -r '.id')"
    bucket_name="$(echo "$bucket_json" | jq -r '.name')"
    bucket_public="$(echo "$bucket_json" | jq -r '.public // false')"
    bucket_limit="$(echo "$bucket_json" | jq -r '.file_size_limit // empty')"
    bucket_mime="$(echo "$bucket_json" | jq -c '.allowed_mime_types // []')"

    if jq -e --arg id "$bucket_id" '.[] | select(.id==$id)' "$remote_buckets_json" >/dev/null; then
      continue
    fi

    payload="$(jq -n \
      --arg id "$bucket_id" \
      --arg name "$bucket_name" \
      --argjson public "$bucket_public" \
      --argjson allowed_mime_types "$bucket_mime" \
      --arg file_size_limit "${bucket_limit}" \
      '{
        id: $id,
        name: $name,
        public: $public,
        allowed_mime_types: $allowed_mime_types
      } + (if $file_size_limit == "" then {} else {file_size_limit: ($file_size_limit|tonumber)} end)'
    )"

    retry_cmd 5 remote_http \
      -X POST "${REMOTE_URL}/storage/v1/bucket" \
      -H "apikey: ${REMOTE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${REMOTE_SERVICE_ROLE_KEY}" \
      -H "Content-Type: application/json" \
      -d "$payload" >/dev/null
  done < <(jq -r '.[] | @base64' "$local_buckets_json")
}

download_local_and_upload_remote() {
  local bucket_id="$1"
  local object_name="$2"
  local content_type="$3"
  local encoded_path tmp_file

  encoded_path="$(urlencode_path "$object_name")"
  tmp_file="${TMP_DIR}/obj.bin"

  retry_cmd 5 curl -sS --fail --show-error --connect-timeout 10 --max-time 180 \
    -H "apikey: ${LOCAL_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${LOCAL_SERVICE_ROLE_KEY}" \
    "${LOCAL_URL}/storage/v1/object/${bucket_id}/${encoded_path}" > "$tmp_file"

  retry_cmd 5 remote_upload_file \
    -X POST "${REMOTE_URL}/storage/v1/object/${bucket_id}/${encoded_path}" \
    -H "apikey: ${REMOTE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${REMOTE_SERVICE_ROLE_KEY}" \
    -H "x-upsert: true" \
    -H "Content-Type: ${content_type}" \
    --data-binary @"$tmp_file" >/dev/null
}

collect_object_keys() {
  local base_url="$1"
  local key="$2"
  local bucket_id="$3"
  local target_file="$4"
  local use_remote="$5"
  local seen_file queue q_idx prefix offset list_file body count obj_name full_obj_name folder_name next_prefix

  : > "$target_file"
  seen_file="${TMP_DIR}/seen_${use_remote}_${bucket_id}.txt"
  : > "$seen_file"
  queue=("")
  q_idx=0

  while (( q_idx < ${#queue[@]} )); do
    prefix="${queue[$q_idx]}"
    q_idx=$((q_idx + 1))
    [[ -z "$prefix" ]] && prefix=""
    if grep -Fxq "$prefix" "$seen_file"; then
      continue
    fi
    echo "$prefix" >> "$seen_file"

    offset=0
    while true; do
      list_file="${TMP_DIR}/list_${use_remote}_${bucket_id}_$(echo "$prefix" | tr '/ ' '__')_${offset}.json"
      body="$(jq -n --arg p "$prefix" --argjson offset "$offset" '{prefix:$p, limit:1000, offset:$offset, sortBy:{column:"name", order:"asc"}}')"

      if [[ "$use_remote" == "remote" ]]; then
        retry_cmd 5 remote_http \
          -X POST "${base_url}/storage/v1/object/list/${bucket_id}" \
          -H "apikey: ${key}" \
          -H "Authorization: Bearer ${key}" \
          -H "Content-Type: application/json" \
          -d "$body" > "$list_file"
      else
        retry_cmd 5 curl -sS --fail --show-error --connect-timeout 10 --max-time 90 \
          -X POST "${base_url}/storage/v1/object/list/${bucket_id}" \
          -H "apikey: ${key}" \
          -H "Authorization: Bearer ${key}" \
          -H "Content-Type: application/json" \
          -d "$body" > "$list_file"
      fi

      count="$(jq 'length' "$list_file")"
      [[ "$count" -eq 0 ]] && break

      while IFS= read -r obj_name; do
        [[ -z "$obj_name" || "$obj_name" == "null" ]] && continue
        full_obj_name="$obj_name"
        if [[ -n "$prefix" && "$obj_name" != "$prefix"* ]]; then
          full_obj_name="${prefix}${obj_name}"
        fi
        [[ "$full_obj_name" == ".emptyFolderPlaceholder" || "$full_obj_name" == */".emptyFolderPlaceholder" ]] && continue
        printf "%s\n" "$full_obj_name" >> "$target_file"
      done < <(jq -r '.[] | select(.id != null and .name != null) | .name' "$list_file")

      while IFS= read -r folder_name; do
        [[ -z "$folder_name" || "$folder_name" == "null" ]] && continue
        next_prefix="${folder_name}/"
        if [[ -n "$prefix" && "$folder_name" != "$prefix"* ]]; then
          next_prefix="${prefix}${folder_name}/"
        fi
        if ! grep -Fxq "$next_prefix" "$seen_file"; then
          queue+=("$next_prefix")
        fi
      done < <(jq -r '.[] | select(.id == null and .name != null) | .name' "$list_file")

      offset=$((offset + 1000))
    done
  done

  sort -u "$target_file" -o "$target_file"
}

sync_objects_local_to_remote() {
  local local_buckets_json remote_buckets_json
  local_buckets_json="${TMP_DIR}/local_buckets.json"
  remote_buckets_json="${TMP_DIR}/remote_buckets.json"

  if [[ ! -f "$local_buckets_json" || ! -f "$remote_buckets_json" ]]; then
    echo "Bucket metadata missing before object sync." >&2
    exit 1
  fi

  echo "Syncing storage binaries local -> remote..."
  local total=0
  while IFS= read -r bucket_b64; do
    local bucket_json bucket_id local_keys remote_keys remote_only local_only object_name content_type encoded_path head_headers
    bucket_json="$(echo "$bucket_b64" | base64 --decode)"
    bucket_id="$(echo "$bucket_json" | jq -r '.id')"

    local_keys="${TMP_DIR}/local_${bucket_id}_keys.txt"
    remote_keys="${TMP_DIR}/remote_${bucket_id}_keys.txt"
    remote_only="${TMP_DIR}/remote_only_${bucket_id}.txt"
    local_only="${TMP_DIR}/local_only_${bucket_id}.txt"

    collect_object_keys "$LOCAL_URL" "$LOCAL_SERVICE_ROLE_KEY" "$bucket_id" "$local_keys" "local"
    collect_object_keys "$REMOTE_URL" "$REMOTE_SERVICE_ROLE_KEY" "$bucket_id" "$remote_keys" "remote"

    comm -23 "$remote_keys" "$local_keys" > "$remote_only" || true
    if [[ -s "$remote_only" ]]; then
      echo "Deleting remote objects missing locally for bucket ${bucket_id}..."
      while IFS= read -r object_name; do
        [[ -z "$object_name" ]] && continue
        encoded_path="$(urlencode_path "$object_name")"
        retry_cmd 5 remote_http \
          -X DELETE "${REMOTE_URL}/storage/v1/object/${bucket_id}/${encoded_path}" \
          -H "apikey: ${REMOTE_SERVICE_ROLE_KEY}" \
          -H "Authorization: Bearer ${REMOTE_SERVICE_ROLE_KEY}" >/dev/null
      done < "$remote_only"
    fi

    comm -23 "$local_keys" "$remote_keys" > "$local_only" || true
    while IFS= read -r object_name; do
      [[ -z "$object_name" ]] && continue
      encoded_path="$(urlencode_path "$object_name")"
      head_headers="${TMP_DIR}/head_${bucket_id}.txt"
      retry_cmd 5 curl -sS --fail --show-error --connect-timeout 10 --max-time 90 \
        -D "$head_headers" -o /dev/null \
        -H "apikey: ${LOCAL_SERVICE_ROLE_KEY}" \
        -H "Authorization: Bearer ${LOCAL_SERVICE_ROLE_KEY}" \
        "${LOCAL_URL}/storage/v1/object/${bucket_id}/${encoded_path}"
      content_type="$(awk 'BEGIN{IGNORECASE=1} /^Content-Type:/ {sub(/\r$/, "", $2); print $2; exit}' "$head_headers")"
      if [[ -z "$content_type" ]]; then
        content_type="application/octet-stream"
      fi
      download_local_and_upload_remote "$bucket_id" "$object_name" "$content_type"
      total=$((total + 1))
      echo "Uploaded: ${bucket_id}/${object_name} [${content_type}]"
    done < "$local_only"

    while IFS= read -r object_name; do
      [[ -z "$object_name" ]] && continue
      encoded_path="$(urlencode_path "$object_name")"
      head_headers="${TMP_DIR}/head_${bucket_id}.txt"
      retry_cmd 5 curl -sS --fail --show-error --connect-timeout 10 --max-time 90 \
        -D "$head_headers" -o /dev/null \
        -H "apikey: ${LOCAL_SERVICE_ROLE_KEY}" \
        -H "Authorization: Bearer ${LOCAL_SERVICE_ROLE_KEY}" \
        "${LOCAL_URL}/storage/v1/object/${bucket_id}/${encoded_path}"
      content_type="$(awk 'BEGIN{IGNORECASE=1} /^Content-Type:/ {sub(/\r$/, "", $2); print $2; exit}' "$head_headers")"
      if [[ -z "$content_type" ]]; then
        content_type="application/octet-stream"
      fi
      download_local_and_upload_remote "$bucket_id" "$object_name" "$content_type"
      total=$((total + 1))
      echo "Upserted: ${bucket_id}/${object_name} [${content_type}]"
    done < "$local_keys"
  done < <(jq -r '.[] | @base64' "$local_buckets_json")

  echo "Done. Synced storage binaries from local to remote project ${REF}. Uploaded/upserted ${total} object(s)."
}

ensure_remote_buckets
sync_objects_local_to_remote
