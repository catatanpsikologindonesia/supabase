# Knowledge Baseline

Baseline reference for the `Supabase/CatatanPsikolog` repository.

## System Overview

This Supabase project is the shared backend for Catatan Psikolog. It serves multiple consumers and centralizes database schema, auth-adjacent backend logic, edge-function workflows, snapshots, and deployment automation.

## Current Repository Layout

- `supabase/migrations/`
  Active schema baseline SQL.
- `supabase/functions/`
  Edge functions plus `_shared/` helper code.
- `scripts/`
  Start, restore, mirror, verify, and push automation.
- `snapshot/`
  Database and function parity artifacts.
- `knowledge/`
  Repo documentation.
- `integrations/gas-mail-dispatcher/`
  Apps Script email bridge.

## Current Runtime Facts

- project id: `CatatanPsikolog`
- API port: `55321`
- DB port: `55322`
- Studio port: `55323`
- Inbucket port: `55324`
- database major version in `supabase/config.toml`: `17`

## Current Backend Surfaces

- one squashed migration baseline under `supabase/migrations/`
- 23 edge functions under `supabase/functions/`
- shared auth, rate-limit, password, validation, signature-storage, and mail helpers under `_shared/`

## Primary Operational Commands

```bash
make start-local
make start-local-restore
make restore-local
make pull-snapshot
make verify-local-remote
make mirror-remote-to-local
make push-staging
make push-prod
make knowledge-language-check
bash scripts/apply_migration.sh "name" "SQL"
```

## Local Restore Steps

Use the committed local snapshot as the primary recovery source.

1. Ensure Docker/Colima is running.
2. From repo root, run:
   `bash scripts/restore_local_db.sh`
3. To restore a specific archive, run:
   `bash scripts/restore_local_db.sh "snapshot/database/db_full_snapshot.dump"`
4. If auth snapshot replay is explicitly needed after the full restore, run:
   `RESTORE_AUTH_SNAPSHOT_AFTER_FULL_RESTORE=1 bash scripts/restore_local_db.sh`

Restore guardrails:

- the dump file must exist, be non-zero, and pass `pg_restore --list`
- do not assume partial remote data can replace the local dump during incident recovery
- after restore, verify printed row counts before treating the environment as healthy

## Core Rules

- do not use `supabase migration new`
- use the migration script entry point
- keep email delivery on the GAS dispatcher path
- treat schema and function changes as shared frontend contracts
