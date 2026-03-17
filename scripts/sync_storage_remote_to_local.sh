#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "SUPABASE_ACCESS_TOKEN is required" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

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

TMP_DIR="${ROOT_DIR}/.tmp_storage_sync"
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

resolve_remote_service_role_key() {
  local out
  out="$(retry_cmd 5 remote_http \
    -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
    "https://api.supabase.com/v1/projects/${REF}/api-keys?reveal=true")" || return 1

  echo "$out" | jq -r '.[] | select(.id=="service_role") | .api_key'
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

REMOTE_SERVICE_ROLE_KEY="${REMOTE_SERVICE_ROLE_KEY:-}"
if [[ -z "$REMOTE_SERVICE_ROLE_KEY" ]]; then
  REMOTE_SERVICE_ROLE_KEY="$(resolve_remote_service_role_key || true)"
fi
if [[ -z "$REMOTE_SERVICE_ROLE_KEY" || "$REMOTE_SERVICE_ROLE_KEY" == "null" ]]; then
  echo "Failed to resolve REMOTE_SERVICE_ROLE_KEY from project ${REF}" >&2
  exit 1
fi

LOCAL_SERVICE_ROLE_KEY="${LOCAL_SERVICE_ROLE_KEY:-$(supabase status -o env | awk -F= '/^SERVICE_ROLE_KEY=/{gsub(/"/,"",$2); print $2}') }"
if [[ -z "$LOCAL_SERVICE_ROLE_KEY" ]]; then
  echo "Failed to resolve LOCAL_SERVICE_ROLE_KEY from supabase status" >&2
  exit 1
fi

echo "Fetching remote buckets..."
REMOTE_BUCKETS_JSON="${TMP_DIR}/remote_buckets.json"
json_get_remote "${REMOTE_URL}/storage/v1/bucket" "$REMOTE_SERVICE_ROLE_KEY" "$REMOTE_BUCKETS_JSON"

LOCAL_BUCKETS_JSON="${TMP_DIR}/local_buckets.json"
json_get_local "${LOCAL_URL}/storage/v1/bucket" "$LOCAL_SERVICE_ROLE_KEY" "$LOCAL_BUCKETS_JSON"

echo "Ensuring buckets exist locally..."
while IFS= read -r bucket_b64; do
  bucket_json="$(echo "$bucket_b64" | base64 --decode)"
  bucket_id="$(echo "$bucket_json" | jq -r '.id')"
  bucket_name="$(echo "$bucket_json" | jq -r '.name')"
  bucket_public="$(echo "$bucket_json" | jq -r '.public // false')"
  bucket_limit="$(echo "$bucket_json" | jq -r '.file_size_limit // empty')"
  bucket_mime="$(echo "$bucket_json" | jq -c '.allowed_mime_types // []')"

  if jq -e --arg id "$bucket_id" '.[] | select(.id==$id)' "$LOCAL_BUCKETS_JSON" >/dev/null; then
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

  retry_cmd 5 curl -sS --fail --show-error --connect-timeout 10 --max-time 90 \
    -X POST "${LOCAL_URL}/storage/v1/bucket" \
    -H "apikey: ${LOCAL_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${LOCAL_SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json" \
    -d "$payload" >/dev/null
done < <(jq -r '.[] | @base64' "$REMOTE_BUCKETS_JSON")

download_upload_object() {
  local bucket_id="$1"
  local object_name="$2"
  local content_type="$3"
  local encoded_path
  local tmp_file

  encoded_path="$(python3 - <<'PY' "$object_name"
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe='/'))
PY
)"

  tmp_file="${TMP_DIR}/obj.bin"

  retry_cmd 5 remote_http \
    -H "apikey: ${REMOTE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${REMOTE_SERVICE_ROLE_KEY}" \
    "${REMOTE_URL}/storage/v1/object/${bucket_id}/${encoded_path}" > "$tmp_file"

  retry_cmd 5 curl -sS --fail --show-error --connect-timeout 10 --max-time 180 \
    -X POST "${LOCAL_URL}/storage/v1/object/${bucket_id}/${encoded_path}" \
    -H "apikey: ${LOCAL_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${LOCAL_SERVICE_ROLE_KEY}" \
    -H "x-upsert: true" \
    -H "Content-Type: ${content_type}" \
    --data-binary @"$tmp_file" >/dev/null
}

guess_content_type() {
  local object_name="$1"
  local object_name_lc
  object_name_lc="$(printf '%s' "$object_name" | tr '[:upper:]' '[:lower:]')"
  case "$object_name_lc" in
    *.png) echo "image/png" ;;
    *.jpg|*.jpeg) echo "image/jpeg" ;;
    *.webp) echo "image/webp" ;;
    *.gif) echo "image/gif" ;;
    *.svg) echo "image/svg+xml" ;;
    *.pdf) echo "application/pdf" ;;
    *.json) echo "application/json" ;;
    *.txt) echo "text/plain" ;;
    *) echo "application/octet-stream" ;;
  esac
}

echo "Syncing objects remote -> local..."
total=0
while IFS= read -r bucket_b64; do
  bucket_json="$(echo "$bucket_b64" | base64 --decode)"
  bucket_id="$(echo "$bucket_json" | jq -r '.id')"

  seen_file="${TMP_DIR}/seen_${bucket_id}.txt"
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
      list_file="${TMP_DIR}/list_${bucket_id}_$(echo "$prefix" | tr '/ ' '__')_${offset}.json"
      body="$(jq -n --arg p "$prefix" --argjson offset "$offset" '{prefix:$p, limit:1000, offset:$offset, sortBy:{column:"name", order:"asc"}}')"

      retry_cmd 5 remote_http \
        -X POST "${REMOTE_URL}/storage/v1/object/list/${bucket_id}" \
        -H "apikey: ${REMOTE_SERVICE_ROLE_KEY}" \
        -H "Authorization: Bearer ${REMOTE_SERVICE_ROLE_KEY}" \
        -H "Content-Type: application/json" \
        -d "$body" > "$list_file"

      count="$(jq 'length' "$list_file")"
      [[ "$count" -eq 0 ]] && break

      while IFS= read -r obj_b64; do
        [[ -z "$obj_b64" ]] && continue
        obj_json="$(echo "$obj_b64" | base64 --decode)"
        obj_name="$(echo "$obj_json" | jq -r '.name')"
        obj_mime="$(echo "$obj_json" | jq -r '.metadata.mimetype // empty')"
        [[ -z "$obj_name" || "$obj_name" == "null" ]] && continue
        full_obj_name="$obj_name"
        if [[ -n "$prefix" && "$obj_name" != "$prefix"* ]]; then
          full_obj_name="${prefix}${obj_name}"
        fi
        [[ "$full_obj_name" == ".emptyFolderPlaceholder" || "$full_obj_name" == */".emptyFolderPlaceholder" ]] && continue
        content_type="$obj_mime"
        if [[ -z "$content_type" || "$content_type" == "null" || "$content_type" == "application/octet-stream" ]]; then
          content_type="$(guess_content_type "$full_obj_name")"
        fi
        download_upload_object "$bucket_id" "$full_obj_name" "$content_type"
        total=$((total + 1))
        echo "Synced: ${bucket_id}/${full_obj_name} [${content_type}]"
      done < <(jq -r '.[] | select(.id != null and .name != null) | @base64' "$list_file")

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
done < <(jq -r '.[] | @base64' "$REMOTE_BUCKETS_JSON")

echo "Done. Synced ${total} storage object(s) from remote project ${REF} to local."
