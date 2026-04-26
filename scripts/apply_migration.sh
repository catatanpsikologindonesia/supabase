#!/usr/bin/env bash
# scripts/apply_migration.sh (Catatan Psikolog Version)
# Purpose: Fully automate Supabase migrations, Knowledge mirroring, Squashing, and Frontend Sync.

set -euo pipefail

# Ensure Homebrew libpq is in PATH for pg_dump
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <migration_name> <sql_content>"
    exit 1
fi

MIGRATION_NAME=$1
SQL_CONTENT=$2
TIMESTAMP=$(date +%Y%m%d%H%M%S)
FILENAME="supabase/migrations/${TIMESTAMP}_${MIGRATION_NAME}.sql"
KNOWLEDGE_DIR="knowledge/supabase_migrations"
KNOWLEDGE_FILE="${KNOWLEDGE_DIR}/${TIMESTAMP}_${MIGRATION_NAME}.md"
SNAPSHOT_DB_DIR="snapshot/database"

# --- HELPER: Global Discovery ---
find_portal_path() {
    local target_name=$1
    local found_path=$(find "$HOME" -maxdepth 5 -name "$target_name" -type d -not -path "*/Library/*" -not -path "*/.*" -print -quit 2>/dev/null)
    
    if [ -n "$found_path" ]; then
        echo "$found_path"
        return 0
    fi
    return 1
}

# --- HELPER: Ensure Pre-requisites ---
ensure_environment_ready() {
    echo "==> [0/9] Checking environment readiness..."
    
    if ! docker info > /dev/null 2>&1; then
        echo "    -> Docker is not running. Attempting to start Docker daemon..."
        if command -v colima >/dev/null 2>&1; then
            echo "    -> Colima detected. Starting Colima..."
            colima start
        elif command -v open >/dev/null 2>&1; then
            echo "    -> Starting Docker Desktop..."
            open -a Docker || true
        else
            echo "    [!] ERROR: Cannot automatically start Docker on this OS. Please start Docker manually."
            exit 1
        fi
        
        echo -n "    -> Waiting for Docker daemon "
        local retries=0
        while ! docker info > /dev/null 2>&1; do
                sleep 3
                retries=$((retries + 1))
                if [ "$retries" -ge 20 ]; then
                    echo ""
                    echo "    [!] ERROR: Docker failed to start after 60s. Please start it manually."
                    exit 1
                fi
                echo -n "."
            done
            echo " Ready!"
    else
        echo "    -> Docker is running."
    fi

    if ! supabase status > /dev/null 2>&1; then
        echo "    -> Local Supabase stack is not running. Starting it now..."
        supabase start
    else
        echo "    -> Supabase stack is running."
    fi
}

ensure_environment_ready

# 1. Create Migration File
echo "==> [1/8] Creating migration file: $FILENAME"
echo "$SQL_CONTENT" > "$FILENAME"

# 2. Create Knowledge Mirror
echo "==> [2/8] Mirroring to knowledge: $KNOWLEDGE_FILE"
mkdir -p "$KNOWLEDGE_DIR"
cat <<EOF > "$KNOWLEDGE_FILE"
# Migration: ${MIGRATION_NAME}

- **Timestamp**: ${TIMESTAMP}
- **Applied At**: $(date "+%Y-%m-%d %H:%M:%S")

## Description
Auto-generated migration for database structural changes.

## SQL Content
\`\`\`sql
${SQL_CONTENT}
\`\`\`
EOF

# 3. Apply to Database
echo "==> [3/8] Applying migration to local database..."
if supabase migration up; then
    echo "==> Migration applied successfully."
    
    # 4. Update Status Log
    STATUS_FILE="knowledge/operations/MIGRATION_STATUS.md"
    mkdir -p "$(dirname "$STATUS_FILE")"
    echo "- $(date +%Y-%m-%d) $TIMESTAMP: Applied $MIGRATION_NAME" >> "$STATUS_FILE"

    # 5. AUTO-SQUASH (The Cleanup)
    echo "==> [5/8] Tidying up stale migrations (Squashing)..."
    if supabase migration squash; then
        echo "==> Squashing complete. Folder is now lean."
        
        # 6. DELETE Stale Knowledge Files
        echo "==> [6/8] Deleting stale knowledge files..."
        find "$KNOWLEDGE_DIR" -maxdepth 1 -name "*.md" ! -name "$(basename "$KNOWLEDGE_FILE")" -delete
    else
        echo "==> WARNING: Squash failed. Skipping cleanup."
    fi

    # 7. SCHEMA HEARTBEAT (Makes sync visible in Git even if no schema changes)
    echo "==> [7/10] Updating schema heartbeat comment..."
    HEARTBEAT_SQL="COMMENT ON SCHEMA public IS 'Last Synchronized: $(date "+%Y-%m-%d %H:%M:%S") | Source: $MIGRATION_NAME';"
    psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -q -c "$HEARTBEAT_SQL"

    # 8. Refresh local source-of-truth snapshot
    echo "==> [8/10] Refreshing local database snapshot artifacts..."
    mkdir -p "$SNAPSHOT_DB_DIR"
    supabase db dump --local --schema public --file "$SNAPSHOT_DB_DIR/schema_snapshot.sql"
    PGPASSWORD="postgres" pg_dump -Fc --no-owner --no-privileges \
      -h 127.0.0.1 -p 54322 -U postgres -d postgres \
      -f "$SNAPSHOT_DB_DIR/db_full_snapshot.dump"

    # 9. FRONTEND SYNC (Global Discovery Bridge)
    echo "==> [9/10] Searching and Syncing frontend portals..."
    PORTAL_NAMES=(
        "catatan-psikolog-user-portal"
        "catatan-psikolog-admin-portal"
        "catatan-psikolog-landing-page"
    )

    for name in "${PORTAL_NAMES[@]}"; do
        echo "    -> Searching for $name..."
        portal_path=$(find_portal_path "$name")
        if [ -n "$portal_path" ]; then
            echo "       Found at: $portal_path"
            (cd "$portal_path" && make sync-schema > /dev/null 2>&1) || echo "    [!] Warning: sync-schema failed in $name"
        else
            echo "    [!] Skip: Portal '$name' not found."
        fi
    done
    echo "==> [10/10] All systems synchronized."

else
    echo "==> ERROR: Failed to apply migration. Please check your SQL syntax."
    exit 1
fi
