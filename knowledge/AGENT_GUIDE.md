# Agent Notes

## Objective

Maintain strict local/remote parity for the CatatanPsikolog Supabase project and push safely.

## Do

- Use Make targets from repository root.
- Run parity check before push.
- Keep environment-specific pushes separated (`push-staging`, `push-prod`).
- Treat `supabase/functions/*` as deployable edge function source.

## Do not

- Do not bypass push preflight checks.
- Do not push directly to production before staging verification.

## Secret handling

- This repository is private and environment files are tracked by design.
- When env/secrets change for an active workstream, update the relevant tracked files (`.env.local`, `.env.staging`, `.env.prod`) in the same branch.

## Fast start

```bash
make verify-local-remote
make push-staging
```
