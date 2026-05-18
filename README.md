# Catatan Psikolog Supabase

Shared Supabase backend for the Catatan Psikolog product line.

## Repository Scope

- PostgreSQL schema and RLS under `supabase/migrations/`
- Edge functions under `supabase/functions/`
- Local stack, restore, mirror, verify, and push automation under `scripts/`
- Snapshot artifacts under `snapshot/`
- Repo knowledge under `knowledge/`
- Google Apps Script mail dispatcher integration under `integrations/gas-mail-dispatcher/`

## Current Edge Functions

- `accept-patient-consent`
- `address-reference`
- `admin-add-clinic-member`
- `admin-create-clinic`
- `admin-get-b2b-templates`
- `admin-set-b2b-template-active`
- `admin-toggle-clinic-active`
- `admin-update-clinic`
- `create-b2b-invitation`
- `create-patient-invitation`
- `create-patient-invitation-v2`
- `create-referral`
- `extend-clinic-expiry`
- `get-b2b-invitation`
- `reset-password`
- `send-otp`
- `send-patient-invitation`
- `send-referral-pin`
- `submit-b2b-invitation`
- `submit-demo-request`
- `submit-patient-registration`
- `verify-otp`
- `verify-referral-pin`

## Shared Function Helpers

- `_shared/auth.ts`
- `_shared/http.ts`
- `_shared/mail_dispatcher.ts`
- `_shared/mail_flow_errors.ts`
- `_shared/password_policy.ts`
- `_shared/patient_invitation_mail.ts`
- `_shared/rate_limit.ts`
- `_shared/referral_pin_mail.ts`
- `_shared/signature_storage.ts`
- `_shared/otp.ts`
- `_shared/validation.ts`
- `_shared/email_templates/*`

## Database State

The repo currently keeps a single squashed migration baseline:

- `supabase/migrations/20260518234046_rebuild-from-schema.sql`

That baseline defines the active public schema, RLS policies, triggers, and RPC surfaces.

## Core Commands

```bash
make start-local
make start-local-restore
make restore-local
make pull-snapshot
make verify-local-remote
make mirror-remote-to-local
make push-staging
make push-prod
bash scripts/apply_migration.sh "name" "SQL"
```

## Local Ports

- API `55321`
- DB `55322`
- Studio `55323`
- Inbucket `55324`

## Current Snapshot Artifacts

- `snapshot/database/schema_snapshot.sql`
- `snapshot/database/db_full_snapshot.dump`
- `snapshot/database/auth_snapshot.dump`
- `snapshot/database/db_counts.txt`
- `snapshot/database/db_tables.txt`
- `snapshot/database/db_functions.txt`
- `snapshot/database/db_views.txt`
- `snapshot/database/db_extensions.txt`
- `snapshot/database/extensions_export.sql`
- `snapshot/database/cron_jobs_export.sql`

## Documentation

Start with `knowledge/README.md`.
