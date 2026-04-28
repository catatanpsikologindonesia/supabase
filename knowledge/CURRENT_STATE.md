# Current State

Last updated: 2026-04-28 (Remote Snapshot Refresh and Verified Local/Remote Parity)

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

## Email Delivery

Outbound email is now driven by edge functions plus a Google Apps Script dispatcher.

- `MAIL_DISPATCHER_WEBHOOK_URL` has been rotated to the latest deployed Apps Script Web App endpoint on 2026-04-26.
  - active endpoint: `https://script.google.com/macros/s/AKfycbwSntcwwDc4bnsTfH51xL6ZgMjep_xHp8CDp57oxU2iyc7NQFYfuWOMZKfUAeHNw1JC1g/exec`

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
- the function creates the invitation via RPC and then uses the shared invitation-mail helper directly, avoiding local edge-runtime self-calls before fallback handling
- the edge function now forwards the caller JWT into the invitation RPC so `auth.uid()`-dependent checks survive the edge boundary
- the function now honors the request `clinic_id` when resolving the active membership in multiclinic scenarios
- fallback registration links use the active query-based route shape: `/register?token=...`
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

## Operational Notes

- 2026-04-28 parity verification refresh:
  - local stack was restarted successfully under Supabase CLI `2.95.4` after the heavy image refresh triggered by the CLI upgrade.
  - `make verify-local-remote` returned `VERIFY OK` against the active remote project using the pooler connection path.
  - repository-owned snapshot artifacts were refreshed and committed so the local parity evidence matches the current remote state.
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
