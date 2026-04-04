# Current State

Last updated: 2026-04-05

## Repository Role

This repository is the operational Supabase home for Catatan Psikolog. It owns local stack startup, mirror automation, snapshots, migrations, edge functions, and deployment workflows.

## Local Stack

- local startup is handled by `make start-local`
- startup loads `.env.local`
- stale Docker container conflicts are cleaned up automatically when possible
- local startup preserves existing local data unless a restore or mirror command is explicitly used

## Email Delivery

Outbound email is now driven by edge functions plus a Google Apps Script dispatcher.

Active functions:

- `send-patient-invitation`
- `send-referral-pin`

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

## Operational Notes

- use `make start-local` for normal development
- use `make prepare-local` for a reproducible restore-based baseline
- use `make mirror-remote-to-local` only when you intentionally want a full remote refresh
- edge mail secrets are wired through `supabase/config.toml`
