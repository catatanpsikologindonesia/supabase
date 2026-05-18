# Deployment And Parity

## Current Verification Command

```bash
make verify-local-remote
```

This runs `scripts/verify_local_remote_diff.sh`.

## Current Verification Coverage

The verify script currently compares:

- public tables
- public SQL functions
- public views
- cron availability
- cron jobs
- storage objects
- auth user and identity counts
- remote versus local edge-function slugs

Verification reports are written into `snapshot/verification/`.

## Current Deployment Commands

```bash
make push-staging
make push-prod
make push-remote
```

`make push-remote` is the staging alias.

## Current Push Flow

`scripts/push_remote_changes.sh` currently:

1. loads local secrets and checks the expected project ref
2. ensures the Supabase CLI link matches the target project
3. runs local versus remote verification
4. pulls a remote backup snapshot before push
5. runs `supabase db push`
6. syncs extensions
7. syncs cron jobs
8. syncs storage binaries and bucket metadata
9. syncs storage policies
10. pushes project config where supported
11. pushes edge-function secrets from the selected env file
12. deploys every non-underscored edge-function directory
13. verifies remote function deployment
14. exports remote cron and extension snapshots back to the repo

## Current Staging Project Reference

- `ixwaaziifteubxkxtdwj`
