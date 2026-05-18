# Current State

Last updated: 2026-05-16

## Repository Role

This repository is the operational Supabase home for Catatan Psikolog. It owns local stack startup, mirror automation, snapshots, migrations, edge functions, and deployment workflows.

- **Golden Entry Point**: Local development is now driven by `make run-local` (preserve current local DB), `make run-local-fast` (incremental), or `make run-local-restore` (explicit baseline restore) from any portal root.
- **Auto-Wipe Bug (Fixed)**: The startup script no longer wipes the database due to false-positive 'Stopped services' (Vector) reports.
- **Offline Auth Restoration**: Local startup automatically restores `snapshot/auth/auth_snapshot.dump` to ensure authenticated dev sessions persist even when offline.
- **Data Integrity Guard**: `apply_migration.sh` has been hardened to never overwrite the production data snapshot with local/empty data.
- **Snapshot Guardrails (New)**:
  - `pull_remote_snapshot.sh` now fails fast on project-ref mismatch instead of silently trusting the current linked context.
  - remote snapshot pulls now persist table-count metadata in `snapshot/database/db_counts.txt`.
  - `restore_local_db.sh` now verifies restored core-table counts against that snapshot metadata and aborts on mismatch.
  - `restore_local_db.sh` now restores the full custom dump instead of a schema-filtered host restore, because the old filtered path could skip creating `auth`/`storage` schemas on a minimal local DB and silently corrupt the restored business data.
  - `restore_local_db.sh` now skips `auth_snapshot.dump` by default; forcing an auth-only restore after a full dump can cascade-delete dependent public business data.
- **Port Parity**: API is strictly mapped to `55321`, DB to `55322`.
- Local restore includes the `storage` schema and restores binary storage contents from `snapshot/storage/objects/` via the local Storage API when that artifact exists.
- Local startup avoids replaying the full historical migration chain during normal boot by using the squashed baseline.

## Current Runtime Feature Availability

- `pg_cron` is not currently enabled on the active Catatan Psikolog remote project
- storage buckets and storage objects are currently empty on the active Catatan Psikolog remote project
- local startup and snapshot flows now remain compatible with that reduced feature surface without changing the source-of-truth workflow
- `demo_requests` now also stores landing-page address line, RT/RW, subscribe flag, privacy consent flag, and normalized `fullname` / `position` fields for richer admin-side review without dropping the older `pic_name` / `pic_role` shape.
- `demo_requests` now also tracks `email_delivery_status` (pending/sent/failed), `email_delivery_error`, `registration_status` (registered/not_registered), `registered_at`, `client_ip`, and `user_agent` for end-to-end lead tracking from landing-page submission through clinic registration.
- `demo_requests` now also links successful manual clinic onboarding through `registered_clinic_id`, so admin-side registration can point back to the created `clinics` row.
- `clinics` now also stores `full_address` so the admin onboarding payload can persist the same computed address summary shown in the registration form.

## Email Delivery

Outbound email is now driven by edge functions plus a Google Apps Script dispatcher.

- `MAIL_DISPATCHER_WEBHOOK_URL` has been rotated to the latest deployed Apps Script Web App endpoint on 2026-04-26.
  - active endpoint: `https://script.google.com/macros/s/AKfycbwSntcwwDc4bnsTfH51xL6ZgMjep_xHp8CDp57oxU2iyc7NQFYfuWOMZKfUAeHNw1JC1g/exec`

Active functions:

- `create-patient-invitation`
- `create-patient-invitation-v2`
- `create-referral`
- `submit-patient-registration`
- `send-patient-invitation`
- `send-referral-pin`
- `accept-patient-consent`
- `verify-referral-pin`
- `admin-create-clinic`
- `admin-add-clinic-member`
- `admin-update-clinic`
- `admin-toggle-clinic-active`
- `admin-get-b2b-templates`
- `admin-set-b2b-template-active`
- `create-b2b-invitation`
- `get-b2b-invitation`
- `submit-b2b-invitation`
- `extend-clinic-expiry`
- `send-otp`
- `verify-otp`
- `reset-password`

Invitation variants:

