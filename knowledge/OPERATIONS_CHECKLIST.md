# Pre-Push Checklist

Use this checklist before running `make push-staging` or `make push-prod`.

## Mandatory checks

- [ ] `make verify-local-remote` returns `VERIFY OK` (or mismatch is understood and intentional)
- [ ] Correct target env file exists:
  - staging: `.env.staging`
  - production: `.env.prod`
- [ ] `SUPABASE_PROJECT_REF` matches intended target
- [ ] Edge function source changes are committed under `supabase/functions/*`
- [ ] No secrets are staged in git (`.env.*`, PAT files)

## Command sequence

```bash
make verify-local-remote
make push-staging
```

If staging is good:

```bash
make push-prod
```

## If mismatch appears

1. Read generated diff files under `snapshot/verification/verify_local_remote_<timestamp>/`
2. Decide whether mismatch is expected
3. If expected, continue push with explicit confirmation
4. If unexpected, re-run mirror sync first:

```bash
make mirror-remote-to-local
```
