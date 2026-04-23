# Database Automation Protocol (Catatan Psikolog)

All database schema changes in this repository MUST be automated using the provided script to ensure environmental parity across portals.

## Automated Script
Path: `scripts/apply_migration.sh`

### Usage
```bash
# From the root of Supabase/CatatanPsikolog
./scripts/apply_migration.sh "your_migration_name" "YOUR SQL QUERY HERE"
```

## Workflow
1. **Synthesize**: Generate the correct SQL for the requested change.
2. **Execute**: Call the script above with a descriptive name and the SQL.
3. **Verify**: Ensure the script returns success.
4. **Knowledge**: The script will automatically update `knowledge/supabase_migrations/`.
5. **Auto-Cleanup (Squash)**: The script will automatically run `supabase migration squash` and delete stale files.
6. **Frontend Sync**: The script will automatically search for `catatan-psikolog-user-portal` and `catatan-psikolog-admin-portal` and run `make sync-schema`.

## Rationale
Ensures that the Database, Migrations, Knowledge base, and TypeScript types in all frontend portals are synchronized simultaneously.
