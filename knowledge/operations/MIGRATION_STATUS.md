# Migration Status (Catatan Psikolog Supabase)

Last audited: 2026-04-24 (Asia/Jakarta)

## Local Migration Folder

Path: `supabase/migrations`

**STATUS: CLEAN BASELINE RECONSTRUCTED**
On 2026-04-23, the migration history was consolidated into a single baseline to ensure environmental parity and a lean repository state.

Local files (active):
1. `20260424004623_document_therapy_table.sql` (Current Consolidated Baseline)

## Automated Workflow Status

- **Migration Automation**: Active via `scripts/apply_migration.sh`.
- **Knowledge Mirroring**: Active. Detailed Markdown history is generated in `knowledge/supabase_migrations/`.
- **Auto-Cleanup**: Active. `supabase migration squash` is triggered on every successful apply.
- **Frontend Sync**: Active. Automated `make sync-schema` for User and Admin portals on every DB change via Smart Discovery.

## Recent Logs
- 2026-04-24 20240101000000: Initial Baseline Reconstruction.
- 2026-04-24 20260424004623: Applied document_therapy_table (Latest Verified Baseline).
- 2026-04-24 20260424005831: Applied test_sync_final
- 2026-04-24 20260424010406: Applied final_verification_test
- 2026-04-24 20260424010519: Applied final_verification_verified
- 2026-04-24 20260424012443: Applied infrastructure_final_parity
- 2026-04-24 20260424012722: Applied landing_page_readiness
