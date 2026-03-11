#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKDIR"
PROJECT_REF="ixwaaziifteubxkxtdwj"

mkdir -p snapshot/config snapshot/storage snapshot/functions snapshot/verification

run_capture() {
  local name="$1"
  local outfile="$2"
  shift 2

  if "$@" >"$outfile" 2>"${outfile}.err"; then
    rm -f "${outfile}.err"
    echo "ok|${name}" >> snapshot/verification/config_export_status.txt
  else
    echo "failed|${name}|$(tr '\n' ' ' < "${outfile}.err")" >> snapshot/verification/config_export_status.txt
  fi
}

: > snapshot/verification/config_export_status.txt

run_capture "projects_list" "snapshot/config/projects_list.json" \
  supabase projects list -o json

run_capture "api_keys" "snapshot/config/api_keys.json" \
  supabase projects api-keys --project-ref "$PROJECT_REF" -o json

run_capture "secrets" "snapshot/config/secrets.json" \
  supabase secrets list --project-ref "$PROJECT_REF" -o json

run_capture "postgres_config" "snapshot/config/postgres_config.json" \
  supabase --experimental postgres-config get --project-ref "$PROJECT_REF" -o json

run_capture "network_restrictions" "snapshot/config/network_restrictions.json" \
  supabase --experimental network-restrictions get --project-ref "$PROJECT_REF" -o json

run_capture "ssl_enforcement" "snapshot/config/ssl_enforcement.json" \
  supabase --experimental ssl-enforcement get --project-ref "$PROJECT_REF" -o json

run_capture "network_bans" "snapshot/config/network_bans.json" \
  supabase --experimental network-bans get --project-ref "$PROJECT_REF" -o json

run_capture "domains" "snapshot/config/domains.json" \
  supabase domains get --project-ref "$PROJECT_REF" -o json

run_capture "vanity_subdomains" "snapshot/config/vanity_subdomains.json" \
  supabase --experimental vanity-subdomains get --project-ref "$PROJECT_REF" -o json

run_capture "sso_list" "snapshot/config/sso_list.json" \
  supabase sso list --project-ref "$PROJECT_REF" -o json

run_capture "functions_list" "snapshot/functions/functions_list.json" \
  supabase functions list --project-ref "$PROJECT_REF" -o json

run_capture "functions_download" "snapshot/functions/functions_download.log" \
  supabase functions download --project-ref "$PROJECT_REF" --use-api --workdir "$WORKDIR"

run_capture "storage_tree" "snapshot/storage/storage_tree.json" \
  supabase --experimental storage ls ss:/// -r --workdir "$WORKDIR" -o json

# Extract remote project row for convenience.
python3 - <<'PY'
import json
from pathlib import Path

root = Path('snapshot/config')
projects_path = root / 'projects_list.json'
out_path = root / 'project_ixwaaziifteubxkxtdwj.json'
if projects_path.exists():
    try:
        data = json.loads(projects_path.read_text() or '[]')
        row = next((item for item in data if item.get('id') == 'ixwaaziifteubxkxtdwj'), None)
        out_path.write_text(json.dumps(row, indent=2, sort_keys=True))
    except Exception as exc:
        out_path.write_text(json.dumps({'error': str(exc)}, indent=2))
PY

echo "Config export finished. See snapshot/verification/config_export_status.txt"