- `registration_required`
- `consent_required`
- `info_only`

## Email Security State

- edge mail functions no longer trust raw recipient and content payloads from the portal
- `send-patient-invitation` now resolves invitation data from `patient_invitations` by `invitation_id`
- `send-referral-pin` now resolves referral and patient data from the database by `referral_id`
- both functions verify that the authenticated staff user owns the related membership before an email can be sent

## Timezone Handling

- email templates accept `recipient_timezone`
- raw timezone labels such as `(Asia/Jakarta)` have been removed from rendered email text
- fallback timezone remains `Asia/Jakarta`

## Public Verification Surface

- referral PIN verification is now exposed through public edge function `verify-referral-pin`
- intended caller is the public referral page in `catatan-psikolog-user-portal`
- the function verifies input, calls RPC `verify_referral_pin`, and normalizes fallback labels before returning a public-safe payload

## Public Consent Surface

- patient consent acceptance is now exposed through public edge function `accept-patient-consent`
- intended caller is the public consent flow in `catatan-psikolog-user-portal`
- the function forwards consent IP and user-agent metadata to RPC `accept_patient_consent_by_token`

## Public Auth Recovery Surface

- forgot-password recovery is now exposed through public edge functions `send-otp`, `verify-otp`, and `reset-password`
- intended caller is the public auth recovery flow in `catatan-psikolog-user-portal`
- additive local migration `20260513131224_auth-recovery-otp.sql` created `public.otp_verifications` and helper function `public.is_registered_profile_email(text)`
- `send-otp` stores hashed OTP codes, applies IP/email rate limits, and sends the recovery code through the shared Google Apps Script mail dispatcher
- `verify-otp` validates the active OTP window and marks the selected verification row as verified before returning `verification_id`
- `reset-password` validates password policy, resolves the matching `clinic_staff` auth user from `clinic_memberships.email`, updates `auth.users` through the admin API, and deletes the used OTP row on success

## Authenticated Therapy Write Surface

- therapy session persistence is now exposed through DB RPC `save_therapy_session_entry`
- intended caller is the authenticated therapy workspace in `catatan-psikolog-user-portal`
- the function enforces practitioner access plus clinic/patient/visit consistency before inserting into `therapy_sessions`

## Authenticated Invitation Surface

- patient invitation creation is now exposed through authenticated edge function `create-patient-invitation`
- `create-patient-invitation-v2` is the active clinic invite-modal variant for email, phone, and admin link-copy flows
- intended caller is the invite modal in `catatan-psikolog-user-portal`
- the function creates the invitation via RPC and then uses the shared invitation-mail helper directly, avoiding local edge-runtime self-calls before fallback handling
- the edge function now forwards the caller JWT into the invitation RPC so `auth.uid()`-dependent checks survive the edge boundary
- the function now honors the request `clinic_id` when resolving the active membership in multiclinic scenarios
- fallback registration links use the active query-based route shape: `/register?token=...`
- phone-based invitations now return a prefilled `wa.me` deeplink plus the raw WhatsApp message body so the portal can offer a dedicated "Kirim via WhatsApp" action alongside a manual copy fallback; the message copy includes the clinic name, the session schedule, and flow-specific wording (`registration_required`, `consent_required`, `info_only`).
- invitation email rendering also uses the active query-based registration route instead of the retired `/register/:token` path
- the Google Apps Script dispatcher now falls back to the executor default sender when `support@catatanpsikolog.id` is not available as a configured Gmail alias
- fallback success responses now expose a safe `mailFailureReason` code and log structured dispatcher-failure details without leaking webhook secrets or raw email HTML

## Authenticated Referral Surface

- referral creation is now exposed through authenticated edge function `create-referral`
- intended caller is the therapy workspace in `catatan-psikolog-user-portal`
- the function generates the PIN, persists the referral, and then uses the shared referral-mail helper directly, avoiding local edge-runtime self-calls before fallback handling
- referral fallback success responses now expose the same safe `mailFailureReason` code for operator debugging

## Public Registration Surface

