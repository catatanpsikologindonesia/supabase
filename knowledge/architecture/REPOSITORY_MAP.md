# Repository Map

## Top-Level Areas

- `supabase/`
  Supabase CLI workspace and runtime source of truth.
- `scripts/`
  Local stack, restore, mirror, verify, and deploy automation.
- `snapshot/`
  Generated dumps, schema snapshots, and verification reports.
- `integrations/gas-mail-dispatcher/`
  Google Apps Script integration for outbound email.
- `knowledge/`
  English-only documentation.

## Email-Relevant Paths

- `supabase/functions/send-patient-invitation/`
- `supabase/functions/send-referral-pin/`
- `supabase/functions/_shared/email_templates/patient_invitation.ts`
- `supabase/functions/_shared/email_templates/referral_pin.ts`
- `integrations/gas-mail-dispatcher/Code.gs`

## Operational Entry Points

- `Makefile`
- `scripts/start_local_stack.sh`
- `scripts/full_mirror_remote_to_local.sh`
- `scripts/verify_local_remote_diff.sh`
- `scripts/push_remote_changes.sh`
