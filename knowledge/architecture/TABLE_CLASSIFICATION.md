# Table Classification: Master vs User Tables

**Last updated:** 2026-05-20
**Product:** Catatan Psikolog
**Backend repo:** `Supabase/CatatanPsikolog`

---

## Definitions

**Master table** - data that cannot be modified from the user portal. Only the admin portal can write to it, or no portal can write to it at all in infra-owned cases. It can be read from both portals.

**User table** - data fully created, read, updated, and deleted from the user portal by clinics, staff, or practitioners. Admin does not have UI to manage it directly.

**Infra table** - system-operational table. It is not directly created, read, updated, or deleted from any portal.

---

## Master Tables

### Reference Data
Admin STAFF+ write. Readable by all relevant consumers, with anon access for address flows where applicable.

| Table | Description |
|---|---|
| `education` | Education level reference |
| `marital_status` | Marital status reference |
| `occupation` | Occupation reference |
| `religion` | Religion reference |

### Address Hierarchy
Read-only for all consumers, including anon.

| Table | Description |
|---|---|
| `address_province` | Province |
| `address_city` | City/regency |
| `address_district` | District |
| `address_subdistrict` | Subdistrict/village |
| `address_postal_code` | Postal code |

### B2B & Agreement
Admin-only write. Clinics are read-only or have tightly limited update behavior depending on the table.

| Table | Description |
|---|---|
| `b2b_agreement_templates` | B2B agreement template - admin-only write; anon can read rows where `is_active = true` |
| `b2b_invitations` | Signing invitation - admin-only write; anon can update pending to signed during the signing flow |
| `consent_templates` | Patient informed-consent template - admin-only write; all authenticated users can read |

### Admin Internal
Internal LBSD only.

| Table | Description |
|---|---|
| `admin_profiles` | LBSD staff profile |
| `demo_requests` | Demo request - anon inserts, admin reads and manages |

---

## User Tables

### Clinic

| Table | Description |
|---|---|
| `clinics` | Clinic record - owner can update |
| `clinic_memberships` | Clinic staff membership - owner manages |
| `clinic_extension_requests` | Extension request (**hybrid**: owner inserts, admin approves or rejects) |
| `b2b_agreements` | Signed B2B agreement (**hybrid**: owner inserts during signing, admin creates invitation) |

### Patient / Client

| Table | Description |
|---|---|
| `patients` | Core patient row |
| `patient_personal_data` | Patient identity data |
| `patient_family_data` | Patient family data |
| `patient_signatures` | Patient signature - SELECT via ops; INSERT only via service_role or edge function |
| `clinic_patients` | Patient-to-clinic link |
| `patient_invitations` | Patient registration invitation |

### Consent

| Table | Description |
|---|---|
| `patient_consents` | Patient treatment consent - scoped via `has_patient_access(patient_id)` |
| `patient_clinic_consents` | Patient-to-clinic consent - scoped via `has_ops_access(clinic_id)` |

### Session / Therapy

| Table | Description |
|---|---|
| `appointments` | Session schedule - clinic ops manage |
| `patient_visits` | Patient visit - clinic ops manage |
| `therapy_sessions` | Therapy session - **practitioner only** (`has_practitioner_access`) |
| `cognitive_assessments` | Cognitive assessment per session - clinic ops manage |
| `developmental_history` | Patient developmental history - clinic ops manage |

### Referral

| Table | Description |
|---|---|
| `referrals_and_feedback` | Referral and feedback - **practitioner only** (`has_practitioner_access`) |

---

## Infra Tables

| Table | Description |
|---|---|
| `users` | Auth user row - read own only; insert via edge function during registration |
| `otp_verifications` | Password-reset OTP records - service_role only via edge function |
| `edge_rate_limit_events` | Rate limiting - service_role only |

---

## Notes

- All master tables can be **read** from the user portal for dropdowns, references, and other lookup behavior.
- The user portal **cannot write** to master tables; database RLS rejects those writes.
- `clinic_extension_requests` and `b2b_agreements` are **hybrid** tables: inserts come from the user portal, while approval or completion happens from the admin portal.
- `b2b_invitations` is admin-created, but anon users can update pending to signed during the signing flow before the clinic has its own account.
- `therapy_sessions` and `referrals_and_feedback` are user tables with **stricter access**: practitioners only, not all clinic ops staff.
- `patient_signatures` has no INSERT policy; inserts must go through service_role or an edge function.
- `patient_consents` RLS was corrected in `20260520_fix-patient-consents-rls.sql` to use `has_patient_access(patient_id)` instead of `USING (true)`.
