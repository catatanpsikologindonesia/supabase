# Security Notes

## Current Operational Rules

- verify the target project ref before push operations
- avoid remote changes that bypass repository scripts
- keep mail webhook secrets aligned between Supabase and Apps Script
- prefer database-resolved recipients and payloads for mail flows
- enforce authenticated ownership checks in authenticated edge-function paths

## Current Local Safety Controls

- `make start-local` preserves the current local DB by default
- `make start-local-restore` restores the local DB snapshot intentionally
- `make db-reset` is guarded through `scripts/guard_destructive.sh`
- `scripts/pull_remote_snapshot.sh` and push workflows rely on project-ref checks

## Data And Secret Handling

Do not expose:

- service role keys
- mail webhook secrets
- remote database credentials
- patient data
- local env file contents

## Documentation Rule

Knowledge documents in `knowledge/` must remain in English.
