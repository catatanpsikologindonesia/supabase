# GAS Mail Dispatcher

Single source of truth untuk jalur pengiriman email Catatan Psikolog:

- HTML email dirender di Supabase edge function.
- GAS hanya bertugas memverifikasi signature, mencegah replay, lalu mengirim email via `GmailApp.sendEmail`.

## Script Properties

Tambahkan Script Property berikut di Apps Script:

- `MAIL_WEBHOOK_SECRET`

Nilainya harus sama persis dengan env Supabase:

- `MAIL_WEBHOOK_SECRET`

## Mail Identity

- sender name: `Catatan Psikolog Support`
- sender address: `support@catatanpsikolog.id`
- if the Apps Script executor account does not have `support@catatanpsikolog.id` configured as a valid Gmail alias, the dispatcher will automatically fall back to the account default sender address

## Required Supabase Env

- `MAIL_DISPATCHER_WEBHOOK_URL`
- `MAIL_WEBHOOK_SECRET`

## Edge Functions

- `send-patient-invitation`
- `send-referral-pin`

## Payload Contract

Dispatcher menerima JSON berikut:

```json
{
  "timestamp": "2026-04-04T16:00:00.000Z",
  "request_id": "uuid-or-stable-request-id",
  "to": "recipient@example.com",
  "subject": "Email subject",
  "html": "<html>...</html>",
  "reply_to": "",
  "use_custom_from": true,
  "signature": "hex-hmac-sha256"
}
```

String yang ditandatangani:

```text
timestamp
request_id
to
subject
html
reply_to
use_custom_from ? 1 : 0
```

## Deploy

1. Copy [Code.gs](./Code.gs) ke Apps Script project baru.
2. Set Script Property `MAIL_WEBHOOK_SECRET`.
3. Deploy sebagai Web App.
4. Simpan URL Web App itu ke env Supabase `MAIL_DISPATCHER_WEBHOOK_URL`.
5. Deploy edge function yang membutuhkan email.

## Notes

- `Code.gs` sengaja general-purpose. Dia tidak tahu business flow invite/referral.
- Semua subject, template, dan penerima email ditentukan dari Supabase project Catatan Psikolog.
