# Migration: clinic-registration-demo-parity

- **Timestamp**: 20260513133454
- **Applied At**: 2026-05-13 13:34:58

## Description
Add `registered_clinic_id` to `demo_requests` and expand `create_clinic_with_owner` so admin clinic registration persists full clinic metadata captured by the Psikolog admin portal.

## SQL Content
```sql
ALTER TABLE public.demo_requests
ADD COLUMN IF NOT EXISTS registered_clinic_id uuid REFERENCES public.clinics(id) ON DELETE SET NULL;

CREATE OR REPLACE FUNCTION public.create_clinic_with_owner(
  clinic_name text,
  clinic_slug text DEFAULT NULL::text,
  owner_user_id uuid DEFAULT auth.uid(),
  permit_number text DEFAULT NULL::text,
  owner_ktp_number text DEFAULT NULL::text,
  phone_number text DEFAULT NULL::text,
  address_line text DEFAULT NULL::text,
  rt_rw text DEFAULT NULL::text,
  province_name text DEFAULT NULL::text,
  city_name text DEFAULT NULL::text,
  district_name text DEFAULT NULL::text,
  subdistrict_name text DEFAULT NULL::text,
  postal_code text DEFAULT NULL::text,
  expired_date timestamptz DEFAULT NULL::timestamptz
) RETURNS jsonb
...
```
