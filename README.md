# CatatanPsikolog Supabase Mirror

Operational mirror for the **CatatanPsikolog** Supabase project.

This repository is the team baseline for:

- pulling remote state into local
- verifying local/remote parity
- applying local schema/function updates
- pushing safely to staging/production

## Scope

The mirror covers business-critical Supabase assets:

- PostgreSQL schema and data (database dump + SQL snapshot)
- `public` RPC/functions inventory
- Auth parity checks (`auth.users`, `auth.identities`)
- Storage object parity checks and binary sync
- Edge Functions source and deployment
- `pg_cron` job parity

## Repository Layout

- `supabase/`  
  Supabase CLI workspace (`config.toml`, `migrations/`, `functions/`).
- `scripts/`  
  Pull/sync/verify/push automation.
- `snapshot/database/`  
  Latest database snapshot artifacts (`db_full_snapshot.dump`, `schema_snapshot.sql`, `db_*.txt`).
- `snapshot/functions/`  
  Edge Functions metadata snapshots.
- `snapshot/verification/`  
  Generated parity reports (`verify_local_remote_<timestamp>/`).
- `knowledge/`  
  Agent/team knowledge (non-runtime docs).
- `Makefile`  
  Standard command entry points.

## Prerequisites

- Supabase CLI
- Docker runtime (Colima or Docker Desktop)
- `psql` / `pg_restore` (libpq)
- `jq`

## Environment Files

Secrets are loaded by scripts and are gitignored.

- `.env.local` for local mirror operations
- `.env.staging` for staging push target
- `.env.prod` for production push target
- `.env.prod.example` as template

`SUPABASE_PAT_FILE` must point to a local file path on each developer machine
(do not commit PAT files or absolute paths).

## Daily Workflow

## Team Entry Point

For day-to-day frontend dev, use:

- `make run-local` from `catatan-psikolog-user-portal`

This command now auto-runs mirror prep (`make prepare-local`) + frontend contract sync + preflight checks.

### 1. Sync remote to local mirror

```bash
make mirror-remote-to-local
```

### 1b. Prepare local DB for frontend/agent work

Use this when you want a deterministic local baseline without manual migration troubleshooting.

```bash
make prepare-local
```

What it does:

- restores local DB from `snapshot/database/db_full_snapshot.dump`
- re-applies every SQL migration under `supabase/migrations/`
- validates key local artifact (`public` table count)

### 2. Verify parity

```bash
make verify-local-remote
```

### 3. Apply local changes (SQL, migration, edge function)

Edit files under `supabase/` and/or run SQL migration workflow.

### 4. Push

```bash
make push-staging
# after staging validation
make push-prod
```

`make push-remote` is an alias to `make push-staging`.

## Push Safety Guarantees

`scripts/push_remote_changes.sh` enforces:

1. local-vs-remote preflight verification
2. explicit operator confirmation on mismatch
3. remote backup snapshot before deployment
4. `supabase db push`
5. edge function deployment
6. post-push verification

## Local/Remote Resolution Strategy

Remote DB connectivity uses linked project metadata from Supabase CLI.

If direct DB host is unreachable from the current network, scripts automatically fallback to the Supabase pooler so mirror/verify remains reproducible.

## Knowledge Index

Start here for onboarding and agent execution context:

1. `knowledge/README.md`
2. `knowledge/TEAM_GUIDE.md`
3. `knowledge/OPERATIONS_CHECKLIST.md`
4. `knowledge/SUPABASE_SCHEMA_MAP.md`

## Project Identity

- Project name: `CatatanPsikolog`
- Staging project ref: `ixwaaziifteubxkxtdwj`
