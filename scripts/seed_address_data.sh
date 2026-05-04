#!/usr/bin/env bash

set -euo pipefail

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

DB_URL="${SUPABASE_DB_URL:-postgresql://postgres:postgres@localhost:55322/postgres}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(mktemp -d)"
trap "rm -rf '$WORK_DIR'" EXIT

WILAYAH_REF="${WILAYAH_REF:-master}"
KODEPOS_REF="${KODEPOS_REF:-main}"
WILAYAH_URL="https://raw.githubusercontent.com/cahyadsn/wilayah/${WILAYAH_REF}/db/wilayah.sql"
KODEPOS_URL="https://raw.githubusercontent.com/cahyadsn/wilayah_kodepos/${KODEPOS_REF}/db/wilayah_kodepos.sql"

read -r -d '' PARSE_WILAYAH_PERL <<'EOF' || true
next unless /^\('([^']+)',\s*'((?:[^']|'')*)'\),?\r?$/;
my ($kode, $nama) = ($1, $2);
$nama =~ s/''/'/g;
print join("\t", $kode, $nama), "\n";
EOF

read -r -d '' PARSE_KODEPOS_PERL <<'EOF' || true
next unless /^\('([^']+)',\s*'([0-9]{5})'\),?\r?$/;
my ($kode, $kodepos) = ($1, $2);
print join("\t", $kode, $kodepos), "\n";
EOF

echo "[1/4] Downloading source SQL files..."
curl -fsSL "$WILAYAH_URL" -o "$WORK_DIR/wilayah_raw.sql"
curl -fsSL "$KODEPOS_URL" -o "$WORK_DIR/kodepos_raw.sql"

echo "[2/4] Parsing tuple rows from source SQL dumps..."
perl -ne "${PARSE_WILAYAH_PERL}" "$WORK_DIR/wilayah_raw.sql" > "$WORK_DIR/wilayah_rows.tsv"
perl -ne "${PARSE_KODEPOS_PERL}" "$WORK_DIR/kodepos_raw.sql" > "$WORK_DIR/kodepos_rows.tsv"

echo "[3/4] Verifying DB connection..."
psql "$DB_URL" -c "SELECT 1 AS ping;" > /dev/null

echo "[4/4] Running seed in single psql session..."
psql "$DB_URL" -v ON_ERROR_STOP=1 <<SQL
CREATE TEMP TABLE _staging_wilayah (kode VARCHAR(13) NOT NULL, nama VARCHAR(100) NOT NULL);
CREATE TEMP TABLE _staging_kodepos (kode VARCHAR(13) NOT NULL, kodepos VARCHAR(5));
\copy _staging_wilayah FROM '$WORK_DIR/wilayah_rows.tsv' WITH (FORMAT csv, DELIMITER E'\t')
\copy _staging_kodepos FROM '$WORK_DIR/kodepos_rows.tsv' WITH (FORMAT csv, DELIMITER E'\t')
$(cat "$SCRIPT_DIR/seed_address_upsert.sql")
SQL

echo ""
echo "Seed complete."
