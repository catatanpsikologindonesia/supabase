#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKDIR"

mkdir -p snapshot/verification

if [[ ! -f snapshot/verification/remote_table_row_estimates.txt ]]; then
  echo "Missing remote_table_row_estimates.txt. Run export_remote_database_snapshot.sh first." >&2
  exit 1
fi

if [[ ! -f snapshot/verification/local_table_row_estimates.txt ]]; then
  echo "Missing local_table_row_estimates.txt. Run restore_snapshot_to_local.sh first." >&2
  exit 1
fi

sort snapshot/verification/remote_table_row_estimates.txt > snapshot/verification/remote_table_row_estimates.sorted.txt
sort snapshot/verification/local_table_row_estimates.txt > snapshot/verification/local_table_row_estimates.sorted.txt

if diff -u snapshot/verification/remote_table_row_estimates.sorted.txt snapshot/verification/local_table_row_estimates.sorted.txt > snapshot/verification/row_estimate_diff.txt; then
  echo "Row estimate diff: clean (no differences)."
else
  echo "Row estimate diff: differences found. See snapshot/verification/row_estimate_diff.txt"
fi

shasum -a 256 snapshot/database/*.sql > snapshot/verification/database_sql_sha256.txt

echo "Verification artifacts updated under snapshot/verification/."
