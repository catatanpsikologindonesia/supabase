# Operations Checklist

## Sebelum Sync
1. Pastikan login Supabase CLI valid (`supabase projects list`).
2. Pastikan koneksi internet stabil.
3. Pastikan disk cukup untuk dump SQL + log.

## Saat Sync
1. Jalankan `make sync-all-verbose`.
2. Tunggu sampai status `SYNC ALL VERBOSE COMPLETED`.
3. Cek ada/tidak error di `sync_all_verbose_latest.log`.

## Setelah Sync
1. Cek mismatch count:
   - `snapshot/verification/exact_count_mismatch_total.txt` harus `0`.
2. Cek status export config:
   - `snapshot/verification/config_export_status.txt`.
3. Cek status storage:
   - `snapshot/verification/storage_export_status.txt`.

## Troubleshooting Cepat
- Jika `supabase start` gagal karena port bentrok, cek port di `supabase/config.toml`.
- Jika timeout API Supabase, rerun command yang gagal.
- Jika ingin audit detail step-by-step, pakai file:
  - `snapshot/verification/sync_all_verbose_latest.log`.
