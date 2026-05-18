# Current State

Last updated: 2026-05-19

## Repository Role

This repository is the shared backend authority for Catatan Psikolog.

It currently owns:

- database schema and RLS
- SQL functions, triggers, and policies
- edge functions and shared helpers
- local restore, mirror, verify, and push automation
- snapshot artifacts for local recovery and parity work

## Branch And Runtime

- active branch in local docs: `dev`
- project id: `CatatanPsikolog`
- local API port: `55321`
- local DB port: `55322`
- local Studio port: `55323`
- local Inbucket port: `55324`
- local DB container name pattern: `supabase_db_CatatanPsikolog`

## Edge Functions In Code

The current codebase contains 23 edge functions:

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

## Shared Helper Surfaces

Current `_shared/` files in code:

- `auth.ts`
- `http.ts`
- `mail_dispatcher.ts`
- `mail_flow_errors.ts`
- `otp.ts`
- `password_policy.ts`
- `patient_invitation_mail.ts`
- `rate_limit.ts`
- `referral_pin_mail.ts`
- `signature_storage.ts`
- `validation.ts`
- `email_templates/demo_request.ts`
- `email_templates/patient_invitation.ts`
- `email_templates/registration_invite.ts`
- `email_templates/referral_pin.ts`

## Migration State

The repository currently uses a single squashed migration baseline:

- `supabase/migrations/20260518234046_rebuild-from-schema.sql`

That file contains the active tables, enums, RPCs, triggers, RLS enablement, and policies.

## Current Public Schema Families

- address hierarchy tables
- admin profiles
- appointments
- B2B agreement templates, agreements, and invitations
- clinic extension requests
- clinic memberships
- clinic patients
- clinics
- cognitive assessments
- consent templates
- demo requests
- developmental history
- edge rate limit events
- education
- marital status
- occupation
- OTP verifications
- patient clinic consents
- patient consents
- patient family data
- patient invitations
- patient personal data
- patient signatures
- patient visits
- patients
- referrals and feedback
- religion
- therapy sessions
- users

## Current Operational Scripts

The repo currently exposes script-driven workflows for:

- migration apply and squash
- local stack startup
- local DB restore
- remote snapshot pull
- local/remote parity verification
- full remote-to-local mirror
- storage sync
- auth sync
- cron sync
- extension sync
- staging and production push flows

## Snapshot State

Committed database snapshot artifacts currently present:

- `schema_snapshot.sql`
- `db_full_snapshot.dump`
- `auth_snapshot.dump`
- `db_counts.txt`
- `db_tables.txt`
- `db_functions.txt`
- `db_views.txt`
- `db_extensions.txt`
- `extensions_export.sql`
- `cron_jobs_export.sql`

## Key Active Rules

- never use `supabase migration new`
- use `bash scripts/apply_migration.sh` for schema changes
- outbound email goes through the GAS dispatcher
- backend changes are shared-contract changes for the admin portal, user portal, and any landing-page integration work
