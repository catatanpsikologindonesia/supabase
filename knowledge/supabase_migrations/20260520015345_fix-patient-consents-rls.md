# Migration: fix-patient-consents-rls

- **Timestamp**: 20260520015345
- **Applied At**: 2026-05-20 01:53:48

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql

-- Drop the over-permissive policies
DROP POLICY IF EXISTS "patient_consents_insert" ON "public"."patient_consents";
DROP POLICY IF EXISTS "patient_consents_select" ON "public"."patient_consents";
DROP POLICY IF EXISTS "patient_consents_update" ON "public"."patient_consents";

-- Replace with clinic-scoped policies using has_patient_access(patient_id)
CREATE POLICY "patient_consents_select"
  ON "public"."patient_consents"
  FOR SELECT TO "authenticated"
  USING ("public"."has_patient_access"("patient_id"));

CREATE POLICY "patient_consents_insert"
  ON "public"."patient_consents"
  FOR INSERT TO "authenticated"
  WITH CHECK ("public"."has_patient_access"("patient_id"));

CREATE POLICY "patient_consents_update"
  ON "public"."patient_consents"
  FOR UPDATE TO "authenticated"
  USING ("public"."has_patient_access"("patient_id"))
  WITH CHECK ("public"."has_patient_access"("patient_id"));

```
