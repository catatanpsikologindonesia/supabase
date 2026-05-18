# Agent Protocol

Backend-specific protocol for `Supabase/CatatanPsikolog`.

## Required Behaviors

1. Use `bash scripts/apply_migration.sh "name" "SQL"` for schema changes.
2. Treat backend changes as shared contracts for both portals and related landing-page integrations.
3. Update `knowledge/CURRENT_STATE.md` and `knowledge/operations/MIGRATION_STATUS.md` when backend capabilities or migration state change.
4. Preserve snapshot artifacts used by restore and parity workflows.

## Current Operational Reality

- the repo uses one squashed migration baseline
- the repo currently has 23 edge functions
- local DB restore defaults to `snapshot/database/db_full_snapshot.dump`
- parity verification compares tables, functions, views, cron, storage, auth counts, and edge-function slugs