- patient registration submit is now exposed through public edge function `submit-patient-registration`
- intended caller is the registration wizard in `catatan-psikolog-user-portal`
- the function preserves the current sign-up/sign-in fallback orchestration while removing the Next route from the active runtime path
- phone-based invitations now create or resolve patient auth users through the admin API and pass the invited phone through the registration RPC chain instead of requiring an invitation email

## Operational Notes

- 2026-04-28 parity verification refresh:
  - local stack was restarted successfully under Supabase CLI `2.95.4` after the heavy image refresh triggered by the CLI upgrade.
  - `make verify-local-remote` returned `VERIFY OK` against the active remote project using the pooler connection path.
  - repository-owned snapshot artifacts were refreshed and committed so the local parity evidence matches the current remote state.
- 2026-05-03 remote-to-local invitation parity sync completed:
  - pulled remote edge function source for `create-patient-invitation-v2` into the local mirror.
  - local-only stale overloads of `create_patient_from_auth_user` and `create_patient_invitation_with_schedule` were removed so local signatures now match staging.
  - final `make verify-local-remote` returned `VERIFY OK` after sync.
- 2026-05-03 address reference and demo intake baseline added locally:
  - additive migration `20260504004615_address-tables-and-demo-requests` created address hierarchy tables, `demo_requests`, and the `edge_check_rate_limit` helper infrastructure.
  - local edge functions `address-reference` and `submit-demo-request` now exist and respond successfully through the local gateway.
  - local seed scripts now populate address master data from `cahyadsn/wilayah` and `cahyadsn/wilayah_kodepos` with counts `38 / 514 / 7285 / 83724 / 83724`.
- 2026-05-04 admin portal auth baseline added locally:
  - additive migration `20260504005710_admin-profiles` created `admin_level_enum`, `admin_profiles`, audit trigger helpers, and `is_admin_at_least(text)`.
  - `demo_requests` now exposes authenticated admin read access through RLS so dashboard counts can be fetched without service-role usage.
  - local verification seeded three auth users: one active `SUPER_ADMIN`, one auth-only user without `admin_profiles`, and one CRUD validation user.
  - local `make verify-local-remote` now reports mismatch because the local mirror intentionally includes unapplied local-only schema/auth changes and previously diverged edge-function work.
- 2026-05-05 admin clinic registration baseline added locally:
  - additive migrations `20260505045301_admin_add_clinic_member_rpc`, `20260505051338_admin_list_clinics_rpc`, and `20260505061355_admin_get_clinic_detail_rpc` were applied locally.
  - new edge functions `admin-create-clinic` and `admin-add-clinic-member` now provide the admin-only onboarding path for clinic creation and clinic member bootstrap.
  - shared edge helpers now include password-policy and validation utilities used by the new admin registration functions.
  - local API validation confirmed: unauthorized and non-admin callers are rejected, owner creation writes `auth.users` + `public.users` + `public.clinics` + `public.clinic_memberships`, practitioner default profession resolves to `psychologist`, non-practitioner profession stays `NULL`, and rollback deletes auth users after downstream clinic lookup failure.
  - the replay gap was resolved by squashing the active folder into a single baseline file `20260505061355_admin_get_clinic_detail_rpc.sql`; local `supabase migration squash` now completes successfully without warnings.
- 2026-05-05 patient registration Step 1 baseline added locally:
  - new public reference tables `religion`, `education`, and `occupation` were added with public read access and admin-only write access.
  - tracked seed automation now exists in `scripts/seed_reference_data.sh` + `scripts/seed_reference_upsert.sql` for religion, education, occupation, and marital status rows.
  - `patient_personal_data` now stores structured lookup IDs plus geographic domain IDs, address line, and RT/RW fields.
  - `patient_family_data` now stores structured guardian address domain IDs plus guardian address line and RT/RW fields.
  - `update_patient_registration_by_user_id` now persists both the new structured fields and backward-compatible text fallbacks for reference labels and address strings.
  - `submit-patient-registration` now validates the structured registration payload used by the updated public intake wizard.
  - the first implementation used `integer` for all geographic domain IDs, but live registration verification exposed that `subdistrict_domain_id` values exceed `int4`; the active columns and RPC casts were corrected to `bigint`.
  - `create_patient_from_auth_user` now creates the initial `patients` row with `full_name`, `email`, and `phone`, fixing the earlier not-null failure on `patients.full_name` during public registration.
  - end-to-end local verification succeeded through `submit-patient-registration`: auth user creation, patient bootstrap, structured `patient_personal_data`, structured `patient_family_data`, and invitation completion all completed successfully.
  - after the patient-registration work, the migration folder was rebuilt into a single replay-clean local baseline `20260505130000_local_full_baseline.sql`; `supabase migration squash` now completes cleanly again.
