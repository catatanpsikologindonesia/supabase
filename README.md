# CatatanPsikolog Supabase Mirror

This repository contains an operational pipeline to mirror a remote Supabase project into a local Supabase stack with high parity across database, auth tables, RLS policies, functions (if any), storage objects, and exportable project configuration.

## Purpose

- Provide a repeatable `remote -> snapshot -> local restore -> verification` workflow.
- Keep local state as close as possible to remote for development, QA, and troubleshooting.
- Produce auditable artifacts for team validation and handover.

## Parity Scope

Included in parity workflow:
- Database schema and data for non-system schemas (including `public`, `auth`, `storage`, `realtime`, and others that are dumpable).
- Roles/globals snapshot (best effort based on effective dump privileges).
- RLS policies, triggers, and SQL functions captured in schema dumps.
- Storage object binary export/import when buckets/objects exist.
- Remote project configuration that is available via Supabase CLI APIs.

Not fully clonable 1:1 (platform constraints):
- Plan-gated hosted features (for example custom domains or vanity subdomains).
- Internal managed infrastructure details not exposed by Supabase dump/API interfaces.

## Repository Layout

- `scripts/`: export, restore, verification, and full-sync scripts.
- `snapshot/`: exported snapshots and verification outputs.
- `supabase/`: local Supabase project config/runtime context.
- `knowledge/`: team and agent documentation (outside runtime path).
- `Makefile`: primary command entrypoint.

## Prerequisites

- Docker Desktop running.
- Supabase CLI installed and authenticated (`supabase login`).
- Linked remote project in this workdir context.
- `libpq` binaries available at:
  - `/opt/homebrew/opt/libpq/bin/psql`
  - `/opt/homebrew/opt/libpq/bin/pg_dump`
  - `/opt/homebrew/opt/libpq/bin/pg_dumpall`

## Commands

```bash
make help
make export-all
make restore
make verify
make sync-all
make sync-all-verbose
```

Command summary:
- `make export-all`: export database, storage objects, and project configuration.
- `make restore`: restore snapshot into local Supabase.
- `make verify`: run exact table row-count comparison (remote vs local).
- `make sync-all`: run export + restore + verify end-to-end.
- `make sync-all-verbose`: same as `sync-all` with timestamped audit logging.

## Recommended Workflow

1. Run full sync:

```bash
make sync-all-verbose
```

2. Validate parity outputs:
- `snapshot/verification/exact_count_mismatch_total.txt` should be `0`.
- `snapshot/verification/exact_count_compare.txt` contains per-table results.
- `snapshot/verification/config_export_status.txt` contains config export status.
- `snapshot/verification/storage_export_status.txt` contains storage export status.

3. Investigate issues if mismatch is detected:
- `snapshot/verification/sync_all_verbose_latest.log`
- `snapshot/verification/local_restore.log`

## Security Notes

- Treat `snapshot/` data as potentially sensitive.
- Review content before publishing to any public repository.
- Do not place secrets in `knowledge/` documents.
- Follow [SECURITY.md](SECURITY.md) for vulnerability reporting and handling.
- Follow [REDACTION_POLICY.md](REDACTION_POLICY.md) before sharing artifacts outside the trusted team boundary.

## Repository Hygiene

This repository intentionally ignores local runtime and transient logs via `.gitignore`, including:
- `supabase/.temp/`
- verbose sync logs
- local restore logs
- temporary CLI error/log files

## CI Checks

GitHub Actions runs on `push` and `pull_request` to `main` and validates:
- Bash script syntax (`bash -n scripts/*.sh`)
- Repository structure and baseline files (`scripts/ci_validate_repo.sh`)

## Troubleshooting

- Missing `psql/pg_dump/pg_dumpall` binaries:
  - Install `libpq` and ensure expected paths are available.
- Supabase authentication or link failures:
  - Re-run `supabase login` and verify project link.
- Count mismatch after restore:
  - Re-run `make sync-all-verbose`, then inspect verification outputs in `snapshot/verification/`.

---

For operational SOP and team onboarding, see the files under `knowledge/`.
