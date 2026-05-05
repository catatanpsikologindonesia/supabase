# Migration Status (Catatan Psikolog Supabase)

Last audited: 2026-05-05 (Asia/Jakarta)

## Local Migration Folder

Path: `supabase/migrations`

**STATUS: CLEAN BASELINE RECONSTRUCTED**
On 2026-04-23, the migration history was consolidated into a single baseline to ensure environmental parity and a lean repository state.

Local files (active):
1. `20260505061355_admin_get_clinic_detail_rpc.sql`

## Automated Workflow Status

- **Migration Automation**: Active via `scripts/apply_migration.sh`.
- **Knowledge Mirroring**: Active. Detailed Markdown history is generated in `knowledge/supabase_migrations/`.
- **Auto-Cleanup**: Active. `supabase migration squash` is triggered on every successful apply.
- **Frontend Sync**: Active. Automated `make sync-schema` for User and Admin portals on every DB change via Smart Discovery.
- **Current Status**: Replay-clean. `supabase migration squash` now replays the active folder successfully and rewrites the local baseline without warnings.

## Recent Logs
- 2026-04-24 20240101000000: Initial Baseline Reconstruction.
- 2026-04-24 20260424004623: Applied document_therapy_table (Latest Verified Baseline).
- 2026-04-24 20260424005831: Applied test_sync_final
- 2026-04-24 20260424010406: Applied final_verification_test
- 2026-04-24 20260424010519: Applied final_verification_verified
- 2026-04-24 20260424012443: Applied infrastructure_final_parity
- 2026-04-24 20260424012722: Applied landing_page_readiness
- 2026-04-26 20260426191130: Applied dummy_migration_test
- 2026-04-26 20260426191222: Applied dummy_migration_test
- 2026-04-26 20260426192022: Applied final_verification
- 2026-04-26 20260426194012: Applied bukti_nyata_sync
- 2026-04-26 20260426194207: Applied sync_verification_test
- 2026-04-26 20260426194402: Applied landing_page_sync_upgrade
- 2026-04-26 20260426194705: Applied final_health_check
- 2026-04-26 20260426195202: Applied final_final_check
- 2026-04-26 20260426200654: Applied heartbeat_verification
- 2026-04-26 20260426200950: Applied heartbeat_verification_fixed
- 2026-04-26 20260426214020: Applied test_sync_flow
- 2026-05-03 remote pull: invitation phone + contact_type support synchronized from staging (local-only parity refresh; no new authored migration).
- 2026-05-04 20260504004615: Applied address-tables-and-demo-requests (address hierarchy, demo_requests, edge rate limit infra).
- 2026-05-04 20260504004615: Applied address-tables-and-demo-requests
- 2026-05-04 20260504005710: Applied admin-profiles (admin auth table, helper RLS function, demo request read policy for admins).
- 2026-05-05 20260505045301: Applied admin_add_clinic_member_rpc
- 2026-05-05 20260505051338: Applied admin_list_clinics_rpc
- 2026-05-05 20260505061355: Applied admin_get_clinic_detail_rpc
- 2026-05-05 20260505061355: Manual squash verification completed successfully; active migration folder consolidated to a single replay-clean baseline.
