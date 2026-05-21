# Migration: security_hardening_rpc_migration

- **Timestamp**: 20260521123255
- **Applied At**: 2026-05-21 12:32:57

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
-- Additive security-hardening RPC migration.
-- Direct table grants are intentionally left unchanged until FE migration is complete.

CREATE OR REPLACE FUNCTION public.get_reference_data(table_name text)
RETURNS TABLE(id uuid, name text, order_index integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  CASE table_name
    WHEN 'religion' THEN
      RETURN QUERY SELECT r.id, r.name, r.order_index FROM public.religion r ORDER BY r.order_index ASC, r.name ASC;
    WHEN 'education' THEN
      RETURN QUERY SELECT e.id, e.name, e.order_index FROM public.education e ORDER BY e.order_index ASC, e.name ASC;
    WHEN 'occupation' THEN
      RETURN QUERY SELECT o.id, o.name, o.order_index FROM public.occupation o ORDER BY o.order_index ASC, o.name ASC;
    WHEN 'marital_status' THEN
      RETURN QUERY SELECT ms.id, ms.name, ms.order_index FROM public.marital_status ms ORDER BY ms.order_index ASC, ms.name ASC;
    ELSE
      RAISE EXCEPTION 'Unsupported reference table: %', table_name USING ERRCODE = '22023';
  END CASE;
END;
$$;

ALTER FUNCTION public.get_reference_data(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_reference_data(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_reference_data(text) TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.rpc_get_portal_session()
RETURNS TABLE(
  profile_role public.user_role,
  membership_id uuid,
  clinic_id uuid,
  is_owner boolean,
  is_staff boolean,
  is_practitioner boolean,
  profession public.practitioner_profession,
  is_active boolean,
  clinic jsonb
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
  SELECT
    u.role AS profile_role,
    cm.id AS membership_id,
    cm.clinic_id,
    cm.is_owner,
    cm.is_staff,
    cm.is_practitioner,
    cm.profession,
    cm.is_active,
    jsonb_build_object(
      'id', c.id,
      'name', c.name,
      'slug', c.slug,
      'is_active', c.is_active,
      'expired_date', c.expired_date,
      'is_agreement_signed', c.is_agreement_signed
    ) AS clinic
  FROM public.users u
  LEFT JOIN public.clinic_memberships cm
    ON cm.user_id = u.id
   AND cm.is_active = true
  LEFT JOIN public.clinics c
    ON c.id = cm.clinic_id
  WHERE u.id = auth.uid()
    AND u.role = 'clinic_staff'::public.user_role
  ORDER BY cm.is_owner DESC NULLS LAST, cm.created_at ASC NULLS LAST;
$$;

ALTER FUNCTION public.rpc_get_portal_session() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.rpc_get_portal_session() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rpc_get_portal_session() TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.rpc_get_admin_profile()
RETURNS TABLE(
  id uuid,
  full_name text,
  email text,
  phone text,
  admin_level public.admin_level_enum,
  is_active boolean
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
  SELECT ap.id, ap.full_name, ap.email, ap.phone, ap.admin_level, ap.is_active
  FROM public.admin_profiles ap
  WHERE ap.id = auth.uid()
    AND ap.is_active = true
  LIMIT 1;
$$;

ALTER FUNCTION public.rpc_get_admin_profile() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.rpc_get_admin_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rpc_get_admin_profile() TO authenticated, service_role;
```
