# Database Automation Protocol

All schema work in this repository is script-driven.

## Required Entry Point

```bash
bash scripts/apply_migration.sh "your_migration_name" "YOUR SQL HERE"
```

## Current Script Behavior

`scripts/apply_migration.sh` currently:

1. checks Docker and local Supabase readiness
2. creates a full local DB backup at `snapshot/database/db_full_snapshot.dump`
3. writes the migration file into `supabase/migrations/`
4. mirrors the migration into `knowledge/supabase_migrations/`
5. repairs orphaned local migration history if needed
6. applies the migration with `supabase db push --local`
7. appends a line to `knowledge/operations/MIGRATION_STATUS.md`
8. runs `supabase migration squash --yes`
9. deletes stale migration mirror markdown files after squash
10. refreshes `snapshot/database/schema_snapshot.sql`
11. searches for the user portal, admin portal, and landing page repos and runs `make sync-schema` where available

## Rules

- do not use `supabase migration new`
- do not create migration SQL files manually outside the script flow
- verify the generated migration result in both code and knowledge files
