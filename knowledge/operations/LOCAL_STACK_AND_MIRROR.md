# Local Stack And Mirror

## Main Commands

```bash
make start-local
make start-local-restore
make restore-local
make prepare-local
make mirror-remote-to-local
```

## Current Local Startup Behavior

`make start-local` runs `scripts/start_local_stack.sh`, which currently:

- prepares Colima-compatible Docker socket links
- loads `.env.local` when present
- cleans stale Supabase containers for this project id when needed
- starts the local Supabase stack
- preserves the current local DB by default
- optionally restores the committed DB snapshot when `AUTO_PREPARE_LOCAL_ON_START=1`
- ensures required schemas and grants exist locally
- restores local storage binaries snapshot
- prints local URLs and keys from runtime status where available

## Current Restore Behavior

`make restore-local` runs `scripts/restore_local_db.sh`, which currently:

- restores from `snapshot/database/db_full_snapshot.dump` by default
- restores inside the local Postgres container
- recreates required local schemas
- resyncs sequences
- optionally restores auth snapshot only with explicit opt-in
- verifies key table counts using `snapshot/database/db_counts.txt` when available

## Current Prepare Behavior

`make prepare-local` currently:

- parks migration SQL files temporarily
- restores the local DB snapshot
- re-applies parked migrations on top
- verifies key local artifacts
- restores the migration files back into place

## Current Mirror Behavior

`make mirror-remote-to-local` runs `scripts/full_mirror_remote_to_local.sh`, which currently:

- pulls remote snapshot artifacts
- starts the local stack
- restores the DB snapshot locally
- syncs auth
- syncs cron jobs
- syncs storage objects and metadata
- captures remote function metadata
- compares key remote and local counts

## Local Ports

- API `55321`
- DB `55322`
- Studio `55323`
- Inbucket `55324`
