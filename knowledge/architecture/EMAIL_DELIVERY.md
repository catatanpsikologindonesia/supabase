# Email Delivery

## Current Model

Catatan Psikolog email delivery is handled by Supabase edge functions that forward requests to a Google Apps Script dispatcher.

## Active Edge Functions

- `send-patient-invitation`
- `send-referral-pin`

## Trusted Inputs

The portal no longer sends trusted email content payloads to these functions.

- `send-patient-invitation` accepts `invitation_id`, `registration_base_url`, and `recipient_timezone`
- `send-referral-pin` accepts `referral_id`, `portal_base_url`, and `recipient_timezone`

The functions resolve recipients, flow data, clinic context, referral details, and related content from the database.

## Ownership Checks

- invitation emails require the authenticated staff user to match the `invited_by_membership_id` owner
- referral emails require the authenticated staff user to match the `practitioner_membership_id` owner

This reduces the risk of a leaked clinic staff token being used to send arbitrary branded email payloads.

## Invitation Variants

`send-patient-invitation` serves three variants:

- `registration_required`
- `consent_required`
- `info_only`

## Runtime Secrets

Required mail secrets:

- `MAIL_DISPATCHER_WEBHOOK_URL`
- `MAIL_WEBHOOK_SECRET`

These are exposed to edge functions through `edge_runtime.secrets` in `supabase/config.toml`.

## Timezone Handling

- templates accept `recipient_timezone`
- explicit `(Asia/Jakarta)` suffixes were removed from rendered email strings
- fallback timezone remains `Asia/Jakarta`

## Branding

Current email brand family is based on `#A5A5D3`.