- 2026-05-05 patient registration Step 1 + Step 2 follow-up added locally:
  - `public.marital_status` now exists as a public reference table with 5 seeded rows and admin-only write access.
  - `patient_family_data` now stores father/mother education and occupation lookup IDs, marital-status lookup ID, and the related `other_*` fallback text fields.
  - `update_patient_registration_by_user_id` now resolves and persists father/mother education, father/mother occupation, and marital-status labels from reference-table UUIDs while still preserving backward-compatible text fallbacks.
  - public registration local verification succeeded with a full Step 1 + Step 2 payload, including structured guardian address data and family lookup IDs.
  - tracked reference seeding is now reproducible through `scripts/seed_reference_data.sh` + `scripts/seed_reference_upsert.sql`.
  - `marital_status` was deduplicated and now has a `lower(name)` unique index so the seed helper is idempotent across reruns.
  - active local migration baseline is now `20260505232611_fix_marital_status_seed_idempotency.sql` after replay-clean squash.
  - `make verify-local-remote` still reports `VERIFY MISMATCH` because the local-only tables, functions, auth counts, and edge sources have not yet been promoted to the remote project.
- 2026-05-06 consent page with digital signature added locally:
  - `public.patient_signatures` now stores one immutable reusable signature row per patient, backed by private storage bucket `patient_signatures`.
  - `patient_clinic_consents` now includes nullable `signature_id` and active consent rows can point to reusable patient signatures.
  - `accept_patient_consent_by_token` now requires a `signature_id` and validates ownership against the invitation patient before writing consent.
  - `update_patient_registration_by_user_id` now requires a signature for registration-complete invites and links that signature into `patient_clinic_consents`.
  - public edge functions `accept-patient-consent` and `submit-patient-registration` now decode/upload/reuse PNG signature data and inject the resulting `signatureId` into the backend RPC chain.
  - the active local migration baseline is now `20260506212421_signature_consent_registration_rpcs.sql`.
- 2026-05-05 phone-invitation registration repair added locally:
  - `submit-patient-registration` now accepts invitation lookups with `contact_type = phone`, no longer requires an invitation email on the public submit path, and creates or resolves patient auth users through the admin API for phone-based invitations.
  - `update_patient_registration_by_user_id` now validates `auth.users.phone` against phone invitations, preserves existing patient email on phone-only registrations, and keeps the invited phone as the fallback patient phone when the intake form leaves the patient phone blank.
  - active local migration baseline is now `20260505230112_fix_phone_registration_submit_flow.sql` after replay-clean squash.
- 2026-05-11 demo-requests delivery and registration tracking:
  - additive migration `20260511042709_demo-requests-delivery-registration-tracking` added `email_delivery_status`, `email_delivery_error`, `registration_status`, `registered_at` columns to `demo_requests`.
  - `submit-demo-request` edge function now updates `email_delivery_status` and `email_delivery_error` after attempting mail dispatch instead of leaving the status at the default `pending`.
  - stale migration mirrors `20260506212421_signature_consent_registration_rpcs.md` and `20260508114021_demo-requests-client-audit-columns.md` were removed by the auto-squash pipeline.
  - stale migration SQL files `20260506212421_signature_consent_registration_rpcs.sql` and `20260508114021_demo-requests-client-audit-columns.sql` removed by the auto-squash pipeline.
