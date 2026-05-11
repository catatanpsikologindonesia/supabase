# Migration: clinic-lifecycle-b2b-schema-sync

- **Timestamp**: 20260512013433
- **Applied At**: 2026-05-12 01:34:34

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
ALTER TABLE clinics ADD COLUMN IF NOT EXISTS expired_date timestamp with time zone;
ALTER TABLE clinics ADD COLUMN IF NOT EXISTS is_agreement_signed boolean DEFAULT false;
ALTER TABLE clinics ADD COLUMN IF NOT EXISTS permit_number text;
ALTER TABLE clinics ADD COLUMN IF NOT EXISTS phone_number text;
CREATE TABLE IF NOT EXISTS b2b_agreement_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    title text NOT NULL,
    content text NOT NULL,
    is_active boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
CREATE TABLE IF NOT EXISTS b2b_invitations (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    clinic_id uuid NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
    token_hash text NOT NULL UNIQUE,
    template_id uuid REFERENCES b2b_agreement_templates(id),
    status text DEFAULT 'pending'::text CHECK (status IN ('pending', 'signed', 'expired', 'cancelled')),
    signed_at timestamp with time zone,
    signature_url text,
    signature_storage_path text,
    signed_by_name text,
    signed_by_position text,
    created_by uuid REFERENCES auth.users(id),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
ALTER TABLE b2b_agreement_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE b2b_invitations ENABLE ROW LEVEL SECURITY;
INSERT INTO storage.buckets (id, name, public) VALUES ('b2b-signatures', 'b2b-signatures', false) ON CONFLICT (id) DO NOTHING;
```
