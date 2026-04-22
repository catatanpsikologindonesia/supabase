# Knowledge Baseline

This document serves as the foundational truth for the `Supabase/CatatanPsikolog` repository.

## System Architecture Overview
The Supabase project is the central data layer for the Catatan Psikolog ecosystem, which primarily serves the `catatan-psikolog-user-portal` Next.js frontend.

### Core Modules
- **PostgreSQL Database:** Handles multi-tenant clinic data, patient records, therapy sessions, and referrals.
- **Edge Functions:** Secure orchestration for email deliveries and complex logic operations.
- **Storage:** Snapshots and backups (limited remote functionality).

### Dependencies
- **Frontend Consumers:** See `architecture/SUPABASE_PRODUCT_CONTRACT.md`.
- **Integrations:** Email Dispatcher via Google Apps Script (see `architecture/EMAIL_DELIVERY.md`).
- **Operational Policy:** See `operations/DEPLOYMENT_AND_PARITY.md`.
