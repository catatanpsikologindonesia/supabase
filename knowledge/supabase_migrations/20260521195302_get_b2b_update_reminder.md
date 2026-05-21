# Migration: get_b2b_update_reminder

- **Timestamp**: 20260521195302
- **Applied At**: 2026-05-21 19:53:04

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
CREATE OR REPLACE FUNCTION public.get_b2b_update_reminder(p_clinic_id uuid) RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$ SELECT jsonb_build_object('should_show', COALESCE(t.updated_at > COALESCE(a.signed_at::timestamptz, '-infinity'::timestamptz) AND t.updated_at > now() - interval '7 days', false), 'message', 'Dokumen PKS telah diperbarui. Silakan tandatangani ulang di halaman Profil Klinik.') FROM public.b2b_agreement_templates t LEFT JOIN public.b2b_agreements a ON a.clinic_id = p_clinic_id AND a.id = (SELECT id FROM public.b2b_agreements WHERE clinic_id = p_clinic_id ORDER BY signed_at DESC LIMIT 1) WHERE t.is_active = true LIMIT 1; $$; REVOKE ALL ON FUNCTION public.get_b2b_update_reminder(uuid) FROM PUBLIC; GRANT EXECUTE ON FUNCTION public.get_b2b_update_reminder(uuid) TO authenticated;
```
