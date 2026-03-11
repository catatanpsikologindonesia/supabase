# Security Policy

This repository contains infrastructure and data-mirroring automation for Supabase environments. Treat all snapshot artifacts as sensitive by default.

## Supported Scope

Security reporting applies to:
- Scripts under `scripts/`
- Supabase local project configuration under `supabase/`
- Snapshot workflow outputs under `snapshot/`
- Documentation and operational guidance in repository root and `knowledge/`

## Reporting a Vulnerability

Please do not open public issues for suspected vulnerabilities or exposed secrets.

Use one of these channels:
- GitHub private vulnerability reporting (preferred) on this repository.
- If private reporting is unavailable, contact repository maintainers/organization admins directly.

Include:
- Impact summary
- Reproduction steps
- Affected files/paths
- Suggested remediation if available

## Response Expectations

Maintainers should:
- Acknowledge receipt as soon as possible.
- Triage and classify severity.
- Contain exposure (revoke/rotate credentials, restrict access, remove leaked artifacts).
- Publish a fix and, when relevant, notify downstream teams.

## Secret Handling Rules

- Never commit `.env` files or plaintext production credentials.
- Never publish access tokens, JWT secrets, database passwords, or private keys.
- Before pushing, review all `snapshot/` changes for accidental sensitive content.
- If a secret is exposed, rotate it immediately and replace the leaked value in history where required by policy.

## Data Sensitivity

Artifacts in `snapshot/database/`, `snapshot/config/`, and `snapshot/storage/` may contain sensitive data. Access should follow least-privilege principles and internal compliance requirements.

## Related Standard

See `REDACTION_POLICY.md` for repository-specific redaction and publication controls.
