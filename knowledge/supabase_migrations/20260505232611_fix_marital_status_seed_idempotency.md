# Migration: fix_marital_status_seed_idempotency

- **Timestamp**: 20260505232611
- **Applied At**: 2026-05-05 23:26:11

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
WITH ranked AS ( SELECT id, lower(name) AS key_name, row_number() OVER (PARTITION BY lower(name) ORDER BY created_at ASC, id ASC) AS rn, first_value(id) OVER (PARTITION BY lower(name) ORDER BY created_at ASC, id ASC) AS keep_id FROM public.marital_status ), duplicates AS ( SELECT id AS duplicate_id, keep_id FROM ranked WHERE rn > 1 ) UPDATE public.patient_family_data pf SET marital_status_id = d.keep_id FROM duplicates d WHERE pf.marital_status_id = d.duplicate_id; WITH ranked AS ( SELECT id, lower(name) AS key_name, row_number() OVER (PARTITION BY lower(name) ORDER BY created_at ASC, id ASC) AS rn FROM public.marital_status ) DELETE FROM public.marital_status ms USING ranked r WHERE ms.id = r.id AND r.rn > 1; CREATE UNIQUE INDEX IF NOT EXISTS marital_status_name_unique_idx ON public.marital_status (lower(name));
```
