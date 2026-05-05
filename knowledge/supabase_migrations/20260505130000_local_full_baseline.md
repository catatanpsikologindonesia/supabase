# Migration: local_full_baseline

- **Timestamp**: 20260505130000
- **Applied At**: 2026-05-05 13:00:00

## Description
Rebuilt replay-clean local baseline after the 2026-05-05 patient-registration schema and RPC changes. This file replaces the temporary granular local-only migration chain so `supabase migration squash` can replay the active folder without warnings.

## Notes
- Source of truth for the SQL body is `supabase/migrations/20260505130000_local_full_baseline.sql`.
- This baseline is local-only until remote migration history is explicitly repaired and the backend changes are deployed remotely.
