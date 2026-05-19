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
    echo "==> [0/10] Checking environment readiness..."
    
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
                    echo "    [!] ERROR: Docker failed to start after 60s. Please start Docker manually."
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

# --- 1. PRE-MIGRATION DATA BACKUP ---
# Always backup local data before any destructive operation (squash -> db reset).
# Single file, overwritten each run — always the latest snapshot.
# Restore via: bash scripts/restore_local_db.sh
echo "==> [1/10] Creating pre-migration data backup..."
BACKUP_FILE="snapshot/database/db_full_snapshot.dump"
mkdir -p "$(dirname "$BACKUP_FILE")"
PROJECT_ID="$(awk -F= '/^project_id[[:space:]]*=/{gsub(/[ "\r]/, "", $2); print $2; exit}' supabase/config.toml)"
DB_CONTAINER="supabase_db_${PROJECT_ID}"
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    echo "    [!] ERROR: Cannot find Supabase DB container. Backup failed."
    exit 1
fi
echo "    -> Backing up from container: $DB_CONTAINER"
docker exec "$DB_CONTAINER" pg_dump -U postgres -d postgres \
    -Fc \
    -n auth -n public -n cron -n storage \
    --exclude-table-data='"auth"."schema_migrations"' \
    --exclude-table-data='"public"."supabase_migrations"' \
    -f /tmp/_apply_migration_backup.dump 2>/dev/null
docker cp "$DB_CONTAINER":/tmp/_apply_migration_backup.dump "$BACKUP_FILE" 2>/dev/null
docker exec "$DB_CONTAINER" rm -f /tmp/_apply_migration_backup.dump 2>/dev/null
if [[ ! -s "$BACKUP_FILE" ]]; then
    echo "    [!] ERROR: Backup file is empty or missing after copy: $BACKUP_FILE"
    echo "    -> Aborting before migration apply to avoid unsafe reset/squash flow."
    exit 1
fi
if ! pg_restore --list "$BACKUP_FILE" >/dev/null 2>&1; then
    echo "    [!] ERROR: Backup file failed pg_restore validation: $BACKUP_FILE"
    echo "    -> Aborting before migration apply to avoid unsafe reset/squash flow."
    exit 1
fi
echo "    -> Backup saved to: $BACKUP_FILE"
echo "    -> Backup verified. Restore via: bash scripts/restore_local_db.sh \"$BACKUP_FILE\""

# 2. Create Migration File
echo "==> [2/10] Creating migration file: $FILENAME"
echo "$SQL_CONTENT" > "$FILENAME"

# 3. Create Knowledge Mirror
echo "==> [3/10] Mirroring to knowledge: $KNOWLEDGE_FILE"
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

# 4. Repair any orphaned migration history entries
echo "==> [4/10] Repairing orphaned local migration history..."
supabase db dump --local --schema supabase_migrations --data-only 2>/dev/null \
  | rg -o "'[0-9]{14}'" \
  | tr -d "'" \
  | while read version; do
    if ! ls "supabase/migrations/${version}"_*.sql >/dev/null 2>&1; then
      echo "    -> Reverting orphaned version: ${version}"
      supabase migration repair --status reverted "${version}" --local 2>/dev/null || true
    fi
  done

# 5. Apply to Database
echo "==> [5/10] Applying migration to local database..."
if supabase db push --local <<< "y" 2>&1; then
    echo "==> Migration applied successfully."
    
    # 6. Update Status Log
    STATUS_FILE="knowledge/operations/MIGRATION_STATUS.md"
    mkdir -p "$(dirname "$STATUS_FILE")"
    echo "- $(date +%Y-%m-%d) $TIMESTAMP: Applied $MIGRATION_NAME" >> "$STATUS_FILE"

    # 7. AUTO-SQUASH (The Cleanup)
    echo "==> [7/10] Tidying up stale migrations (Squashing)..."
    if supabase migration squash --yes; then
        echo "==> Squashing complete. Folder is now lean."
        
        # 8. DELETE Stale Knowledge Files
        echo "==> [8/10] Deleting stale knowledge files..."
        find "$KNOWLEDGE_DIR" -maxdepth 1 -name "*.md" ! -name "$(basename "$KNOWLEDGE_FILE")" -delete
    else
        echo "==> WARNING: Squash failed. Skipping cleanup."
    fi

    # 9. Refresh local source-of-truth snapshot
    echo "==> [9/10] Refreshing local database snapshot artifacts..."
    mkdir -p "$SNAPSHOT_DB_DIR"
    supabase db dump --local --schema public --file "$SNAPSHOT_DB_DIR/schema_snapshot.sql"

    # 10. FRONTEND SYNC (Global Discovery Bridge)
    echo "==> [10/10] Searching and Syncing frontend portals..."
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
    echo "==> All systems synchronized."

else
    echo "==> ERROR: Failed to apply migration. Please check your SQL syntax."
    echo "    -> Data backup exists at: $BACKUP_FILE"
    echo "    -> Restore via: bash scripts/restore_local_db.sh \"$BACKUP_FILE\""
    exit 1
fi
