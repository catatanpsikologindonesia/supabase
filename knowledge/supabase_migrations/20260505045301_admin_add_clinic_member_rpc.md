# Migration: admin_add_clinic_member_rpc

- **Timestamp**: 20260505045301
- **Applied At**: 2026-05-05 04:53:01

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
CREATE OR REPLACE FUNCTION public.admin_add_clinic_member( p_clinic_id uuid, p_user_id uuid, p_full_name text, p_email text, p_is_staff boolean DEFAULT false, p_is_practitioner boolean DEFAULT false, p_profession public.practitioner_profession DEFAULT NULL ) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$ DECLARE v_membership_id uuid; v_profession public.practitioner_profession; BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RETURN jsonb_build_object('status', 'error', 'code', 'FORBIDDEN', 'message', 'Caller is not an LBSD admin.'); END IF; IF NOT EXISTS (SELECT 1 FROM public.clinics WHERE id = p_clinic_id) THEN RETURN jsonb_build_object('status', 'error', 'code', 'CLINIC_NOT_FOUND', 'message', 'Clinic does not exist.'); END IF; v_profession := CASE WHEN p_is_practitioner THEN COALESCE(p_profession, 'psychologist'::public.practitioner_profession) ELSE NULL END; INSERT INTO public.users (id, role) VALUES (p_user_id, 'clinic_staff'::public.user_role) ON CONFLICT (id) DO UPDATE SET role = 'clinic_staff'::public.user_role, updated_at = now(); INSERT INTO public.clinic_memberships ( clinic_id, user_id, is_owner, is_staff, is_practitioner, profession, full_name, email, is_active ) VALUES ( p_clinic_id, p_user_id, false, p_is_staff, p_is_practitioner, v_profession, p_full_name, p_email, true ) ON CONFLICT (clinic_id, user_id) DO UPDATE SET is_staff = EXCLUDED.is_staff, is_practitioner = EXCLUDED.is_practitioner, profession = EXCLUDED.profession, full_name = EXCLUDED.full_name, email = EXCLUDED.email, is_active = true, updated_at = now() RETURNING id INTO v_membership_id; RETURN jsonb_build_object('status', 'success', 'message', 'Member added successfully.', 'membershipId', v_membership_id, 'userId', p_user_id); EXCEPTION WHEN others THEN RETURN jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Failed to add member: ' || SQLERRM); END; $$; GRANT EXECUTE ON FUNCTION public.admin_add_clinic_member(uuid, uuid, text, text, boolean, boolean, public.practitioner_profession) TO authenticated;
```
