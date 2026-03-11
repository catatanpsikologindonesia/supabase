# Team Guide

## Workspace
- Root: `/Users/guntur/Lintas Buana Sistem Digital/Catatan Psikolog/Supabase/CatatanPsikolog`
- Folder penting:
  - `supabase/` untuk runtime local stack.
  - `scripts/` untuk export/restore/verify.
  - `snapshot/` untuk hasil sinkronisasi.
  - `knowledge/` untuk dokumentasi tim.

## Menjalankan Local Supabase
```bash
cd "/Users/guntur/Lintas Buana Sistem Digital/Catatan Psikolog/Supabase/CatatanPsikolog"
supabase start --exclude vector,logflare
```

Endpoint:
- API: `http://127.0.0.1:55321`
- Studio: `http://127.0.0.1:55323`
- DB: `postgresql://postgres:postgres@127.0.0.1:55322/postgres`

## Sinkronisasi Remote -> Local
- Standar:
```bash
make sync-all
```
- Dengan audit log timestamp:
```bash
make sync-all-verbose
```

## File Verifikasi
- `snapshot/verification/exact_count_compare.txt`
- `snapshot/verification/exact_count_mismatch_total.txt`
- `snapshot/verification/sync_all_verbose_latest.log`
