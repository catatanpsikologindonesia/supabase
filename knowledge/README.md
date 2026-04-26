# Catatan Psikolog Supabase Knowledge

This folder contains focused operational, architectural, policy, and agent documentation for the Catatan Psikolog Supabase repository.

## Reading Order

1. `PROJECT_SUMMARY.md`
2. `CURRENT_STATE.md`
3. `AGENTS.md`
4. `KNOWLEDGE_BASELINE.md`
5. `architecture/REPOSITORY_MAP.md`
6. `architecture/SUPABASE_PRODUCT_CONTRACT.md`
7. `architecture/EMAIL_DELIVERY.md`
8. `operations/LOCAL_STACK_AND_MIRROR.md`
9. `operations/DEPLOYMENT_AND_PARITY.md`
10. `operations/SECURITY.md`
11. `agents/WORKING_RULES.md`

## Local Source Of Truth Rule

- Local repository state is the operational source of truth for push decisions.
- `make start-local` preserves the current local DB state by default while restoring runtime-owned storage artifacts needed for local parity.
- `make start-local-restore` is the explicit path to restore the local DB baseline snapshot during startup.
- Before any push to Supabase cloud, agents must ensure local artifacts are current.
- If storage binaries changed locally, refresh the committed local snapshot with `make export-storage`.
- Remote-to-local mirror flows are recovery tools only and must not be used as the default response to parity mismatch when local intentional changes are in progress.
