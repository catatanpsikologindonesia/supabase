#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

error_count=0

fail() {
  local message="$1"
  echo "ERROR: ${message}" >&2
  error_count=$((error_count + 1))
}

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "Missing file: $path"
}

assert_dir() {
  local path="$1"
  [[ -d "$path" ]] || fail "Missing directory: $path"
}

assert_gitignore_line() {
  local line="$1"
  grep -Fqx "$line" .gitignore || fail "Missing .gitignore entry: $line"
}

assert_file "Makefile"
assert_file "README.md"
assert_file "SECURITY.md"
assert_file "REDACTION_POLICY.md"
assert_file ".gitignore"
assert_file "supabase/config.toml"

assert_dir "scripts"
assert_dir "snapshot"
assert_dir "snapshot/config"
assert_dir "snapshot/database"
assert_dir "snapshot/storage"
assert_dir "snapshot/verification"
assert_dir "knowledge"

assert_file "snapshot/verification/config_export_status.txt"
assert_file "snapshot/verification/storage_export_status.txt"
assert_file "snapshot/verification/exact_count_compare.txt"
assert_file "snapshot/verification/exact_count_mismatch_total.txt"

for script_path in scripts/*.sh; do
  [[ -f "$script_path" ]] || fail "No shell scripts found in scripts/"
  [[ -x "$script_path" ]] || fail "Script is not executable: $script_path"
  first_line="$(head -n 1 "$script_path")"
  [[ "$first_line" == "#!/usr/bin/env bash" ]] || fail "Invalid shebang in $script_path"
  grep -Fqx "set -euo pipefail" "$script_path" || fail "Missing strict mode in $script_path"
done

assert_gitignore_line "supabase/.temp/"
assert_gitignore_line "supabase/.branches/_current_branch"
assert_gitignore_line "snapshot/verification/local_restore.log"
assert_gitignore_line "snapshot/verification/sync_all_verbose_*.log"
assert_gitignore_line "snapshot/functions/functions_download.log"
assert_gitignore_line "snapshot/config/*.err"

if [[ "$error_count" -gt 0 ]]; then
  echo "Repository validation failed with ${error_count} error(s)." >&2
  exit 1
fi

echo "Repository validation passed."
