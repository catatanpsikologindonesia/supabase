# RPC Naming Mapping

Last updated: 2026-05-22

## Status

Implemented for CP. Normalized functions are live and the old `rpc_*` functions have been dropped.

## Rename Map

| Current | Proposed |
|---|---|
| `rpc_admin_b2b_template_delete` | `delete_admin_b2b_template` |
| `rpc_admin_b2b_template_upsert` | `upsert_admin_b2b_template` |
| `rpc_admin_clinic_followups` | `list_admin_clinic_followups` |
| `rpc_admin_consent_template_delete` | `delete_admin_consent_template` |
| `rpc_admin_consent_template_upsert` | `upsert_admin_consent_template` |
| `rpc_admin_dashboard` | `get_admin_dashboard` |
| `rpc_admin_get_clinic_edit` | `get_admin_clinic_edit` |
| `rpc_admin_list_consent_templates` | `list_admin_consent_templates` |
| `rpc_admin_list_demo_requests` | `list_admin_demo_requests` |
| `rpc_admin_list_profiles` | `list_admin_profiles` |
| `rpc_admin_mark_demo_registered` | `mark_admin_demo_registered` |
| `rpc_admin_set_profile_active` | `set_admin_profile_active` |
| `rpc_admin_upsert_profile` | `upsert_admin_profile` |
| `rpc_create_patient_consent` | `create_patient_consent` |
| `rpc_get_active_consent_template` | `get_active_consent_template` |
| `rpc_get_admin_profile` | `get_admin_profile` |
| `rpc_get_portal_session` | `get_portal_session` |
| `rpc_mutate_reference_data` | Split into `create_reference_data`, `update_reference_data`, `delete_reference_data` if feasible; otherwise temporary `mutate_reference_data` |
| `rpc_patient_consents` | `list_patient_consents` |
| `rpc_portal_clinic_agreement` | `get_portal_clinic_agreement` |
| `rpc_portal_clinic_memberships` | `list_portal_clinic_memberships` |
| `rpc_portal_dashboard` | `get_portal_dashboard` |
| `rpc_portal_get_clinic_profile` | `get_portal_clinic_profile` |
| `rpc_portal_patient_workspace` | `get_portal_patient_workspace` |
| `rpc_portal_patients` | `list_portal_patients` |
| `rpc_portal_submit_clinic_agreement` | `submit_portal_clinic_agreement` |
| `rpc_portal_update_clinic_asset_paths` | `update_portal_clinic_asset_paths` |
| `rpc_update_patient_consent_signature` | `update_patient_consent_signature` |

## Functions To Keep As-Is

Already normalized functions should remain unchanged unless a later audit finds a business reason:

- `accept_patient_consent_by_token`
- `add_clinic_member_by_email`
- `admin_add_clinic_member`
- `admin_get_clinic_detail`
- `admin_list_clinics`
- `approve_clinic_extension_request`
- `create_clinic_with_owner`
- `create_patient_from_auth_user`
- `create_patient_invitation_with_schedule`
- `get_b2b_update_reminder`
- `get_clinics_with_pending_extension`
- `get_invitation_by_token`
- `get_reference_data`
- `reject_clinic_extension_request`
- `save_therapy_session_entry`
- `submit_patient_registration`
- `update_patient_registration_by_user_id`
- `verify_referral_pin`

## Execution Status

1. Create new normalized functions with identical bodies and grants. Done.
2. Regenerate schema types. Done.
3. Update CP admin portal RPC callsites. Done.
4. Update CP user portal RPC callsites. Done.
5. Verify no frontend `rpc_*` calls remain. Done.
6. Drop deprecated `rpc_*` functions. Done.
