# Deployment And Parity

## Verification

Run the local source-of-truth runtime first:

```bash
make start-local
```

If local storage binaries changed, refresh the committed storage snapshot:

```bash
make export-storage
```

Then run:

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

1. start and validate the local source-of-truth runtime
2. refresh local storage snapshot if binary storage changed
3. verify local and remote parity
4. create a remote backup snapshot
5. push schema changes
6. deploy edge functions
7. run post-push verification
