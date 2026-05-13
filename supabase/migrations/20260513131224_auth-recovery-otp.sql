create table if not exists public.otp_verifications (
  id uuid default gen_random_uuid() primary key,
  email text not null,
  otp_code text not null,
  created_at timestamptz not null default timezone('utc'::text, now()),
  expires_at timestamptz not null,
  is_verified boolean default false,
  updated_at timestamptz default now(),
  created_by uuid,
  updated_by uuid
);

create index if not exists idx_otp_verifications_email_created_at
  on public.otp_verifications (email, created_at desc);

alter table public.otp_verifications enable row level security;

grant all on table public.otp_verifications to anon, authenticated, service_role;

create or replace function public.is_registered_profile_email(p_email text)
returns boolean
language sql
stable
set search_path to 'public'
as $$
  select exists (
    select 1
    from public.users u
    left join public.clinic_memberships cm on cm.user_id = u.id
    where lower(trim(coalesce(cm.email, ''))) = lower(trim(p_email))
      and u.role = 'clinic_staff'
    limit 1
  );
$$;

grant all on function public.is_registered_profile_email(text) to anon, authenticated, service_role;
