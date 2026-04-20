#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SNAPSHOT_DIR="$ROOT_DIR/snapshot/storage"
OBJECTS_DIR="$SNAPSHOT_DIR/objects"
MANIFEST_FILE="$SNAPSHOT_DIR/manifest.tsv"
LOCAL_URL="${LOCAL_SUPABASE_URL:-http://127.0.0.1:55321}"
LOCAL_SERVICE_ROLE_KEY="${LOCAL_SERVICE_ROLE_KEY:-$(supabase status -o env | awk -F= '/^SERVICE_ROLE_KEY=/{gsub(/"/,"",$2); print $2}') }"

if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "No local storage manifest found at ${MANIFEST_FILE}. Skipping restore."
  exit 0
fi

if [[ -z "$LOCAL_SERVICE_ROLE_KEY" ]]; then
  echo "Failed to resolve LOCAL_SERVICE_ROLE_KEY from supabase status" >&2
  exit 1
fi

while IFS=$'\t' read -r bucket_id object_name content_type; do
  [[ -z "$bucket_id" || -z "$object_name" ]] && continue
  file_path="$OBJECTS_DIR/$bucket_id/$object_name"
  if [[ ! -f "$file_path" ]]; then
    echo "Missing local storage artifact: ${file_path}" >&2
    exit 1
  fi

  encoded_path="$(python3 - <<'PY' "$object_name"
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe='/'))
PY
)"

  curl -sS --fail --show-error --connect-timeout 10 --max-time 180 \
    -X POST "${LOCAL_URL}/storage/v1/object/${bucket_id}/${encoded_path}" \
    -H "apikey: ${LOCAL_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${LOCAL_SERVICE_ROLE_KEY}" \
    -H "x-upsert: true" \
    -H "Content-Type: ${content_type:-application/octet-stream}" \
    --data-binary @"$file_path" >/dev/null
done < "$MANIFEST_FILE"

echo "Restored local storage snapshot from ${OBJECTS_DIR}"
