# Migration: demo-requests-delivery-registration-tracking

- **Timestamp**: 20260511042709
- **Applied At**: 2026-05-11 04:27:11

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
ALTER TABLE public.demo_requests ADD COLUMN IF NOT EXISTS email_delivery_status TEXT NOT NULL DEFAULT 'pending' CHECK (email_delivery_status IN ('pending','sent','failed')); ALTER TABLE public.demo_requests ADD COLUMN IF NOT EXISTS email_delivery_error TEXT; ALTER TABLE public.demo_requests ADD COLUMN IF NOT EXISTS registration_status TEXT NOT NULL DEFAULT 'not_registered' CHECK (registration_status IN ('registered','not_registered')); ALTER TABLE public.demo_requests ADD COLUMN IF NOT EXISTS registered_at TIMESTAMPTZ;
```
