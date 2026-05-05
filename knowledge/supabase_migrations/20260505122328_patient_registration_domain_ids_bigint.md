# Migration: patient_registration_domain_ids_bigint

- **Timestamp**: 20260505122328
- **Applied At**: 2026-05-05 12:23:28

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
ALTER TABLE public.patient_personal_data ALTER COLUMN province_domain_id TYPE bigint USING province_domain_id::bigint, ALTER COLUMN city_domain_id TYPE bigint USING city_domain_id::bigint, ALTER COLUMN district_domain_id TYPE bigint USING district_domain_id::bigint, ALTER COLUMN subdistrict_domain_id TYPE bigint USING subdistrict_domain_id::bigint, ALTER COLUMN postal_code_domain_id TYPE bigint USING postal_code_domain_id::bigint; ALTER TABLE public.patient_family_data ALTER COLUMN guardian_province_domain_id TYPE bigint USING guardian_province_domain_id::bigint, ALTER COLUMN guardian_city_domain_id TYPE bigint USING guardian_city_domain_id::bigint, ALTER COLUMN guardian_district_domain_id TYPE bigint USING guardian_district_domain_id::bigint, ALTER COLUMN guardian_subdistrict_domain_id TYPE bigint USING guardian_subdistrict_domain_id::bigint, ALTER COLUMN guardian_postal_code_domain_id TYPE bigint USING guardian_postal_code_domain_id::bigint;
```
