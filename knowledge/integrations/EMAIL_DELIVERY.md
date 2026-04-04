# Email Delivery

## Current Model

Catatan Psikolog email delivery is handled by Supabase edge functions that forward requests to a Google Apps Script dispatcher.

## Active Edge Functions

- `send-patient-invitation`
- `send-referral-pin`

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
