# Email Delivery

## Current Delivery Model

Email delivery in this repository is handled by edge-function code that posts signed payloads to a Google Apps Script dispatcher.

## Current Mail-Related Surfaces In Code

Primary function entry points:

- `send-patient-invitation`
- `send-referral-pin`
- `send-otp`
- `submit-demo-request`

Shared helper entry points:

- `_shared/mail_dispatcher.ts`
- `_shared/patient_invitation_mail.ts`
- `_shared/referral_pin_mail.ts`
- `_shared/email_templates/demo_request.ts`
- `_shared/email_templates/patient_invitation.ts`
- `_shared/email_templates/registration_invite.ts`
- `_shared/email_templates/referral_pin.ts`

## Trust Boundary

- edge functions resolve authoritative recipient and business data from the database when required by the flow
- navigation context such as base URLs and timezones may be provided by callers
- message delivery still terminates at the GAS webhook, not direct SMTP

## Current Runtime Secrets

- `MAIL_DISPATCHER_WEBHOOK_URL`
- `MAIL_WEBHOOK_SECRET`

## Sender Behavior

- preferred sender name: `Catatan Psikolog Support`
- preferred sender address: `support@catatanpsikolog.id`
- if the alias is unavailable in Gmail, Apps Script falls back to the executor account default sender

## Timezone Behavior

- templates accept recipient timezone input where needed
- fallback timezone remains `Asia/Jakarta`
