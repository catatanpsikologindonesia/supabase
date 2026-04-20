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
- starts the local Supabase stack
- restores binary storage snapshot from `snapshot/storage/objects/` when present
- cleans stale Docker containers for the current project when name conflicts occur
- retries startup once after cleanup
- treats repository-owned local artifacts as the startup baseline

## Local Ports

- API `55321`
- DB `55322`
- Studio `55323`
- Mailpit `55324`
