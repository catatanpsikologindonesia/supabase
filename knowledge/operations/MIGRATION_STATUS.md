# Migration Status

## Current Migration Layout

The repository currently keeps one squashed migration file:

- `20260520231500_cleanup_remaining_warnings.sql`

This file is the active schema baseline under `supabase/migrations/`.

## Automation Entry Point

Schema changes must use:

```bash
bash scripts/apply_migration.sh "name" "SQL"
```

## Current Script Behavior

The migration script currently:

- creates a pre-migration local DB backup
- writes the SQL migration file
- records migration status in this file; the old `knowledge/supabase_migrations/` mirror directory is no longer used after the squash flow
- repairs orphaned local migration history when needed
- applies the migration with `supabase db push --local`
- appends a status line to this file
- squashes migrations with `supabase migration squash --yes`
- deletes stale migration mirror markdown files
- refreshes `snapshot/database/schema_snapshot.sql`
- attempts `make sync-schema` in the user portal, admin portal, and landing page repos if found

## Historical Status Lines Present In File History

The current code appends plain bullet lines to this file after each successful migration run. This document describes the active process and current squashed result rather than reconstructing older entries from prior doc text.
- 2026-05-20 20260520015345: Applied fix-patient-consents-rls
- 2026-05-20 20260520222619: Applied cleanup_user_role_enum
- 2026-05-20 20260520224754: Applied fix_rls_and_indexes
- 2026-05-20 20260520225900: Applied fix_security_functions (manual via supabase db push)
- 2026-05-20 20260520231500: Applied cleanup_remaining_warnings (manual via supabase db push)
- 2026-05-21 20260521124811: Applied security_hardening_rpc_migration
- 2026-05-21 20260521194855: Applied get_b2b_update_reminder
- 2026-05-21 20260521195302: Applied get_b2b_update_reminder
