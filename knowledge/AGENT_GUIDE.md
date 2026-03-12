# Agent Notes

## Objective

Maintain strict local/remote parity for the CatatanPsikolog Supabase project and push safely.

## Do

- Use Make targets from repository root.
- Run parity check before push.
- Keep environment-specific pushes separated (`push-staging`, `push-prod`).
- Treat `supabase/functions/*` as deployable edge function source.

## Do not

- Do not commit secret files (`.env.local`, `.env.staging`, `.env.prod`).
- Do not bypass push preflight checks.
- Do not push directly to production before staging verification.

## Fast start

```bash
make verify-local-remote
make push-staging
```
