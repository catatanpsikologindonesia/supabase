# Security Notes

## Operational Rules

- verify the target environment before every push
- avoid ad-hoc remote changes that bypass verification scripts
- keep edge mail secrets aligned between Supabase and Apps Script
- keep edge mail functions database-resolved by row identifiers instead of trusting frontend-composed recipient payloads
- verify authenticated ownership before dispatching invitation or referral email from an edge function

## Local Safety

- prefer `make start-local` for daily work because it is non-destructive
- use restore and mirror commands intentionally, not as a default startup path

## Mail Delivery Controls

- `send-patient-invitation` must resolve mail content from `patient_invitations`
- `send-referral-pin` must resolve mail content from `referrals_and_feedback` and related patient data
- frontend callers may provide navigation context such as base URLs and recipient timezone, but not authoritative recipient identity or message content
