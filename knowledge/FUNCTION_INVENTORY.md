# Function Inventory

Last updated: 2026-05-22

## Scope

This file lists the active `public` routine surface for the Catatan Psikolog backend after RPC normalization and frontend migration.

## Naming Status

- No `rpc_*` functions remain in the live local database.
- Frontend callsites in both active portals already use normalized names.

## Normalized Portal / Admin RPCs

- `get_admin_profile`
- `list_admin_profiles`
- `upsert_admin_profile`
- `set_admin_profile_active`
- `get_admin_dashboard`
- `list_admin_demo_requests`
- `mark_admin_demo_registered`
- `list_admin_consent_templates`
- `upsert_admin_consent_template`
- `delete_admin_consent_template`
- `upsert_admin_b2b_template`
- `delete_admin_b2b_template`
- `list_admin_clinic_followups`
- `get_admin_clinic_edit`
- `get_portal_session`
- `get_portal_dashboard`
- `get_portal_clinic_profile`
- `get_portal_clinic_agreement`
- `submit_portal_clinic_agreement`
- `update_portal_clinic_asset_paths`
- `list_portal_clinic_memberships`
- `list_portal_patients`
- `get_portal_patient_workspace`
- `list_patient_consents`
- `create_patient_consent`
- `update_patient_consent_signature`
- `get_active_consent_template`

## Existing Non-prefixed Business Functions

- `admin_add_clinic_member`
- `admin_get_clinic_detail`
- `admin_list_clinics`
- `approve_clinic_extension_request`
- `reject_clinic_extension_request`
- `create_clinic_with_owner`
- `create_patient_from_auth_user`
- `create_patient_invitation_with_schedule`
- `get_b2b_update_reminder`
- `get_clinics_with_pending_extension`
- `get_invitation_by_token`
- `get_reference_data`
- `save_therapy_session_entry`
- `submit_patient_registration`
- `update_patient_registration_by_user_id`
- `verify_referral_pin`

## Helper / Access Functions

- `has_active_membership`
- `has_ops_access`
- `has_owner_access`
- `has_patient_access`
- `has_practitioner_access`
- `is_admin_at_least`
- `is_portal_staff`
- `is_registered_profile_email`

## Infra / Trigger Functions

- `accept_patient_consent_by_token`
- `edge_check_rate_limit`
- `handle_new_auth_user`
- `rls_auto_enable`
- `set_admin_profiles_audit_fields`
- `sync_clinic_membership_profile_defaults`

## Notes

- This inventory reflects the active local database and normalized naming baseline.
- Use `snapshot/database/db_functions.txt` or `information_schema.routines` when exact signatures are needed.
