# Current State

Last updated: 2026-05-22

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

The repository currently uses one squashed migration file:

- `supabase/migrations/20260521210149_rpc_portal_update_clinic_asset_paths.sql` — squashed baseline plus B2B reminder and clinic profile asset RPCs

RPC naming standardization Phase 1 audit is documented in `knowledge/rpc-naming-mapping.md`; no SQL migrations have been applied for that initiative yet.

Normalized RPC functions replaced the previous `rpc_*` function names. The old `rpc_*` functions were dropped after CP admin/user source callsites were migrated and verified.

This file contains the active tables, enums, RPCs, triggers, RLS enablement, policies, `public.get_b2b_update_reminder(uuid)`, `public.rpc_portal_get_clinic_profile(uuid)`, and `public.rpc_portal_update_clinic_asset_paths(uuid, text, text, text)`.

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

Restore and migration hardening currently include:

- backup archive validation in `scripts/apply_migration.sh` before migration apply continues
- dump existence, non-zero-size, and `pg_restore --list` validation in `scripts/restore_local_db.sh`
- explicit restore steps documented in `knowledge/KNOWLEDGE_BASELINE.md`

Current parity note:

- `make verify-local-remote` still reports broader local-vs-remote drift in tables, functions, auth counts, storage objects, and edge-function inventory
- this repository should not be described as remote-parity-clean until that rollout gap is explicitly resolved
- `_shared/password_policy.ts` is currently in parity with the active Psikolog admin and user frontend validators

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

## Notable Schema Changes

- **2026-05-20**: Removed unused `admin` and `psychologist` values from `user_role` enum. Values `admin` and `psychologist` were never insertable due to `users_role_supported_chk` CHECK constraint. Enum now only contains `clinic_staff` and `patient`.
- **2026-05-20**: Fixed `demo_requests` INSERT RLS policy (`WITH CHECK (true)` → `WITH CHECK (false)`) — production flow inserts via edge function using `service_role`, so anon/authenticated direct REST inserts are now blocked.
- **2026-05-20**: Added 5 missing indexes on FK columns for query performance:
  - `patient_signatures(patient_id)`
  - `patient_invitations(invited_by_membership_id)`
  - `patient_invitations(practitioner_membership_id)`
  - `b2b_agreements(clinic_id)`
  - `clinics(owner_user_id)`
- **2026-05-20**: Fixed `get_clinics_with_pending_extension()` — added `is_admin_at_least('STAFF')` guard (was missing entirely, data leak). Converted from SQL to plpgsql. REVOKEd EXECUTE FROM anon.
- **2026-05-20**: Fixed `submit_patient_registration()` — lookup psychologist from `clinic_memberships.is_practitioner` instead of `users.role in ('admin','psychologist')` (which were removed from enum, function was broken).
- **2026-05-20**: REVOKEd EXECUTE FROM anon for 8 admin/internal functions: `get_clinics_with_pending_extension`, `create_clinic_with_owner` (3 overloads), `admin_list_clinics`, `admin_get_clinic_detail`, `admin_add_clinic_member`, `approve_clinic_extension_request`, `reject_clinic_extension_request`.
- **2026-05-20**: REVOKEd SELECT FROM anon for 26 sensitive tables (all non-reference). GraphQL schema no longer exposes clinic/patient table names to public. Only reference tables (address, religion, education, occupation, marital_status) remain visible to anon.
- **2026-05-20**: Added 13 more missing indexes on FK columns (B2B, patient personal data, patient family data).
- **2026-05-20**: REVOKEd EXECUTE FROM anon for 3 SECURITY DEFINER write functions: `add_clinic_member_by_email`, `create_patient_invitation_with_schedule`, `save_therapy_session_entry`.
- **2026-05-20**: REVOKEd EXECUTE FROM anon for 15 additional SECURITY DEFINER functions (admin ops, patient registration, internal helpers). Total anon-exposed functions reduced from 25 to 10. Supabase linter warnings reduced from 106 to 85 (21 actionable, rest inherent/intentional).
- **2026-05-21**: Added frontend RPC migration contracts for the admin and user portals. Active frontend database reads/writes now go through RPC contracts; direct `supabase.from()` database table access has been removed from both active frontend codebases. Storage bucket access still uses `supabase.storage.from()`.
- **2026-05-21**: Added `public.get_b2b_update_reminder(uuid)` for the user portal PKS update banner. The RPC compares `b2b_agreement_templates.updated_at` with the clinic's latest `b2b_agreements.signed_at` and returns a seven-day reminder window.
- **2026-05-21**: Added clinic profile asset support: `clinics.profile_picture_path`, `clinics.stamp_path`, `clinics.signature_path`, private `clinic_profile_picture` storage bucket, member-scoped storage policies, `rpc_portal_get_clinic_profile(uuid)`, and `rpc_portal_update_clinic_asset_paths(uuid, text, text, text)`.

## Key Active Rules

- never use `supabase migration new`
- use `bash scripts/apply_migration.sh` for schema changes
- outbound email goes through the GAS dispatcher
- backend changes are shared-contract changes for the admin portal, user portal, and any landing-page integration work
