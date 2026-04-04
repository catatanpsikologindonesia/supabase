# Local Stack And Mirror

## Daily Commands

```bash
make start-local
make prepare-local
make mirror-remote-to-local
```

## Recommended Usage

- use `make start-local` for normal development
- use `make prepare-local` when you need a reproducible baseline from the stored snapshot
- use `make mirror-remote-to-local` only when you intentionally want remote parity copied into local state

## Current Local Startup Behavior

`make start-local` now:

- loads `.env.local`
- starts the local Supabase stack
- cleans stale Docker containers for the current project when name conflicts occur
- retries startup once after cleanup
- preserves local database contents by default

## Local Ports

- API `55321`
- DB `55322`
- Studio `55323`
- Mailpit `55324`
