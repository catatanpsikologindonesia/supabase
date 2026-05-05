# Migration: admin_list_clinics_rpc

- **Timestamp**: 20260505051338
- **Applied At**: 2026-05-05 05:13:38

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
CREATE OR REPLACE FUNCTION public.admin_list_clinics() RETURNS TABLE ( clinic_id uuid, clinic_name text, clinic_slug text, is_active boolean, owner_name text, owner_email text, total_memberships bigint, active_memberships bigint, created_at timestamptz ) LANGUAGE sql SECURITY DEFINER STABLE SET search_path TO 'public' AS $$ SELECT c.id, c.name, c.slug::text, c.is_active, COALESCE( cm_owner.full_name, au.raw_user_meta_data->>'full_name', au.raw_user_meta_data->>'name', SPLIT_PART(au.email, '@', 1) ) AS owner_name, COALESCE(cm_owner.email, LOWER(au.email)) AS owner_email, COUNT(cm.id) AS total_memberships, COUNT(cm.id) FILTER (WHERE cm.is_active = true) AS active_memberships, c.created_at FROM public.clinics c LEFT JOIN LATERAL ( SELECT cm2.user_id, cm2.full_name, cm2.email FROM public.clinic_memberships cm2 WHERE cm2.clinic_id = c.id AND cm2.is_owner = true AND cm2.is_active = true ORDER BY cm2.created_at ASC LIMIT 1 ) cm_owner ON true LEFT JOIN auth.users au ON au.id = cm_owner.user_id LEFT JOIN public.clinic_memberships cm ON cm.clinic_id = c.id WHERE public.is_admin_at_least('STAFF') GROUP BY c.id, c.name, c.slug, c.is_active, c.created_at, cm_owner.full_name, cm_owner.email, au.raw_user_meta_data, au.email ORDER BY c.created_at DESC; $$; GRANT EXECUTE ON FUNCTION public.admin_list_clinics() TO authenticated;
```
