# Migration: clinic-full-address-rpc-parity

- **Timestamp**: 20260513150000
- **Applied At**: pending

## Description
Expand `create_clinic_with_owner` so Psikolog admin clinic onboarding also persists `full_address`, matching the frontend computed address contract.

## SQL Content
```sql
CREATE OR REPLACE FUNCTION public.create_clinic_with_owner(..., full_address text DEFAULT NULL::text, expired_date timestamptz DEFAULT NULL::timestamptz)
RETURNS jsonb
...
```
