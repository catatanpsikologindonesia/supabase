# Table Classification: Master vs User Tables

**Last updated:** 2026-05-20
**Product:** Catatan Psikolog
**Backend repo:** `Supabase/CatatanPsikolog`

---

## Definitions

**Master table** — data yang tidak bisa diubah dari user portal. Hanya admin portal yang bisa write, atau tidak ada portal yang bisa write (infra). Bisa dibaca dari kedua portal.

**User table** — data yang di-CRUD sepenuhnya dari user portal oleh klinik / staf / praktisi. Admin tidak punya UI untuk mengelolanya.

**Infra table** — table operasional sistem. Tidak di-CRUD langsung dari portal manapun.

---

## Master Tables

### Reference Data
Admin STAFF+ write. Dibaca semua (authenticated + anon untuk address).

| Table | Keterangan |
|---|---|
| `education` | Tingkat pendidikan |
| `marital_status` | Status perkawinan |
| `occupation` | Pekerjaan |
| `religion` | Agama |

### Address Hierarchy
Read-only untuk semua, termasuk anon.

| Table | Keterangan |
|---|---|
| `address_province` | Provinsi |
| `address_city` | Kota/kabupaten |
| `address_district` | Kecamatan |
| `address_subdistrict` | Kelurahan/desa |
| `address_postal_code` | Kode pos |

### B2B & Agreement
Admin-only write. Klinik hanya read atau update terbatas.

| Table | Keterangan |
|---|---|
| `b2b_agreement_templates` | Template perjanjian B2B — admin only write; anon bisa read `is_active = true` |
| `b2b_invitations` | Undangan tanda tangan — admin only write; anon bisa update pending→signed saat flow signing |
| `consent_templates` | Template informed consent pasien — admin only write; semua authenticated bisa read |

### Admin Internal
Internal LBSD only.

| Table | Keterangan |
|---|---|
| `admin_profiles` | Profil staff LBSD |
| `demo_requests` | Permintaan demo — anon insert, admin read/manage |

---

## User Tables

### Klinik

| Table | Keterangan |
|---|---|
| `clinics` | Data klinik — owner bisa update |
| `clinic_memberships` | Keanggotaan staf klinik — owner manage |
| `clinic_extension_requests` | Permintaan perpanjangan (**hybrid**: owner insert, admin approve/reject) |
| `b2b_agreements` | Perjanjian B2B yang ditandatangani (**hybrid**: owner insert saat signing, admin buat invitasi) |

### Pasien / Klien

| Table | Keterangan |
|---|---|
| `patients` | Row utama pasien |
| `patient_personal_data` | Data identitas pasien |
| `patient_family_data` | Data keluarga pasien |
| `patient_signatures` | Tanda tangan pasien — SELECT via ops; INSERT hanya via service_role/edge function |
| `clinic_patients` | Link pasien ke klinik |
| `patient_invitations` | Undangan registrasi pasien |

### Consent / Persetujuan

| Table | Keterangan |
|---|---|
| `patient_consents` | Persetujuan tindakan per pasien — scoped via `has_patient_access(patient_id)` |
| `patient_clinic_consents` | Consent pasien ke klinik — scoped via `has_ops_access(clinic_id)` |

### Session / Terapi

| Table | Keterangan |
|---|---|
| `appointments` | Jadwal sesi — ops klinik manage |
| `patient_visits` | Kunjungan pasien — ops klinik manage |
| `therapy_sessions` | Sesi terapi — **praktisi only** (`has_practitioner_access`) |
| `cognitive_assessments` | Asesmen kognitif per sesi — ops klinik manage |
| `developmental_history` | Riwayat perkembangan pasien — ops klinik manage |

### Referral

| Table | Keterangan |
|---|---|
| `referrals_and_feedback` | Referral dan feedback — **praktisi only** (`has_practitioner_access`) |

---

## Infra Tables

| Table | Keterangan |
|---|---|
| `users` | Row auth user — read own only; insert via edge function saat registrasi |
| `otp_verifications` | OTP reset password — service_role only via edge function |
| `edge_rate_limit_events` | Rate limiting — service_role only |

---

## Notes

- Semua master table bisa **dibaca** dari user portal (untuk populate dropdown, referensi, dll).
- User portal **tidak bisa write** ke master tables — RLS di database akan reject.
- `clinic_extension_requests` dan `b2b_agreements` adalah **hybrid**: insert dari user portal, approve/complete dari admin portal.
- `b2b_invitations` — admin create, tapi anon bisa update pending→signed saat proses tanda tangan sebelum klinik punya akun.
- `therapy_sessions` dan `referrals_and_feedback` — user table tapi dengan **akses lebih ketat**: hanya praktisi, bukan semua ops klinik.
- `patient_signatures` — tidak punya INSERT policy; insert harus lewat service_role atau edge function.
- `patient_consents` — RLS sudah diperbaiki di `20260520_fix-patient-consents-rls.sql` untuk menggunakan `has_patient_access(patient_id)` instead of `USING (true)`.
