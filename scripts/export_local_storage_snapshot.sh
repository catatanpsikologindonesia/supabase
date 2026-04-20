#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SNAPSHOT_DIR="$ROOT_DIR/snapshot/storage"
OBJECTS_DIR="$SNAPSHOT_DIR/objects"
MANIFEST_FILE="$SNAPSHOT_DIR/manifest.tsv"
LOCAL_URL="${LOCAL_SUPABASE_URL:-http://127.0.0.1:55321}"
LOCAL_SERVICE_ROLE_KEY="${LOCAL_SERVICE_ROLE_KEY:-$(supabase status -o env | awk -F= '/^SERVICE_ROLE_KEY=/{gsub(/"/,"",$2); print $2}') }"

if [[ -z "$LOCAL_SERVICE_ROLE_KEY" ]]; then
  echo "Failed to resolve LOCAL_SERVICE_ROLE_KEY from supabase status" >&2
  exit 1
fi

mkdir -p "$OBJECTS_DIR"
find "$OBJECTS_DIR" -mindepth 1 -delete 2>/dev/null || true
: > "$MANIFEST_FILE"

urlencode_path() {
  python3 - <<'PY' "$1"
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe='/'))
PY
}

collect_object_keys() {
  local bucket_id="$1"
  local target_file="$2"
  local seen_file queue q_idx prefix offset list_file body count obj_name full_obj_name folder_name next_prefix

  : > "$target_file"
  seen_file="$(mktemp -t cp_storage_seen.XXXXXX)"
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
      list_file="$(mktemp -t cp_storage_list.XXXXXX.json)"
      body="$(jq -n --arg p "$prefix" --argjson offset "$offset" '{prefix:$p, limit:1000, offset:$offset, sortBy:{column:"name", order:"asc"}}')"

      curl -sS --fail --show-error --connect-timeout 10 --max-time 90 \
        -X POST "${LOCAL_URL}/storage/v1/object/list/${bucket_id}" \
        -H "apikey: ${LOCAL_SERVICE_ROLE_KEY}" \
        -H "Authorization: Bearer ${LOCAL_SERVICE_ROLE_KEY}" \
        -H "Content-Type: application/json" \
        -d "$body" > "$list_file"

      count="$(jq 'length' "$list_file")"
      [[ "$count" -eq 0 ]] && rm -f "$list_file" && break

      while IFS= read -r obj_name; do
        [[ -z "$obj_name" || "$obj_name" == "null" ]] && continue
        full_obj_name="$obj_name"
        if [[ -n "$prefix" && "$obj_name" != "$prefix"* ]]; then
          full_obj_name="${prefix}${obj_name}"
        fi
        [[ "$full_obj_name" == ".emptyFolderPlaceholder" || "$full_obj_name" == */".emptyFolderPlaceholder" ]] && continue
        [[ "$full_obj_name" == ".keep" || "$full_obj_name" == */".keep" ]] && continue
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

      rm -f "$list_file"
      offset=$((offset + 1000))
    done
  done

  sort -u "$target_file" -o "$target_file"
  rm -f "$seen_file"
}

buckets_json="$(mktemp -t cp_storage_buckets.XXXXXX.json)"
curl -sS --fail --show-error --connect-timeout 10 --max-time 90 \
  -H "apikey: ${LOCAL_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${LOCAL_SERVICE_ROLE_KEY}" \
  "${LOCAL_URL}/storage/v1/bucket" > "$buckets_json"

while IFS= read -r bucket_id; do
  [[ -z "$bucket_id" || "$bucket_id" == "null" ]] && continue
  keys_file="$(mktemp -t cp_storage_keys.XXXXXX)"
  collect_object_keys "$bucket_id" "$keys_file"

  while IFS= read -r object_name; do
    [[ -z "$object_name" ]] && continue
    encoded_path="$(urlencode_path "$object_name")"
    out_file="$OBJECTS_DIR/$bucket_id/$object_name"
    mkdir -p "$(dirname "$out_file")"

    headers_file="$(mktemp -t cp_storage_head.XXXXXX)"
    curl -sS --fail --show-error --connect-timeout 10 --max-time 180 \
      -D "$headers_file" \
      -o "$out_file" \
      -H "apikey: ${LOCAL_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${LOCAL_SERVICE_ROLE_KEY}" \
      "${LOCAL_URL}/storage/v1/object/${bucket_id}/${encoded_path}"

    content_type="$(awk 'BEGIN{IGNORECASE=1} /^Content-Type:/ {gsub(/\r/, "", $2); print $2; exit}' "$headers_file")"
    [[ -z "$content_type" ]] && content_type="application/octet-stream"
    printf "%s\t%s\t%s\n" "$bucket_id" "$object_name" "$content_type" >> "$MANIFEST_FILE"
    rm -f "$headers_file"
  done < "$keys_file"

  rm -f "$keys_file"
done < <(jq -r '.[].id' "$buckets_json")

rm -f "$buckets_json"
echo "Exported local storage snapshot to ${OBJECTS_DIR}"
