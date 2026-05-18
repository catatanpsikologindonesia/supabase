# Supabase Product Contract

This document maps the current backend contract in this repository to its known product consumers.

## `catatan-psikolog-landing-page`

Current direct backend use from this repo is limited.

- this backend exposes `submit-demo-request`, which exists for landing-page lead capture workflows
- the landing page itself remains a separate repo and may consume the function through a browser or form integration path

## `catatan-psikolog-user-portal`

The user portal is a major direct consumer of this backend.

### Current Direct Table Families Used By The Portal Contract

- clinics and clinic memberships
- patients and clinic patients
- patient invitations and consent records
- patient personal, family, and developmental data
- patient visits and therapy sessions
- appointments
- cognitive assessments
- referrals and feedback
- users
- address and reference tables

### Current RPC Families Defined In The Backend For Portal Workflows

- invitation lookup and invitation-driven registration flows
- patient consent acceptance flows
- therapy session persistence
- referral PIN verification
- clinic membership and role access checks

### Current Edge Functions Relevant To User-Portal Flows

- `accept-patient-consent`
- `address-reference`
- `create-patient-invitation`
- `create-patient-invitation-v2`
- `create-referral`
- `reset-password`
- `send-otp`
- `send-patient-invitation`
- `send-referral-pin`
- `submit-patient-registration`
- `verify-otp`
- `verify-referral-pin`

## `catatan-psikolog-admin-portal`

The admin portal is a major direct consumer of this backend.

### Current Table Families Relevant To Admin Work

- admin profiles
- clinics
- clinic memberships
- B2B agreement templates, agreements, and invitations
- clinic extension requests
- consent templates
- demo requests
- address and reference tables

### Current Edge Functions Relevant To Admin Work

- `admin-add-clinic-member`
- `admin-create-clinic`
- `admin-get-b2b-templates`
- `admin-set-b2b-template-active`
- `admin-toggle-clinic-active`
- `admin-update-clinic`
- `create-b2b-invitation`
- `extend-clinic-expiry`
- `get-b2b-invitation`
- `submit-b2b-invitation`
- `submit-demo-request`

## Shared Contract Rules

- schema and edge-function changes in this repo should be treated as shared-contract changes
- outbound email content is backend-resolved and dispatched through the GAS webhook path
- local schema changes are expected to sync downstream through `make sync-schema` calls triggered by migration automation
