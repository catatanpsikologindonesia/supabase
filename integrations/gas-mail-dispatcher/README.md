# GAS Mail Dispatcher

Google Apps Script is the outbound email bridge for this Supabase backend.

## Current Role

- edge functions render the email HTML
- Supabase signs the request with HMAC SHA-256
- Apps Script verifies the signature and replay fields
- Apps Script sends the message through Gmail

## Required Script Property

- `MAIL_WEBHOOK_SECRET`

It must match the Supabase runtime secret with the same name.

## Required Supabase Secrets

- `MAIL_DISPATCHER_WEBHOOK_URL`
- `MAIL_WEBHOOK_SECRET`

## Current Mail-Related Functions

- `send-patient-invitation`
- `send-referral-pin`
- `send-otp`
- `submit-demo-request`

Authenticated orchestration functions also trigger shared mail helpers through `_shared/patient_invitation_mail.ts` and `_shared/referral_pin_mail.ts`.

## Sender Identity

- preferred sender name: `Catatan Psikolog Support`
- preferred sender address: `support@catatanpsikolog.id`

If the executing Apps Script account does not expose that alias, Gmail falls back to the account default sender address.

## Payload Contract

```json
{
  "timestamp": "2026-05-19T00:00:00.000Z",
  "request_id": "uuid-or-stable-request-id",
  "to": "recipient@example.com",
  "subject": "Email subject",
  "html": "<html>...</html>",
  "reply_to": "",
  "use_custom_from": true,
  "signature": "hex-hmac-sha256"
}
```

Signed message order:

```text
timestamp
request_id
to
subject
html
reply_to
use_custom_from
```

## Deployment

1. Copy `Code.gs` into an Apps Script project.
2. Set the `MAIL_WEBHOOK_SECRET` script property.
3. Deploy the script as a web app.
4. Save the web app URL into `MAIL_DISPATCHER_WEBHOOK_URL` in Supabase secrets.
