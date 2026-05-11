# Migration Status

This file tracks all migrations applied via `scripts/apply_migration.sh`.

## History

- 2026-05-12 20260512015012: Applied clinic-lifecycle-b2b-full-schema (squashed baseline after script fix)

## Current Migration (Squashed)
- `20260512015012_clinic-lifecycle-b2b-full-schema.sql` — single squashed file containing complete public schema

## Script Fix (2026-05-12)
- `scripts/apply_migration.sh` fixed: `supabase migration up` → `yes | supabase db push --local` (targets local DB, not remote)
- Added step 3: auto-repair orphaned local migration history before applying new migration
- `supabase migration squash --yes` — non-interactive squash
