# Catatan Psikolog Supabase Knowledge

Knowledge index for the Catatan Psikolog Supabase repository.

## Suggested Read Order

1. `PROJECT_SUMMARY.md`
2. `CURRENT_STATE.md`
3. `KNOWLEDGE_BASELINE.md`
4. `AGENTS.md`
5. `architecture/REPOSITORY_MAP.md`
6. `architecture/SUPABASE_PRODUCT_CONTRACT.md`
7. `architecture/EMAIL_DELIVERY.md`
8. `operations/LOCAL_STACK_AND_MIRROR.md`
9. `operations/DEPLOYMENT_AND_PARITY.md`
10. `operations/MIGRATION_STATUS.md`
11. `operations/SECURITY.md`
12. `agents/WORKING_RULES.md`
13. `agents/DB_AUTOMATION.md`
14. `agents/AGENTS.md`

## Current Knowledge Scope

- repo purpose and current backend shape
- active migration and snapshot model
- frontend contract boundaries
- local restore, mirror, verify, and push workflows
- email delivery path and security expectations

## Repository Truth Rule

- current code under `supabase/`, `scripts/`, and `snapshot/` is the source of truth for this repo
- knowledge files should describe current code only
- if backend behavior changes, update the matching knowledge file in the same change set
