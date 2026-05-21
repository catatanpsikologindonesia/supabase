# Migration: rpc_portal_update_clinic_asset_paths

- **Timestamp**: 20260521210149
- **Applied At**: 2026-05-21 21:01:51

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
CREATE OR REPLACE FUNCTION public.rpc_portal_update_clinic_asset_paths(p_clinic_id uuid, p_profile_picture_path text DEFAULT NULL, p_stamp_path text DEFAULT NULL, p_signature_path text DEFAULT NULL) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ BEGIN IF NOT public.has_active_membership(p_clinic_id) THEN RAISE EXCEPTION 'Clinic access required' USING ERRCODE = '42501'; END IF; UPDATE public.clinics SET profile_picture_path = COALESCE(p_profile_picture_path, profile_picture_path), stamp_path = COALESCE(p_stamp_path, stamp_path), signature_path = COALESCE(p_signature_path, signature_path), updated_at = now() WHERE id = p_clinic_id; END; $$; REVOKE ALL ON FUNCTION public.rpc_portal_update_clinic_asset_paths(uuid, text, text, text) FROM PUBLIC; GRANT EXECUTE ON FUNCTION public.rpc_portal_update_clinic_asset_paths(uuid, text, text, text) TO authenticated;
```
