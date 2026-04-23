# Current State

Last updated: 2026-04-24

## Repository Role

This repository is the operational Supabase home for Catatan Psikolog. It owns local stack startup, mirror automation, snapshots, migrations, edge functions, and deployment workflows.

## Local Stack

- local startup is handled by `make start-local`
- startup loads `.env.local`
- stale Docker container conflicts are cleaned up automatically when possible
- local startup now restores the local DB snapshot by default before opening the full stack
- local restore includes the `storage` schema and restores binary storage contents from `snapshot/storage/objects/` via the local Storage API when that artifact exists
- local startup avoids replaying the full historical migration chain during normal boot
- local startup can remain safe even when remote features like `pg_cron` or storage buckets are not present yet

## Current Runtime Feature Availability

- `pg_cron` is not currently enabled on the active Catatan Psikolog remote project
- storage buckets and storage objects are currently empty on the active Catatan Psikolog remote project
- local startup and snapshot flows now remain compatible with that reduced feature surface without changing the source-of-truth workflow

## Email Delivery

Outbound email is now driven by edge functions plus a Google Apps Script dispatcher.

Active functions:

- `create-patient-invitation`
- `create-referral`
- `submit-patient-registration`
- `send-patient-invitation`
- `send-referral-pin`
- `accept-patient-consent`
- `verify-referral-pin`

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

## Authenticated Therapy Write Surface

- therapy session persistence is now exposed through DB RPC `save_therapy_session_entry`
- intended caller is the authenticated therapy workspace in `catatan-psikolog-user-portal`
- the function enforces practitioner access plus clinic/patient/visit consistency before inserting into `therapy_sessions`

## Authenticated Invitation Surface

- patient invitation creation is now exposed through authenticated edge function `create-patient-invitation`
- intended caller is the invite modal in `catatan-psikolog-user-portal`
- the function creates the invitation via RPC and immediately triggers `send-patient-invitation`

## Authenticated Referral Surface

- referral creation is now exposed through authenticated edge function `create-referral`
- intended caller is the therapy workspace in `catatan-psikolog-user-portal`
- the function generates the PIN, persists the referral, and then triggers `send-referral-pin`

## Public Registration Surface

- patient registration submit is now exposed through public edge function `submit-patient-registration`
- intended caller is the registration wizard in `catatan-psikolog-user-portal`
- the function preserves the current sign-up/sign-in fallback orchestration while removing the Next route from the active runtime path

## Operational Notes

- use `make start-local` for normal development
- use `make prepare-local` only when you explicitly need restore + migration replay
- use `make mirror-remote-to-local` only when you intentionally want a full remote refresh
- **Universal Automated Migration & Sync Protocol (April 2024)**:
  - New migrations must be executed via `scripts/apply_migration.sh`.
  - The script automatically handles: Migration creation, DB apply, Knowledge mirroring, Auto-Squash, and Global Frontend Sync for all Psikolog portals.
- **Global Baseline Reconstruction (April 2024)**:
  - All legacy migrations have been consolidated into a single clean source of truth (`supabase/migrations/`) to ensure environmental parity and resolved schema drift.
- if local storage binaries change, run `make export-storage` so repository snapshots stay aligned with the local source of truth
- edge mail secrets are wired through `supabase/config.toml`
