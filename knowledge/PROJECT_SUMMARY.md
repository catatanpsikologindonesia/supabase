# Project Summary

**Project Name:** Catatan Psikolog Supabase Backend

## Purpose

Provide the shared database and backend execution layer for Catatan Psikolog.

## Current Components

- squashed SQL schema baseline in `supabase/migrations/`
- 23 Deno edge functions in `supabase/functions/`
- `_shared/` helper modules for auth, HTTP, mail, rate limiting, OTP, validation, and signature storage
- script-based local restore, parity, mirror, and deployment tooling in `scripts/`
- database snapshot artifacts in `snapshot/database/`

## Current Consumers

- `catatan-psikolog-user-portal`
- `catatan-psikolog-admin-portal`
- `catatan-psikolog-landing-page`

## Main Business Domains In Code

- clinic onboarding and lifecycle
- B2B invitation and agreement flows
- patient invitation and registration flows
- consent capture
- therapy session persistence
- referral creation and PIN verification
- OTP-based password reset support
- Indonesian address and reference data
