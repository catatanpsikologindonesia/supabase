#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mode="${1:---all}"
base_sha="${2:-}"
head_sha="${3:-HEAD}"

FILENAME_BANNED='(panduan|keamanan|ringkasan|riwayat|perubahan|pengujian|kebijakan|manajemen|pekerjaan|pernikahan|alamat|kecamatan|kelurahan|provinsi|kabupaten|kota)'
CONTENT_BANNED='\b(yang|untuk|dengan|tidak|harus|wajib|setelah|sebelum|jika|bila|agar|perubahan|jalankan|jangan|kebijakan|panduan|keamanan|ringkasan|riwayat|fitur|pengujian|manajemen|lokal)\b'

# Branding exception: catatan psikolog variants are allowed and must not be renamed.
BRANDING_ALLOW='(catatan[_-]?psikolog|catatanpsikolog)'

collect_files() {
  case "$mode" in
    --all)
      git ls-files
      ;;
    --changed)
      if [[ -z "$base_sha" ]]; then
        echo "Missing base SHA for --changed mode" >&2
        exit 2
      fi
      if ! git cat-file -e "${base_sha}^{commit}" >/dev/null 2>&1; then
        git ls-files
        return
      fi
      git diff --name-only --diff-filter=ACMR "$base_sha" "$head_sha"
      ;;
    *)
      echo "Usage: $0 [--all | --changed <base_sha> <head_sha>]" >&2
      exit 2
      ;;
  esac
}

is_ignored_path() {
  case "$1" in
    .git/*|node_modules/*|dist/*|build/*|.dart_tool/*|snapshot/*|.tmp_*/*|coverage/*)
      return 0
      ;;
  esac
  return 1
}

violations=0

while IFS= read -r rel; do
  [[ -z "$rel" ]] && continue
  is_ignored_path "$rel" && continue
  [[ -e "$rel" ]] || continue

  base_name="$(basename "$rel")"
  base_lower="$(printf '%s' "$base_name" | tr '[:upper:]' '[:lower:]')"

  if [[ "$base_lower" =~ $FILENAME_BANNED ]] && ! [[ "$base_lower" =~ $BRANDING_ALLOW ]]; then
    echo "[filename] Non-English/Indonesian token detected: $rel"
    violations=1
  fi

  if [[ "$rel" == knowledge/*.md ]] && [[ -f "$rel" ]]; then
    if rg -n -i "$CONTENT_BANNED" "$rel" >/tmp/knowledge_lang_hits.$$ 2>/dev/null; then
      echo "[content] Non-English/Indonesian text detected in: $rel"
      head -n 5 /tmp/knowledge_lang_hits.$$
      violations=1
    fi
  fi
done < <(collect_files)

rm -f /tmp/knowledge_lang_hits.$$ >/dev/null 2>&1 || true

if [[ "$violations" -ne 0 ]]; then
  echo "Knowledge language guard failed." >&2
  exit 1
fi

echo "Knowledge language guard passed."
