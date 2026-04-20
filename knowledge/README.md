# Catatan Psikolog Supabase Knowledge

This folder contains focused operational, architectural, policy, and agent documentation for the Catatan Psikolog Supabase repository.

## Reading Order

1. `CURRENT_STATE.md`
2. `architecture/REPOSITORY_MAP.md`
3. `operations/LOCAL_STACK_AND_MIRROR.md`
4. `operations/DEPLOYMENT_AND_PARITY.md`
5. `integrations/EMAIL_DELIVERY.md`
6. `policies/SECURITY.md`
7. `policies/DOCUMENTATION_LANGUAGE_POLICY.md`
8. `agents/WORKING_RULES.md`

## Local Source Of Truth Rule

- Local repository state is the operational source of truth for push decisions.
- `make start-local` is expected to restore the local DB snapshot, storage bucket metadata, and binary storage snapshot from repository-owned artifacts.
- Before any push to Supabase cloud, agents must ensure local artifacts are current.
- If storage binaries changed locally, refresh the committed local snapshot with `make export-storage`.
- Remote-to-local mirror flows are recovery tools only and must not be used as the default response to parity mismatch when local intentional changes are in progress.
