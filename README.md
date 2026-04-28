# Catatan Psikolog Supabase

Operational Supabase repository for the Catatan Psikolog product line. This repository is the source of truth for local mirror workflows, snapshots, migrations, edge functions, and controlled remote deployments.

## What This Repository Owns

- Supabase CLI workspace under `supabase/`
- database snapshots and verification outputs under `snapshot/`
- local mirror, restore, and deploy scripts under `scripts/`
- Google Apps Script based email delivery integration
- repository knowledge under `knowledge/`

## Main Capabilities

- start the local Supabase stack safely without forcing a restore
- restore or fully mirror remote state into the local stack
- verify local versus remote parity
- deploy schema and edge-function changes to staging or production
- host the Catatan Psikolog outbound email edge functions

## Prerequisites

- Supabase CLI
- Docker runtime
- `psql`
- `pg_restore`
- `jq`

## Environment Files

This private repository currently keeps active environment files in git.

- `.env.local`
- `.env.local.keys`
- `.env.staging`
- `.env.prod`

Important mail-related values:

- `MAIL_DISPATCHER_WEBHOOK_URL`
- `MAIL_WEBHOOK_SECRET`

### Golden Development Workflow

The recommended entry point is from any frontend portal root:
- `make run-local`: Full stack start that preserves the current local DB state and syncs frontend schema.
- `make run-local-fast`: Incremental start (preserves existing local data).
- `make run-local-restore`: Explicit baseline restore before app start.
- Frontend `make` helper targets invoke repository `scripts/*.sh` through `bash`, so these entry points do not depend on script executable permissions.

### Supabase Commands (from this repo)
```bash
make start-local              # Normal start (preserves current local DB)
make start-local-restore      # Start stack and restore local baseline snapshot
make pull-snapshot            # Refresh local artifacts from production
bash scripts/apply_migration.sh "<name>" "<sql>" # Automated migration & sync
make verify-local-remote      # Parity check
```

## Local Ports

- API `55321`
- DB `55322`
- Studio `55323`
- Mailpit `55324`

## Email Delivery

The current delivery path is edge-function based and posts to a Google Apps Script dispatcher.

Active mail functions:

- `send-patient-invitation`
- `send-referral-pin`

`send-patient-invitation` supports:

- `registration_required`
- `consent_required`
- `info_only`

## Documentation

Start with [knowledge/README.md](./knowledge/README.md).
