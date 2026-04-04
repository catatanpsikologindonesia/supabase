# Deployment And Parity

## Verification

Run:

```bash
make verify-local-remote
```

This validates the local state against the remote project across schema, functions, storage, auth, and cron.

## Deployment

Use:

```bash
make push-staging
make push-prod
```

`make push-remote` is the staging alias.

## Expected Deployment Flow

1. verify local and remote parity
2. create a remote backup snapshot
3. push schema changes
4. deploy edge functions
5. run post-push verification