- use `make start-local` for normal development
- use `make start-local-restore` when you explicitly want to restore `snapshot/database/db_full_snapshot.dump` during startup
- use `make prepare-local` only when you explicitly need restore + migration replay
- use `make mirror-remote-to-local` only when you intentionally want a full remote refresh
- knowledge policy cleanup 2026-04-27:
  - consolidated redaction and documentation-language rules into `knowledge/operations/SECURITY.md`
  - removed standalone policy stubs that duplicated the same backend operational rules
- **Universal Automated Migration & Sync Protocol (April 2024)**:
  - New migrations must be executed via `scripts/apply_migration.sh`.
  - The script automatically handles: Migration creation, DB apply, Knowledge mirroring, Auto-Squash, and Global Frontend Sync for all Psikolog portals.
- **Global Baseline Reconstruction (April 2024)**:
  - All legacy migrations have been consolidated into a single clean source of truth (`supabase/migrations/`) to ensure environmental parity and resolved schema drift.
- if local storage binaries change, run `make export-storage` so repository snapshots stay aligned with the local source of truth
- edge mail secrets are wired through `supabase/config.toml`
- 2026-05-12 clinic lifecycle + B2B agreement baseline — squashed & script fix:
  - Previous additive migration `20260512010326_clinic-lifecycle-b2b-agreements.sql` squashed into baseline `20260512015012_clinic-lifecycle-b2b-full-schema.sql` (contains complete public schema, no loose migration files).
  - Schema: `expired_date`, `is_agreement_signed`, `permit_number`, `phone_number` on `clinics`; `b2b_agreement_templates`, `b2b_invitations` tables; `b2b-signatures` storage bucket.
  - 8 edge functions: `admin-update-clinic`, `admin-toggle-clinic-active`, `admin-get-b2b-templates`, `admin-set-b2b-template-active`, `create-b2b-invitation`, `get-b2b-invitation`, `submit-b2b-invitation`, `extend-clinic-expiry`.
  - `scripts/apply_migration.sh` fixed: `supabase migration up` → `yes | supabase db push --local` (targets local DB, not remote). Added auto-repair step for orphaned migration history. Squash now uses `--yes` for non-interactive mode.
- 2026-05-13 clinic registration parity hardening:
  - additive migration `20260513133454_clinic-registration-demo-parity` added `demo_requests.registered_clinic_id`.
  - `create_clinic_with_owner(...)` now persists clinic registration metadata already captured by the admin portal: `permit_number`, `owner_ktp_number`, `phone_number`, `address_line`, `rt_rw`, `province_name`, `city_name`, `district_name`, `subdistrict_name`, `postal_code`, and `expired_date`.
- 2026-05-16 Dokter-parity clinic extension workflow:
  - additive migration `20260516224717_clinic-extension-dokter-parity.sql` added `clinic_extension_request_status_enum`, `b2b_agreements`, `clinic_extension_requests`, and Dokter-style RPCs `approve_clinic_extension_request(uuid, integer)`, `reject_clinic_extension_request(uuid)`, and `get_clinics_with_pending_extension()`.
  - `b2b_agreements` now stores the signed agreement record separately from `b2b_invitations`, aligning Psikolog's backend contract with Dokter's renewal workflow.
  - `clinic_extension_requests` now tracks owner-side renewal submissions with `PENDING / APPROVED / REJECTED` state, `approved_by`, and `added_days`.
  - RLS now allows clinic owners to insert/select their own extension requests and allows LBSD admins to review/update them.
  - `submit-b2b-invitation` now also persists a signed agreement row into `b2b_agreements` after public invitation signing succeeds, while continuing to update the original invitation status.
  - follow-up migration `20260517050122_b2b-agreements-storage-policy.sql` added authenticated Storage policies for bucket `b2b-signatures`, fixing the new clinic-detail renewal path so owner-side signature uploads are allowed at runtime.
  - `admin-create-clinic` now forwards the full admin registration payload to that RPC instead of dropping the optional clinic metadata.
 - 2026-05-13 final registration parity follow-up:
  - additive migration `20260513144457_clinic-full-address-parity` added `clinics.full_address`.
  - additive migration `20260513150000_clinic-full-address-rpc-parity` expanded `create_clinic_with_owner(...)` to persist `full_address` alongside the rest of the clinic metadata.
