# Migration: clinic-full-address-parity

- **Timestamp**: 20260513144457
- **Applied At**: 2026-05-13 14:44:59

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
ALTER TABLE public.clinics ADD COLUMN IF NOT EXISTS full_address text;
```
