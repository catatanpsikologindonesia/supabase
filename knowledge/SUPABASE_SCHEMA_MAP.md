# CatatanPsikolog Supabase Schema Map

Last updated: 2026-03-14
Source artifacts:

- `snapshot/database/schema_snapshot.sql`
- `snapshot/database/db_tables.txt`
- `snapshot/database/db_functions.txt`
- `snapshot/functions/functions_metadata.json`

## 1) Auth Layer

Auth identity source is `auth.users`, with related records in `auth.identities`.

Portal onboarding depends on a trigger/function chain:

- `public.handle_new_auth_user()`
- `public.sync_clinic_membership_profile_defaults()`

## 2) Public Schema Domains

### Clinic and membership

- `clinics`
- `clinic_memberships`
- `clinic_patients`

### User and patient profile

- `users`
- `patients`
- `patient_personal_data`
- `patient_family_data`

### Invitation, consent, and registration

- `patient_invitations`
- `patient_clinic_consents`

### Visits and clinical workflow

- `appointments`
- `patient_visits`
- `developmental_history`
- `cognitive_assessments`
- `therapy_sessions`
- `referrals_and_feedback`

## 3) Core RPC Contracts

Main RPCs currently exposed in `public`:

- `create_clinic_with_owner`
- `add_clinic_member_by_email`
- `create_patient_invitation_with_schedule`
- `get_invitation_by_token`
- `submit_patient_registration`
- `update_patient_registration_by_user_id`
- `accept_patient_consent_by_token`
- `verify_referral_pin`

Access helper RPC/functions:

- `has_active_membership`
- `has_owner_access`
- `has_ops_access`
- `has_practitioner_access`
- `has_patient_access`
- `is_portal_staff`

## 4) RLS Pattern

RLS is clinic-scoped with role helper checks:

- owner
- operations staff
- practitioner
- patient self-access

Policy SQL is available in:

- `snapshot/database/schema_snapshot.sql`

## 5) Storage and Jobs

Storage and cron schemas are mirrored as part of dump/snapshot.
Operational parity checks focus on business-facing domains and object inventories.

## 7) Mandatory Local Stack Schemas

To prevent PostgREST errors (PGRST002), the following schemas must exist in the local database:

- `public`: Core business logic.
- `graphql_public`: Required for PostgREST cache.
- `extensions`: Required for Supabase CLI and extra search paths.

> [!IMPORTANT]
> If these schemas are missing, PostgREST will fail to serve requests, leading to "Unauthorized" errors in the portal. Ensure the `ensure_system_schemas` migration is applied.

## 8) Agent Change Protocol

When agent modifies schema/function:

1. edit local mirror first
2. run `make mirror-remote-to-local` if baseline refresh is needed
3. run `make verify-local-remote`
4. run `make push-staging`
5. run `make push-prod` only after staging validation
