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

## Core Rules

- do not use `supabase migration new`
- use the migration script entry point
- keep email delivery on the GAS dispatcher path
- treat schema and function changes as shared frontend contracts
