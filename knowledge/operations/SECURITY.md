# Security Notes

Last reviewed: 2026-04-27 (Asia/Jakarta)

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

## Redaction Rules

Do not share publicly:

- PAT paths and PAT contents
- service role credentials
- mail dispatcher secrets
- private patient data

Safe practice:

- redact secrets in logs before sharing them outside the private workspace
- summarize sensitive values instead of copying them verbatim

## Documentation Language Rules

All knowledge documents in this repository must be written in English.

Runtime content may remain in Indonesian where product behavior requires it,
such as user-facing email subjects and application copy.

Writing style:

- keep one file focused on one concern
- prefer clear headings and short sections
- avoid mixing architecture, troubleshooting, and release notes in one document
