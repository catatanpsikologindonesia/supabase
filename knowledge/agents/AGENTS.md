# Agent Protocol (Catatan Psikolog Supabase)

Follow the **Golden Rule of Knowledge** defined in the workspace root `PROJECT_CONTEXT.md`.

## Specific Backend Rules:
1. **Migrations**: NEVER use `supabase migration up` or create SQL files manually. Use `scripts/apply_migration.sh`.
2. **Sync**: Ensure both portals (User, Admin) are synced after any schema change.
3. **Audit**: Update `knowledge/operations/MIGRATION_STATUS.md` and `knowledge/CURRENT_STATE.md` after every architectural change.
4. **Master Data**: Protect Master Data snapshots. If the local DB is reset, restore from `snapshot/database/db_full_snapshot.dump` or use `make mirror-remote-to-local`.
