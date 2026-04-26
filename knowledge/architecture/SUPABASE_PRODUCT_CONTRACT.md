# Supabase Product Contract

This document outlines the detailed consumption of this Supabase project (`CatatanPsikolog`) by the two frontend repositories within the Lintas Buana Sistem Digital organization.

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
