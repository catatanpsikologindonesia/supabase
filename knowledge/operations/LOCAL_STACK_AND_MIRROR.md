# Local Stack And Mirror

## Daily Commands

```bash
make start-local
make prepare-local
make mirror-remote-to-local
```

## Recommended Usage

- use `make start-local` for normal development
- use `make prepare-local` only when you intentionally need restore + migration replay
- use `make mirror-remote-to-local` only when you intentionally want remote parity copied into local state

## Current Local Startup Behavior

`make start-local` now:

- loads `.env.local`
- restores the local DB snapshot by default
- validates the restored core-table counts against `snapshot/database/db_counts.txt` when that metadata exists
- starts the local Supabase stack
- restores binary storage snapshot from `snapshot/storage/objects/` when present
- cleans stale Docker containers for the current project when name conflicts occur
- retries startup once after cleanup
- treats repository-owned local artifacts as the startup baseline

## Snapshot Safety

- `scripts/pull_remote_snapshot.sh` now requires the resolved `SUPABASE_PROJECT_REF` to match the expected project ref before writing snapshot artifacts.
- remote snapshot pulls persist `snapshot/database/db_counts.txt` so later local restores can prove the restored row counts match the snapshot source.
- if `restore_local_db.sh` restores a dump but the core business-table counts do not match the snapshot metadata, the script exits non-zero instead of silently continuing with a corrupted local baseline.

## Local Ports

- API `55321`
- DB `55322`
- Studio `55323`
- Mailpit `55324`
