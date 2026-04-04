# Current State (Catatan Psikolog Supabase)

Last audited: 2026-04-04 (Asia/Jakarta)

## Repository Role

Supabase mirror and migration source for Catatan Psikolog backend.

## Git/Branch Snapshot

- Branch: `main`
- Mail-dispatch workstream in progress:
  - `supabase/functions/_shared/http.ts`
  - `supabase/functions/_shared/auth.ts`
  - `supabase/functions/_shared/mail_dispatcher.ts`
  - `supabase/functions/_shared/email_templates/registration_invite.ts`
  - `supabase/functions/_shared/email_templates/referral_pin.ts`
  - `supabase/functions/send-registration-invite/index.ts`
  - `supabase/functions/send-referral-pin/index.ts`
  - `integrations/gas-mail-dispatcher/Code.gs`
  - `integrations/gas-mail-dispatcher/README.md`

## Verification Notes

- Local migration directory exists and contains one migration file.
- `supabase migration list` could not be fully verified against remote because credentials failed (`password authentication failed for user postgres`).
- Supabase edge mail flow now exists for Catatan Psikolog and is intended to replace direct SMTP sending from the Next.js user portal.
- GAS dispatcher contract mirrors Catatan Dokter architecture, but this repository remains a separate project with its own env/deploy/secrets.

## Operational Action

- Confirm remote DB credentials before any migration reconciliation or production push.
- Before deploying mail flow:
  - set Supabase edge env `MAIL_DISPATCHER_WEBHOOK_URL`
  - set Supabase edge env `MAIL_WEBHOOK_SECRET`
  - set Apps Script `MAIL_WEBHOOK_SECRET`
  - deploy `send-registration-invite`
  - deploy `send-referral-pin`
- Repo policy for this private project:
  - tracked env files may include active secrets and should be updated in-repo when environment config changes.
