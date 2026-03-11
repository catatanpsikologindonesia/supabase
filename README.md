# CatatanPsikolog Supabase Mirror

Repositori ini menyimpan pipeline untuk menarik snapshot Supabase remote dan merestorasinya ke Supabase local dengan target parity setinggi mungkin (schema, data, role, RLS/policy, storage objects, dan konfigurasi proyek yang bisa diekspor via CLI).

## Tujuan

- Menyediakan workflow **remote -> snapshot -> local restore -> verification** yang konsisten.
- Menjaga hasil lokal sedekat mungkin dengan environment remote (1:1 untuk komponen yang dapat diekspor/restore).
- Menyediakan artefak audit agar tim bisa menelusuri status sinkronisasi.

## Cakupan 1:1

Yang dicakup pipeline ini:
- Database schema dan data (`public`, `auth`, `storage`, `realtime`, dan skema non-system lain yang bisa didump).
- Roles/globals (best-effort sesuai privilege koneksi dump).
- RLS/policies/functions yang ikut dalam dump schema.
- Storage objects (termasuk file biner) bila bucket/objek tersedia di remote.
- Metadata konfigurasi proyek yang tersedia dari Supabase CLI.

Yang **bukan** 1:1 penuh (batas platform/plan Supabase):
- Fitur managed yang plan-gated (contoh: custom domain, vanity subdomain).
- Komponen internal hosted infrastructure yang tidak diekspor sebagai artefak SQL/API publik.

## Struktur Direktori

- `scripts/` - script operasional export, restore, dan verifikasi.
- `snapshot/` - hasil export remote, hasil restore, dan laporan verifikasi.
- `supabase/` - project lokal Supabase CLI (`config.toml`, migrations/snippets lokal, dsb).
- `knowledge/` - dokumentasi tim/agent (tidak mempengaruhi runtime Supabase).
- `Makefile` - entry point command harian.

## Prasyarat

- Docker Desktop aktif.
- Supabase CLI sudah terpasang dan `supabase login` sudah dilakukan.
- Project remote sudah terhubung (`supabase link`) di konteks workdir ini.
- `libpq` binaries tersedia di:
  - `/opt/homebrew/opt/libpq/bin/psql`
  - `/opt/homebrew/opt/libpq/bin/pg_dump`
  - `/opt/homebrew/opt/libpq/bin/pg_dumpall`

## Command Utama

```bash
make help
make export-all
make restore
make verify
make sync-all
make sync-all-verbose
```

Penjelasan singkat:
- `make export-all`: export database, storage objects, dan config remote ke `snapshot/`.
- `make restore`: restore snapshot ke Supabase lokal.
- `make verify`: verifikasi exact row count remote vs local pada schema target.
- `make sync-all`: jalankan export + restore + verify end-to-end.
- `make sync-all-verbose`: sama seperti `sync-all` dengan log audit bertimestamp.

## Alur Kerja Rekomendasi

1. Jalankan sinkronisasi penuh:

```bash
make sync-all-verbose
```

2. Cek hasil verifikasi:
- `snapshot/verification/exact_count_mismatch_total.txt` harus `0`.
- `snapshot/verification/exact_count_compare.txt` untuk detail per tabel.
- `snapshot/verification/config_export_status.txt` untuk status export konfigurasi.
- `snapshot/verification/storage_export_status.txt` untuk status bucket/object export.

3. Jika mismatch, investigasi lewat log:
- `snapshot/verification/sync_all_verbose_latest.log`
- `snapshot/verification/local_restore.log`

## Catatan Operasional

- Script restore melakukan drop schema non-system target sebelum apply snapshot.
- Restore data dijalankan dengan replica mode untuk mengatasi FK cycle saat import.
- Untuk storage, pipeline menarik dan menyalin file biner (bukan metadata saja) jika bucket/object tersedia.

## Keamanan

- Jangan commit kredensial sensitif di luar kebutuhan operasional yang sudah disepakati tim.
- Review konten `snapshot/config/` dan `snapshot/database/` sebelum publish ke repositori publik.
- Folder `knowledge/` tidak boleh berisi secret.

## Troubleshooting Cepat

- Error binary `psql/pg_dump/pg_dumpall` tidak ditemukan:
  - Pastikan `libpq` terpasang dan path sesuai di script.
- Error Supabase CLI auth/link:
  - Ulangi `supabase login` dan validasi project link.
- Verifikasi mismatch:
  - Jalankan ulang `make sync-all-verbose`, lalu cek file compare/log di `snapshot/verification/`.

---

Maintainer notes: lihat dokumen di `knowledge/` untuk SOP tim, checklist operasional, dan panduan agent.
