# Project Context Skill

## Read First

1. `README.md`
2. `knowledge/README.md`
3. `knowledge/CURRENT_STATE.md`
4. `knowledge/KNOWLEDGE_BASELINE.md`
5. `knowledge/architecture/REPOSITORY_MAP.md`
6. `knowledge/architecture/SUPABASE_PRODUCT_CONTRACT.md`

## Repository Summary

This repo is the Catatan Psikolog shared Supabase backend. The current codebase contains one squashed migration baseline, 23 edge functions, and a script-driven local/remote workflow for restore, mirror, verify, and deployment.

## Startup Protocol

- define the exact backend surface you are changing before editing
- use `make start-local` for normal local runtime
- use `make start-local-restore` when you need the committed DB snapshot restored first
- use `make verify-local-remote` before remote push decisions

## Hard Rules

1. Never use `supabase migration new`.
2. Use `bash scripts/apply_migration.sh "name" "SQL"` for schema changes.
3. Update knowledge docs when repository capabilities, commands, or operational behavior change.
4. Keep knowledge docs in English.

## Reference Paths

- `supabase/migrations/`
- `supabase/functions/`
- `scripts/`
- `snapshot/`
- `knowledge/`
