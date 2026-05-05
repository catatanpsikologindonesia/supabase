#!/usr/bin/env bash

set -euo pipefail

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

DB_URL="${SUPABASE_DB_URL:-postgresql://postgres:postgres@localhost:55322/postgres}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[1/2] Verifying DB connection..."
psql "$DB_URL" -c "SELECT 1 AS ping;" > /dev/null

echo "[2/2] Applying reference data seed upserts..."
psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/seed_reference_upsert.sql"

echo ""
echo "Reference seed complete."
