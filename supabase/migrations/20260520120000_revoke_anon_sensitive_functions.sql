-- Revoke anon EXECUTE from sensitive functions to fix security linter warnings
-- Date: 2026-05-20
-- Purpose: Fix anon_security_definer_function_executable warnings
-- Note: Must use explicit argument signatures for overloaded functions

-- Admin functions - should NOT be callable by anon
REVOKE EXECUTE ON FUNCTION public.admin_add_clinic_member(uuid, uuid, text, text, boolean, boolean, practitioner_profession) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_get_clinic_detail(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_list_clinics FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_clinics_with_pending_extension FROM anon;
REVOKE EXECUTE ON FUNCTION public.approve_clinic_extension_request(uuid, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.reject_clinic_extension_request(uuid) FROM anon;

-- Clinic management - should require auth
REVOKE EXECUTE ON FUNCTION public.add_clinic_member_by_email(uuid, text, boolean, boolean, practitioner_profession, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.create_clinic_with_owner(text, text, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.create_clinic_with_owner(text, text, uuid, text, text, text, text, text, text, text, text, text, text, timestamp with time zone) FROM anon;
REVOKE EXECUTE ON FUNCTION public.create_clinic_with_owner(text, text, uuid, text, text, text, text, text, text, text, text, text, text, text, timestamp with time zone) FROM anon;

-- Patient data - should require auth
REVOKE EXECUTE ON FUNCTION public.save_therapy_session_entry(uuid, uuid, uuid, date, time, text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.create_patient_invitation_with_schedule(uuid, uuid, text, text, text, date, time, integer, text, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.submit_patient_registration(text, jsonb) FROM anon;
REVOKE EXECUTE ON FUNCTION public.update_patient_registration_by_user_id(text, jsonb, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.create_patient_from_auth_user(text, uuid, text, text) FROM anon;

-- Internal helpers - should require auth
REVOKE EXECUTE ON FUNCTION public.handle_new_auth_user FROM anon;
REVOKE EXECUTE ON FUNCTION public.set_admin_profiles_audit_fields FROM anon;
REVOKE EXECUTE ON FUNCTION public.sync_clinic_membership_profile_defaults FROM anon;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable FROM anon;
REVOKE EXECUTE ON FUNCTION public.verify_referral_pin(uuid, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.edge_check_rate_limit(text, text, integer, integer) FROM anon;
