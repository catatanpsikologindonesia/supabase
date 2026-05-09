# Migration: demo-requests-client-audit-columns

- **Timestamp**: 20260508114021
- **Applied At**: 2026-05-08 11:40:22

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
ALTER TABLE public.demo_requests ADD COLUMN IF NOT EXISTS client_ip text; ALTER TABLE public.demo_requests ADD COLUMN IF NOT EXISTS user_agent text;
```
