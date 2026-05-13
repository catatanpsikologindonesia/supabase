# Supabase Product Contract

This document outlines the detailed consumption of this Supabase project (`CatatanPsikolog`) by the frontend repositories within the Lintas Buana Sistem Digital organization.

## 1. `catatan-psikolog-landing-page`

**Status:** Consumes **0** direct Supabase features.

**Reasoning:** The landing page is a static HTML/CSS marketing and public site. It does not initialize any Supabase client or make any direct database/RPC calls.

## 2. `catatan-psikolog-user-portal`

**Status:** Consumes multiple Supabase features extensively.

The user portal is a React + Vite SPA for clinic staff and patients. It directly communicates with this Supabase instance for authentication, database operations, and edge functions.

### Tables Consumed Directly (via Supabase JS Client)
- `appointments`
- `clinic_memberships`
- `clinic_patients`
- `cognitive_assessments`
- `developmental_history`
- `patient_family_data`
- `patient_personal_data`
- `patient_visits`
- `patients`
- `referrals_and_feedback`
- `therapy_sessions`
- `users`

### Tables Consumed Indirectly (via RPCs & Edge Functions)
- `clinics` (via `create_clinic_with_owner`)
- `patient_clinic_consents` (via `accept-patient-consent` etc.)
- `patient_invitations` (via invitation Edge Functions)

### Database Functions (RPCs) Consumed
- `add_clinic_member_by_email`
- `create_clinic_with_owner`
- `get_invitation_by_token`
- `save_therapy_session_entry`

### Edge Functions Consumed

#### Authenticated Functions
Frontend callers are located in `src/lib/edge-authenticated.ts`.
- `create-patient-invitation`
- `create-referral`

#### Public Functions
Frontend callers are located in `src/lib/edge-public.ts`.
- `accept-patient-consent`
- `submit-patient-registration`
- `verify-referral-pin`

#### Edge Functions Without Frontend Callers
- `send-patient-invitation`
- `send-referral-pin`
These functions are not directly invoked by the frontend code. They are reusable mail-delivery surfaces used by authenticated orchestration helpers and operational testing flows.

## 3. `catatan-psikolog-admin-portal`

**Status:** Consumes multiple Supabase features for internal clinic onboarding, lead review, and clinic lifecycle management.

The admin portal is a React + Vite SPA used by LBSD internal staff. It directly communicates with this Supabase instance for admin authentication, demo-request review, clinic registration, clinic detail, and clinic management operations.

### Tables Consumed Directly (via Supabase JS Client)
- `admin_profiles`
- `clinics`
- `demo_requests`

### Tables Consumed Indirectly (via RPCs & Edge Functions)
- `clinic_memberships` (via `create_clinic_with_owner`, `admin_add_clinic_member`, `admin_get_clinic_detail`)
- `users` (via `admin-create-clinic`, `admin-add-clinic-member`)

### Database Functions (RPCs) Consumed
- `admin_add_clinic_member`
- `admin_get_clinic_detail`
- `admin_list_clinics`
- `create_clinic_with_owner`
- `is_admin_at_least`

### Edge Functions Consumed
- `admin-create-clinic`
- `admin-add-clinic-member`
- `admin-update-clinic`
- `admin-toggle-clinic-active`
- `admin-get-b2b-templates`
- `admin-set-b2b-template-active`
- `create-b2b-invitation`
- `get-b2b-invitation`
- `submit-b2b-invitation`
- `extend-clinic-expiry`

### Admin Clinic Onboarding Contract

Manual clinic registration from `/dashboard/clinics/register` now depends on the following backend contract:

- The admin portal sends clinic metadata through `admin-create-clinic`:
  - `clinic_name`
  - `clinic_slug`
  - `permit_number`
  - `owner_ktp_number`
  - `phone_number`
  - `address_line`
  - `rt_rw`
  - `province_name`
  - `city_name`
  - `district_name`
  - `subdistrict_name`
  - `postal_code`
  - `full_address`
  - `expired_date`
  - `owner_email`
  - `owner_password`
  - `owner_full_name`
- `admin-create-clinic` forwards that payload into `create_clinic_with_owner(...)`.
- `create_clinic_with_owner(...)` persists the clinic metadata into `public.clinics` while also creating the owner membership.
- The admin portal now computes `full_address` client-side and sends it as part of the same onboarding contract so the backend stores both the structured address parts and a ready-to-display address summary.

### Demo Requests Linkage Contract

The admin portal demo-request flow also depends on these `demo_requests` fields:

- `message` — optional landing-page note shown on both sent and failed lead review pages
- `registration_status` — lead converted vs not converted
- `registered_at` — conversion timestamp
- `registered_clinic_id` — links the lead row to the created `public.clinics.id`

This linkage enables the demo-review flow to act as a seamless handoff into manual clinic onboarding while preserving lead-tracking state.
