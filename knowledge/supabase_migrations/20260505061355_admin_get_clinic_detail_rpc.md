# Migration: admin_get_clinic_detail_rpc

- **Timestamp**: 20260505061355
- **Applied At**: 2026-05-05 06:13:55

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
CREATE OR REPLACE FUNCTION public.admin_get_clinic_detail(p_clinic_id uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER STABLE SET search_path TO 'public' AS $$ DECLARE v_result jsonb; BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RETURN jsonb_build_object('status','error','code','FORBIDDEN','message','Caller is not an LBSD admin.'); END IF; SELECT jsonb_build_object( 'clinic_id', c.id, 'clinic_name', c.name, 'clinic_slug', c.slug, 'is_active', c.is_active, 'owner_user_id', c.owner_user_id, 'created_at', c.created_at, 'memberships', COALESCE(( SELECT jsonb_agg( jsonb_build_object( 'membership_id', cm.id, 'user_id', cm.user_id, 'full_name', COALESCE(cm.full_name, SPLIT_PART(au.email, '@', 1)), 'email', COALESCE(cm.email, LOWER(au.email)), 'phone', cm.phone, 'is_owner', cm.is_owner, 'is_staff', cm.is_staff, 'is_practitioner', cm.is_practitioner, 'profession', cm.profession, 'is_active', cm.is_active, 'created_at', cm.created_at ) ORDER BY cm.is_owner DESC, cm.created_at ASC ) FROM public.clinic_memberships cm LEFT JOIN auth.users au ON au.id = cm.user_id WHERE cm.clinic_id = c.id ), '[]'::jsonb) ) INTO v_result FROM public.clinics c WHERE c.id = p_clinic_id; IF v_result IS NULL THEN RETURN jsonb_build_object('status','error','code','NOT_FOUND','message','Clinic not found.'); END IF; RETURN v_result; END; $$; GRANT EXECUTE ON FUNCTION public.admin_get_clinic_detail(uuid) TO authenticated;
```
