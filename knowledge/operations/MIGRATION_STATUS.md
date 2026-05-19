# Migration Status

## Current Migration Layout

The repository currently keeps one squashed migration file:

- `20260518234046_rebuild-from-schema.sql`

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
- mirrors the migration into `knowledge/supabase_migrations/`
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
