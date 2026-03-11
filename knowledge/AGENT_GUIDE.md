# Agent Guide

## Tujuan
Menjaga perubahan agent tetap aman, repeatable, dan tidak merusak setup Supabase local.

## Aturan Aman
1. Dokumentasi baru taruh di `knowledge/`.
2. Jangan ubah port di `supabase/config.toml` tanpa persetujuan tim.
3. Jangan hapus `snapshot/` kecuali diminta eksplisit.
4. Jangan commit secret/token ke repo.
5. Untuk sinkronisasi, gunakan script/Makefile yang sudah ada.

## Command yang Direkomendasikan
- Export snapshot remote:
  - `./scripts/export_remote_database_snapshot.sh`
  - `./scripts/export_remote_storage_objects.sh`
  - `./scripts/export_remote_project_config.sh`
- Restore lokal:
  - `./scripts/restore_snapshot_to_local.sh`
- Verify:
  - `./scripts/verify_exact_counts.sh`
  - `./scripts/verify_snapshot_vs_local.sh`

## Jalur Cepat
- `make sync-all`
- `make sync-all-verbose`
