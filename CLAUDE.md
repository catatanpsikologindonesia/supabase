# Claude Code - Project Instructions

## Repository Role

This repository is the shared Supabase backend for Catatan Psikolog.

It owns:

- schema and RLS in `supabase/migrations/`
- edge functions in `supabase/functions/`
- local/remote automation in `scripts/`
- snapshots in `snapshot/`
- backend documentation in `knowledge/`

## Required Context Read Order

1. `../../../PROJECT_CONTEXT.md`
2. `../../PROJECT_CONTEXT.md`
3. `README.md`
4. `knowledge/README.md`
5. `knowledge/CURRENT_STATE.md`
6. `knowledge/KNOWLEDGE_BASELINE.md`
7. `knowledge/AGENTS.md`

## Current Backend Shape

- one squashed migration baseline in `supabase/migrations/`
- 23 edge functions in `supabase/functions/`
- shared auth, mail, rate-limit, validation, signature-storage, and template helpers in `_shared/`
- restore, mirror, verify, and push automation in `scripts/`

## Non-Negotiable Rules

- never use `supabase migration new`
- use `bash scripts/apply_migration.sh "name" "SQL"` for schema changes
- treat backend changes as shared contracts for user portal, admin portal, and landing page
- route outbound email through `_shared/mail_dispatcher.ts` and the GAS dispatcher
- keep knowledge documents in English
- all `.md` files in this repository must be written in English without exception

## Current Make Targets

```text
export-db
export-storage
restore-storage
export-config
export-all
restore
verify
verify-fast
sync-all
sync-all-verbose
pull-snapshot
start-local
start-local-restore
restore-local
prepare-local
db-reset
sync-auth
sync-cron
sync-cron-jobs
sync-extensions
sync-storage
sync-storage-policies
verify-local-remote
mirror-remote-to-local
guard-local-sync
knowledge-language-check
push-staging
push-prod
push-remote
guard-knowledge-sync
install-hooks
```

## Local Ports

- API `55321`
- DB `55322`
- Studio `55323`
- Inbucket `55324`

## Notes For Agents

- `make start-local` preserves the current local DB by default
- `make start-local-restore` restores the committed local DB snapshot before continuing
- `make verify-local-remote` compares tables, functions, views, cron, storage, auth counts, and edge-function slugs
- `make push-staging` targets project ref `ixwaaziifteubxkxtdwj`
