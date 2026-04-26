


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."adhd_indication" AS ENUM (
    'possible_adhd',
    'not_adhd'
);


ALTER TYPE "public"."adhd_indication" OWNER TO "postgres";


CREATE TYPE "public"."appointment_status" AS ENUM (
    'scheduled',
    'completed',
    'cancelled'
);


ALTER TYPE "public"."appointment_status" OWNER TO "postgres";


CREATE TYPE "public"."autism_indication" AS ENUM (
    'high_risk',
    'low_risk',
    'other_disorder',
    'borderline_normal'
);


ALTER TYPE "public"."autism_indication" OWNER TO "postgres";


CREATE TYPE "public"."birth_process" AS ENUM (
    'normal',
    'sc',
    'assisted'
);


ALTER TYPE "public"."birth_process" OWNER TO "postgres";


CREATE TYPE "public"."consent_source" AS ENUM (
    'registration_wizard',
    'invite_consent_page',
    'backfill'
);


ALTER TYPE "public"."consent_source" OWNER TO "postgres";


CREATE TYPE "public"."patient_invitation_flow" AS ENUM (
    'registration_required',
    'consent_required',
    'info_only'
);


ALTER TYPE "public"."patient_invitation_flow" OWNER TO "postgres";


CREATE TYPE "public"."patient_invitation_used_reason" AS ENUM (
    'registration_completed',
    'consent_accepted',
    'info_only_notified',
    'superseded',
    'expired',
    'cancelled'
);


ALTER TYPE "public"."patient_invitation_used_reason" OWNER TO "postgres";


CREATE TYPE "public"."practitioner_profession" AS ENUM (
    'psychologist',
    'counselor',
    'other'
);


ALTER TYPE "public"."practitioner_profession" OWNER TO "postgres";


CREATE TYPE "public"."user_role" AS ENUM (
    'admin',
    'psychologist',
    'patient',
    'clinic_staff'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE TYPE "public"."visit_status" AS ENUM (
    'scheduled',
    'in_progress',
    'completed',
    'cancelled'
);


ALTER TYPE "public"."visit_status" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "consent_ip" "text" DEFAULT NULL::"text", "consent_user_agent" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  invitation_row public.patient_invitations%rowtype;
  clinic_patient_id_value uuid;
  practitioner_membership_id_value uuid;
  appointment_id_value uuid;
  visit_id_value uuid;
  session_start_at_value timestamptz;
  session_end_at_value timestamptz;
  consent_text_value text := 'Saya menyetujui berbagi data medis saya dengan klinik tujuan untuk keperluan layanan psikologi.';
begin
  if invite_token is null or btrim(invite_token) = '' then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_TOKEN', 'message', 'Token undangan tidak valid.');
  end if;

  select *
  into invitation_row
  from public.patient_invitations pi
  where pi.token = invite_token
  limit 1
  for update;

  if not found then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_NOT_FOUND', 'message', 'Undangan tidak ditemukan.');
  end if;

  if invitation_row.flow <> 'consent_required'::public.patient_invitation_flow then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_FLOW', 'message', 'Undangan ini tidak menggunakan flow persetujuan data.');
  end if;

  if coalesce(invitation_row.is_used, false) then
    if invitation_row.used_reason = 'superseded'::public.patient_invitation_used_reason then
      return jsonb_build_object('status', 'error', 'code', 'INVITATION_SUPERSEDED', 'message', 'Link undangan ini sudah diganti dengan undangan terbaru.');
    end if;

    return jsonb_build_object('status', 'error', 'code', 'INVITATION_USED', 'message', 'Link undangan sudah digunakan.');
  end if;

  if invitation_row.expires_at < now() then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_EXPIRED', 'message', 'Link undangan sudah kedaluwarsa.');
  end if;

  if invitation_row.target_patient_id is null then
    return jsonb_build_object('status', 'error', 'code', 'PATIENT_NOT_FOUND', 'message', 'Data pasien untuk undangan ini belum tersedia.');
  end if;

  if invitation_row.clinic_id is null then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_CLINIC_REQUIRED', 'message', 'Undangan belum terhubung ke klinik.');
  end if;

  practitioner_membership_id_value := invitation_row.practitioner_membership_id;
  if practitioner_membership_id_value is null
     or not exists (
      select 1
      from public.clinic_memberships cm
      where cm.id = practitioner_membership_id_value
        and cm.is_active = true
        and cm.is_practitioner = true
     ) then
    select cm.id
    into practitioner_membership_id_value
    from public.clinic_memberships cm
    where cm.clinic_id = invitation_row.clinic_id
      and cm.is_active = true
      and cm.is_practitioner = true
    order by cm.is_owner desc, cm.created_at asc
    limit 1;
  end if;

  if practitioner_membership_id_value is null then
    return jsonb_build_object('status', 'error', 'code', 'NO_PRACTITIONER', 'message', 'Tidak ada practitioner aktif pada klinik ini.');
  end if;

  if not exists (
    select 1
    from public.patient_clinic_consents pcc
    where pcc.clinic_id = invitation_row.clinic_id
      and pcc.patient_id = invitation_row.target_patient_id
      and pcc.revoked_at is null
  ) then
    insert into public.patient_clinic_consents (
      clinic_id,
      patient_id,
      invitation_id,
      consent_version,
      consent_text,
      source,
      accepted_at,
      accepted_ip,
      accepted_user_agent,
      created_at,
      updated_at
    )
    values (
      invitation_row.clinic_id,
      invitation_row.target_patient_id,
      invitation_row.id,
      'v1',
      consent_text_value,
      'invite_consent_page'::public.consent_source,
      now(),
      nullif(consent_ip, ''),
      nullif(consent_user_agent, ''),
      now(),
      now()
    );
  end if;

  insert into public.clinic_patients (clinic_id, patient_id, mrn, is_active)
  values (
    invitation_row.clinic_id,
    invitation_row.target_patient_id,
    coalesce(
      (select p.mrn from public.patients p where p.id = invitation_row.target_patient_id),
      'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6))
    ),
    true
  )
  on conflict (clinic_id, patient_id) do update
  set is_active = true,
      updated_at = now()
  returning id into clinic_patient_id_value;

  appointment_id_value := invitation_row.appointment_id;

  if appointment_id_value is null then
    session_start_at_value := coalesce(
      invitation_row.session_start_at,
      date_trunc('day', now()) + interval '1 day' + interval '9 hours'
    );
    session_end_at_value := coalesce(
      invitation_row.session_end_at,
      session_start_at_value + interval '45 minutes'
    );

    insert into public.appointments (
      clinic_id,
      clinic_patient_id,
      patient_id,
      practitioner_membership_id,
      start_time,
      end_time,
      status,
      notes
    )
    values (
      invitation_row.clinic_id,
      clinic_patient_id_value,
      invitation_row.target_patient_id,
      practitioner_membership_id_value,
      session_start_at_value,
      session_end_at_value,
      'scheduled',
      'Auto-created after consent acceptance'
    )
    returning id into appointment_id_value;
  end if;

  select pv.id
  into visit_id_value
  from public.patient_visits pv
  where pv.appointment_id = appointment_id_value
  limit 1;

  if visit_id_value is null then
    insert into public.patient_visits (
      clinic_id,
      clinic_patient_id,
      patient_id,
      appointment_id,
      status
    )
    values (
      invitation_row.clinic_id,
      clinic_patient_id_value,
      invitation_row.target_patient_id,
      appointment_id_value,
      'scheduled'
    )
    returning id into visit_id_value;
  end if;

  update public.patient_invitations
  set is_used = true,
      used_at = now(),
      used_reason = 'consent_accepted'::public.patient_invitation_used_reason,
      appointment_id = appointment_id_value,
      practitioner_membership_id = practitioner_membership_id_value
  where id = invitation_row.id;

  return jsonb_build_object(
    'status', 'success',
    'message', 'Persetujuan data berhasil. Jadwal sesi sudah dikonfirmasi.',
    'patientId', invitation_row.target_patient_id,
    'clinicId', invitation_row.clinic_id,
    'appointmentId', appointment_id_value,
    'visitId', visit_id_value
  );
exception
  when others then
    return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal memproses persetujuan: ' || sqlerrm);
end;
$$;


ALTER FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "consent_ip" "text", "consent_user_agent" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_clinic_member_by_email"("target_clinic_id" "uuid", "member_email" "text", "assign_staff" boolean DEFAULT true, "assign_practitioner" boolean DEFAULT false, "member_profession" "public"."practitioner_profession" DEFAULT NULL::"public"."practitioner_profession", "actor_user_id" "uuid" DEFAULT "auth"."uid"()) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  normalized_email text;
  target_user_id uuid;
  membership_id uuid;
  final_profession public.practitioner_profession;
begin
  if actor_user_id is null then
    return jsonb_build_object(
      'status', 'error',
      'code', 'AUTH_REQUIRED',
      'message', 'Sesi login tidak ditemukan.'
    );
  end if;

  if target_clinic_id is null then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVALID_CLINIC',
      'message', 'Klinik aktif tidak valid.'
    );
  end if;

  if not exists (
    select 1
    from public.clinic_memberships cm
    where cm.user_id = actor_user_id
      and cm.clinic_id = target_clinic_id
      and cm.is_active = true
      and cm.is_owner = true
  ) then
    return jsonb_build_object(
      'status', 'error',
      'code', 'FORBIDDEN',
      'message', 'Hanya owner klinik yang dapat menambah member.'
    );
  end if;

  normalized_email := lower(btrim(member_email));
  if normalized_email is null or normalized_email = '' then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVALID_EMAIL',
      'message', 'Email member wajib diisi.'
    );
  end if;

  select au.id
  into target_user_id
  from auth.users au
  where lower(au.email) = normalized_email
  limit 1;

  if target_user_id is null then
    return jsonb_build_object(
      'status', 'error',
      'code', 'AUTH_USER_NOT_FOUND',
      'message', 'Akun belum terdaftar di Supabase Auth.'
    );
  end if;

  if assign_practitioner = true then
    final_profession := coalesce(member_profession, 'psychologist'::public.practitioner_profession);
  else
    final_profession := null;
  end if;

  insert into public.users (id, role)
  values (target_user_id, 'clinic_staff'::public.user_role)
  on conflict (id) do update
  set role = 'clinic_staff'::public.user_role,
      updated_at = now();

  insert into public.clinic_memberships (
    clinic_id,
    user_id,
    is_owner,
    is_staff,
    is_practitioner,
    profession,
    is_active
  )
  values (
    target_clinic_id,
    target_user_id,
    false,
    coalesce(assign_staff, false),
    coalesce(assign_practitioner, false),
    final_profession,
    true
  )
  on conflict (clinic_id, user_id) do update
  set is_staff = excluded.is_staff,
      is_practitioner = excluded.is_practitioner,
      profession = excluded.profession,
      is_active = true,
      updated_at = now()
  returning id into membership_id;

  return jsonb_build_object(
    'status', 'success',
    'message', 'Member klinik berhasil ditambahkan.',
    'membershipId', membership_id,
    'userId', target_user_id
  );
exception
  when others then
    return jsonb_build_object(
      'status', 'error',
      'code', 'SERVER_ERROR',
      'message', 'Gagal menambah member: ' || sqlerrm
    );
end;
$$;


ALTER FUNCTION "public"."add_clinic_member_by_email"("target_clinic_id" "uuid", "member_email" "text", "assign_staff" boolean, "assign_practitioner" boolean, "member_profession" "public"."practitioner_profession", "actor_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text" DEFAULT NULL::"text", "owner_user_id" "uuid" DEFAULT "auth"."uid"()) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  normalized_name text;
  base_slug text;
  final_slug text;
  suffix int := 0;
  created_clinic_id uuid;
  existing_clinic_id uuid;
  owner_membership_id uuid;
begin
  if owner_user_id is null then
    return jsonb_build_object(
      'status', 'error',
      'code', 'AUTH_REQUIRED',
      'message', 'Akun login tidak ditemukan.'
    );
  end if;

  normalized_name := nullif(btrim(clinic_name), '');
  if normalized_name is null then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVALID_CLINIC_NAME',
      'message', 'Nama klinik wajib diisi.'
    );
  end if;

  base_slug := nullif(regexp_replace(lower(coalesce(clinic_slug, normalized_name)), '[^a-z0-9]+', '-', 'g'), '');
  base_slug := trim(both '-' from coalesce(base_slug, 'clinic'));
  if base_slug = '' then
    base_slug := 'clinic';
  end if;

  final_slug := base_slug;

  while exists (select 1 from public.clinics c where c.slug = final_slug) loop
    suffix := suffix + 1;
    final_slug := base_slug || '-' || suffix::text;
  end loop;

  insert into public.users (id, role)
  values (owner_user_id, 'clinic_staff'::public.user_role)
  on conflict (id) do update
  set role = 'clinic_staff'::public.user_role,
      updated_at = now();

  select cm.clinic_id, cm.id
  into existing_clinic_id, owner_membership_id
  from public.clinic_memberships cm
  where cm.user_id = owner_user_id
    and cm.is_owner = true
    and cm.is_active = true
  order by cm.created_at asc
  limit 1;

  if existing_clinic_id is not null then
    return jsonb_build_object(
      'status', 'success',
      'message', 'Owner sudah memiliki klinik aktif.',
      'clinicId', existing_clinic_id,
      'membershipId', owner_membership_id
    );
  end if;

  insert into public.clinics (name, slug, owner_user_id)
  values (normalized_name, final_slug, owner_user_id)
  returning id into created_clinic_id;

  insert into public.clinic_memberships (
    clinic_id,
    user_id,
    is_owner,
    is_staff,
    is_practitioner,
    profession,
    is_active
  )
  values (
    created_clinic_id,
    owner_user_id,
    true,
    true,
    true,
    'psychologist'::public.practitioner_profession,
    true
  )
  returning id into owner_membership_id;

  return jsonb_build_object(
    'status', 'success',
    'message', 'Klinik berhasil dibuat.',
    'clinicId', created_clinic_id,
    'membershipId', owner_membership_id
  );
exception
  when others then
    return jsonb_build_object(
      'status', 'error',
      'code', 'SERVER_ERROR',
      'message', 'Gagal membuat klinik: ' || sqlerrm
    );
end;
$$;


ALTER FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_patient_from_auth_user"("auth_email" "text", "auth_user_id" "uuid", "invite_token" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  invitation_row public.patient_invitations%rowtype;
  auth_user_email text;
  patient_id_value uuid;
  mrn_value text;
  full_name_value text;
begin
  if invite_token is null or btrim(invite_token) = '' then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_TOKEN', 'message', 'Token registrasi tidak valid.');
  end if;

  if auth_user_id is null then
    return jsonb_build_object('status', 'error', 'code', 'AUTH_USER_REQUIRED', 'message', 'Akun login pasien tidak ditemukan.');
  end if;

  if auth_email is null or btrim(auth_email) = '' then
    return jsonb_build_object('status', 'error', 'code', 'AUTH_EMAIL_REQUIRED', 'message', 'Email akun login pasien tidak ditemukan.');
  end if;

  select *
  into invitation_row
  from public.patient_invitations
  where token = invite_token
  limit 1;

  if not found then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_NOT_FOUND', 'message', 'Undangan tidak ditemukan.');
  end if;

  if invitation_row.flow <> 'registration_required'::public.patient_invitation_flow then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_FLOW', 'message', 'Undangan ini tidak membutuhkan registrasi penuh.');
  end if;

  if invitation_row.clinic_id is null then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_CLINIC_REQUIRED', 'message', 'Undangan belum terhubung ke klinik.');
  end if;

  if coalesce(invitation_row.is_used, false) then
    if invitation_row.used_reason = 'superseded'::public.patient_invitation_used_reason then
      return jsonb_build_object('status', 'error', 'code', 'INVITATION_SUPERSEDED', 'message', 'Link undangan ini sudah diganti dengan undangan terbaru.');
    end if;

    return jsonb_build_object('status', 'error', 'code', 'INVITATION_USED', 'message', 'Link registrasi sudah digunakan.');
  end if;

  if invitation_row.expires_at < now() then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_EXPIRED', 'message', 'Link registrasi sudah kedaluwarsa.');
  end if;

  select au.email
  into auth_user_email
  from auth.users au
  where au.id = auth_user_id
  limit 1;

  if auth_user_email is null then
    return jsonb_build_object('status', 'error', 'code', 'AUTH_USER_NOT_FOUND', 'message', 'User auth pasien tidak ditemukan.');
  end if;

  if lower(btrim(auth_email)) <> lower(btrim(auth_user_email))
     or lower(btrim(auth_email)) <> lower(btrim(invitation_row.email)) then
    return jsonb_build_object('status', 'error', 'code', 'EMAIL_MISMATCH', 'message', 'Email akun tidak cocok dengan email undangan.');
  end if;

  insert into public.users (id, role)
  values (auth_user_id, 'patient'::public.user_role)
  on conflict (id) do update
    set role = case
      when public.users.role::text = 'clinic_staff' then public.users.role
      else 'patient'::public.user_role
    end,
    updated_at = now();

  select p.id
  into patient_id_value
  from public.patients p
  where p.user_id = auth_user_id
  limit 1;

  if patient_id_value is null then
    mrn_value := 'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
    full_name_value := coalesce(
      nullif(initcap(regexp_replace(split_part(invitation_row.email, '@', 1), '[._-]+', ' ', 'g')), ''),
      'Pasien Baru'
    );

    insert into public.patients (user_id, mrn, full_name, email, phone)
    values (auth_user_id, mrn_value, full_name_value, invitation_row.email, null)
    returning id into patient_id_value;
  end if;

  update public.patient_invitations
  set target_patient_id = coalesce(target_patient_id, patient_id_value)
  where id = invitation_row.id;

  return jsonb_build_object(
    'status', 'success',
    'message', 'Data pasien awal berhasil dibuat.',
    'patientId', patient_id_value,
    'clinicId', invitation_row.clinic_id
  );
exception
  when others then
    return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal menyiapkan data pasien: ' || sqlerrm);
end;
$$;


ALTER FUNCTION "public"."create_patient_from_auth_user"("auth_email" "text", "auth_user_id" "uuid", "invite_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_patient_invitation_with_schedule"("target_clinic_id" "uuid", "invited_by_membership_id" "uuid", "patient_email" "text", "session_date" "date", "session_time" time without time zone, "duration_minutes" integer DEFAULT 45, "session_timezone" "text" DEFAULT 'Asia/Jakarta'::"text", "invitation_ttl_hours" integer DEFAULT 72) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  normalized_email text;
  clinic_name_value text;
  auth_user_id_value uuid;
  patient_id_value uuid;
  practitioner_membership_id_value uuid;
  has_active_consent boolean := false;
  resolved_flow public.patient_invitation_flow;
  token_value text;
  expires_at_value timestamptz;
  session_timezone_value text;
  session_start_at_value timestamptz;
  session_end_at_value timestamptz;
  invitation_id_value uuid;
  clinic_patient_id_value uuid;
  appointment_id_value uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('status', 'error', 'code', 'AUTH_REQUIRED', 'message', 'Sesi login tidak ditemukan.');
  end if;

  if target_clinic_id is null then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_CLINIC', 'message', 'Klinik aktif tidak valid.');
  end if;

  if invited_by_membership_id is null then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_MEMBERSHIP', 'message', 'Membership pengundang tidak valid.');
  end if;

  if not public.has_ops_access(target_clinic_id) then
    return jsonb_build_object('status', 'error', 'code', 'FORBIDDEN', 'message', 'Akses operasional klinik ditolak.');
  end if;

  if not exists (
    select 1
    from public.clinic_memberships cm
    where cm.id = invited_by_membership_id
      and cm.clinic_id = target_clinic_id
      and cm.user_id = auth.uid()
      and cm.is_active = true
  ) then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_MEMBERSHIP', 'message', 'Membership pengundang tidak ditemukan pada klinik aktif.');
  end if;

  select c.name
  into clinic_name_value
  from public.clinics c
  where c.id = target_clinic_id
    and c.is_active = true
  limit 1;

  if clinic_name_value is null then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_CLINIC', 'message', 'Klinik tidak aktif atau tidak ditemukan.');
  end if;

  normalized_email := lower(btrim(patient_email));
  if normalized_email is null or normalized_email = '' then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_EMAIL', 'message', 'Email pasien wajib diisi.');
  end if;

  if session_date is null or session_time is null then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_SCHEDULE', 'message', 'Tanggal dan waktu sesi wajib diisi.');
  end if;

  if duration_minutes is null or duration_minutes < 15 or duration_minutes > 180 then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_DURATION', 'message', 'Durasi sesi harus di antara 15 dan 180 menit.');
  end if;

  session_timezone_value := coalesce(nullif(btrim(session_timezone), ''), 'Asia/Jakarta');
  expires_at_value := now() + make_interval(hours => greatest(invitation_ttl_hours, 1));
  token_value := md5(random()::text || clock_timestamp()::text || normalized_email || coalesce(auth.uid()::text, ''))
    || md5(random()::text || clock_timestamp()::text || txid_current()::text);
  session_start_at_value := ((session_date::timestamp + session_time) at time zone session_timezone_value);
  session_end_at_value := session_start_at_value + make_interval(mins => duration_minutes);

  select cm.id
  into practitioner_membership_id_value
  from public.clinic_memberships cm
  where cm.clinic_id = target_clinic_id
    and cm.is_active = true
    and cm.is_practitioner = true
  order by cm.is_owner desc, cm.created_at asc
  limit 1;

  if practitioner_membership_id_value is null then
    return jsonb_build_object('status', 'error', 'code', 'NO_PRACTITIONER', 'message', 'Tidak ada practitioner aktif pada klinik ini.');
  end if;

  select au.id, p.id
  into auth_user_id_value, patient_id_value
  from auth.users au
  left join public.patients p
    on p.user_id = au.id
  where lower(au.email) = normalized_email
  order by p.created_at asc nulls last
  limit 1;

  if auth_user_id_value is null or patient_id_value is null then
    resolved_flow := 'registration_required'::public.patient_invitation_flow;
    patient_id_value := null;
  else
    select exists (
      select 1
      from public.patient_clinic_consents pcc
      where pcc.clinic_id = target_clinic_id
        and pcc.patient_id = patient_id_value
        and pcc.revoked_at is null
    )
    into has_active_consent;

    if has_active_consent then
      resolved_flow := 'info_only'::public.patient_invitation_flow;
    else
      resolved_flow := 'consent_required'::public.patient_invitation_flow;
    end if;
  end if;

  insert into public.patient_invitations (
    clinic_id,
    invited_by_membership_id,
    email,
    token,
    expires_at,
    is_used,
    flow,
    session_start_at,
    session_end_at,
    session_timezone,
    target_patient_id,
    practitioner_membership_id,
    used_reason,
    appointment_id
  )
  values (
    target_clinic_id,
    invited_by_membership_id,
    normalized_email,
    token_value,
    expires_at_value,
    false,
    resolved_flow,
    session_start_at_value,
    session_end_at_value,
    session_timezone_value,
    patient_id_value,
    practitioner_membership_id_value,
    null,
    null
  )
  returning id into invitation_id_value;

  update public.patient_invitations pi
  set is_used = true,
      used_at = now(),
      used_reason = 'superseded'::public.patient_invitation_used_reason,
      replaced_by_invitation_id = invitation_id_value
  where pi.id <> invitation_id_value
    and pi.clinic_id = target_clinic_id
    and lower(pi.email) = normalized_email
    and pi.is_used = false
    and pi.expires_at > now();

  if resolved_flow = 'info_only'::public.patient_invitation_flow then
    if patient_id_value is null then
      return jsonb_build_object('status', 'error', 'code', 'PATIENT_NOT_FOUND', 'message', 'Pasien global tidak ditemukan untuk flow info-only.');
    end if;

    insert into public.clinic_patients (clinic_id, patient_id, mrn, is_active)
    values (
      target_clinic_id,
      patient_id_value,
      coalesce(
        (select p.mrn from public.patients p where p.id = patient_id_value),
        'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6))
      ),
      true
    )
    on conflict (clinic_id, patient_id) do update
    set is_active = true,
        updated_at = now()
    returning id into clinic_patient_id_value;

    insert into public.appointments (
      clinic_id,
      clinic_patient_id,
      patient_id,
      practitioner_membership_id,
      start_time,
      end_time,
      status,
      notes
    )
    values (
      target_clinic_id,
      clinic_patient_id_value,
      patient_id_value,
      practitioner_membership_id_value,
      session_start_at_value,
      session_end_at_value,
      'scheduled',
      'Auto-created from info-only invitation'
    )
    returning id into appointment_id_value;

    insert into public.patient_visits (
      clinic_id,
      clinic_patient_id,
      patient_id,
      appointment_id,
      status
    )
    values (
      target_clinic_id,
      clinic_patient_id_value,
      patient_id_value,
      appointment_id_value,
      'scheduled'
    )
    on conflict (appointment_id) do nothing;

    update public.patient_invitations
    set is_used = true,
        used_at = now(),
        used_reason = 'info_only_notified'::public.patient_invitation_used_reason,
        appointment_id = appointment_id_value
    where id = invitation_id_value;
  end if;

  return jsonb_build_object(
    'status', 'success',
    'message', 'Undangan pasien berhasil dibuat.',
    'flow', resolved_flow::text,
    'token', token_value,
    'email', normalized_email,
    'clinicName', clinic_name_value,
    'expiresAt', expires_at_value,
    'sessionStartAt', session_start_at_value,
    'sessionEndAt', session_end_at_value,
    'sessionTimezone', session_timezone_value,
    'targetPatientId', patient_id_value,
    'invitationId', invitation_id_value,
    'appointmentId', appointment_id_value
  );
exception
  when unique_violation then
    return jsonb_build_object('status', 'error', 'code', 'TOKEN_COLLISION', 'message', 'Gagal membuat token undangan unik. Silakan coba lagi.');
  when others then
    return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal membuat undangan: ' || sqlerrm);
end;
$$;


ALTER FUNCTION "public"."create_patient_invitation_with_schedule"("target_clinic_id" "uuid", "invited_by_membership_id" "uuid", "patient_email" "text", "session_date" "date", "session_time" time without time zone, "duration_minutes" integer, "session_timezone" "text", "invitation_ttl_hours" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_invitation_by_token"("invite_token" "text") RETURNS TABLE("email" "text", "expires_at" timestamp with time zone, "is_used" boolean, "clinic_id" "uuid", "clinic_name" "text", "flow" "public"."patient_invitation_flow", "used_reason" "public"."patient_invitation_used_reason", "session_start_at" timestamp with time zone, "session_end_at" timestamp with time zone, "session_timezone" "text", "target_patient_id" "uuid")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select
    pi.email,
    pi.expires_at,
    pi.is_used,
    pi.clinic_id,
    c.name as clinic_name,
    pi.flow,
    pi.used_reason,
    pi.session_start_at,
    pi.session_end_at,
    coalesce(pi.session_timezone, 'Asia/Jakarta') as session_timezone,
    pi.target_patient_id
  from public.patient_invitations pi
  left join public.clinics c on c.id = pi.clinic_id
  where pi.token = invite_token
  limit 1;
$$;


ALTER FUNCTION "public"."get_invitation_by_token"("invite_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_auth_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  incoming_role text;
begin
  incoming_role := coalesce(new.raw_user_meta_data ->> 'role', 'clinic_staff');
  if incoming_role not in ('clinic_staff', 'patient') then
    incoming_role := 'clinic_staff';
  end if;

  insert into public.users (id, role)
  values (new.id, incoming_role::public.user_role)
  on conflict (id) do nothing;

  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_auth_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_active_membership"("target_clinic_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.clinic_memberships cm
    where cm.user_id = auth.uid()
      and cm.clinic_id = target_clinic_id
      and cm.is_active = true
  );
$$;


ALTER FUNCTION "public"."has_active_membership"("target_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_ops_access"("target_clinic_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.clinic_memberships cm
    where cm.user_id = auth.uid()
      and cm.clinic_id = target_clinic_id
      and cm.is_active = true
      and (cm.is_staff = true or cm.is_owner = true or cm.is_practitioner = true)
  );
$$;


ALTER FUNCTION "public"."has_ops_access"("target_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_owner_access"("target_clinic_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.clinic_memberships cm
    where cm.user_id = auth.uid()
      and cm.clinic_id = target_clinic_id
      and cm.is_active = true
      and cm.is_owner = true
  );
$$;


ALTER FUNCTION "public"."has_owner_access"("target_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_patient_access"("target_patient_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.clinic_patients cp
    join public.clinic_memberships cm
      on cm.clinic_id = cp.clinic_id
     and cm.user_id = auth.uid()
     and cm.is_active = true
    where cp.patient_id = target_patient_id
  );
$$;


ALTER FUNCTION "public"."has_patient_access"("target_patient_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_practitioner_access"("target_clinic_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.clinic_memberships cm
    where cm.user_id = auth.uid()
      and cm.clinic_id = target_clinic_id
      and cm.is_active = true
      and cm.is_practitioner = true
  );
$$;


ALTER FUNCTION "public"."has_practitioner_access"("target_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_portal_staff"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and u.role::text = 'clinic_staff'
  );
$$;


ALTER FUNCTION "public"."is_portal_staff"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."save_therapy_session_entry"("target_clinic_id" "uuid", "target_patient_id" "uuid", "target_visit_id" "uuid", "input_session_date" "date", "input_session_time" time without time zone, "input_activity_type" "text", "input_subject" "text" DEFAULT NULL::"text", "input_clinical_notes" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  inserted_session_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object(
      'status', 'error',
      'code', 'AUTH_REQUIRED',
      'message', 'Sesi login tidak ditemukan.'
    );
  end if;

  if target_clinic_id is null or not public.has_practitioner_access(target_clinic_id) then
    return jsonb_build_object(
      'status', 'error',
      'code', 'FORBIDDEN',
      'message', 'Akses practitioner untuk klinik aktif tidak ditemukan.'
    );
  end if;

  if target_patient_id is null or target_visit_id is null then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVALID_INPUT',
      'message', 'Pasien atau kunjungan tidak valid.'
    );
  end if;

  if input_session_date is null or input_session_time is null then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVALID_INPUT',
      'message', 'Tanggal atau jam sesi tidak valid.'
    );
  end if;

  if input_activity_type is null or btrim(input_activity_type) = '' then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVALID_INPUT',
      'message', 'Jenis aktivitas wajib diisi.'
    );
  end if;

  if input_clinical_notes is null or btrim(input_clinical_notes) = '' then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVALID_INPUT',
      'message', 'Catatan klinis wajib diisi.'
    );
  end if;

  if not exists (
    select 1
    from public.patient_visits pv
    where pv.id = target_visit_id
      and pv.clinic_id = target_clinic_id
      and pv.patient_id = target_patient_id
  ) then
    return jsonb_build_object(
      'status', 'error',
      'code', 'VISIT_NOT_FOUND',
      'message', 'Visit tidak ditemukan pada klinik aktif.'
    );
  end if;

  insert into public.therapy_sessions (
    clinic_id,
    visit_id,
    session_date,
    session_time,
    activity_type,
    subject,
    clinical_notes
  ) values (
    target_clinic_id,
    target_visit_id,
    input_session_date,
    input_session_time,
    btrim(input_activity_type),
    nullif(btrim(coalesce(input_subject, '')), ''),
    btrim(input_clinical_notes)
  )
  returning id into inserted_session_id;

  return jsonb_build_object(
    'status', 'success',
    'message', 'Catatan sesi terapi berhasil disimpan.',
    'sessionId', inserted_session_id
  );
end;
$$;


ALTER FUNCTION "public"."save_therapy_session_entry"("target_clinic_id" "uuid", "target_patient_id" "uuid", "target_visit_id" "uuid", "input_session_date" "date", "input_session_time" time without time zone, "input_activity_type" "text", "input_subject" "text", "input_clinical_notes" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."submit_patient_registration"("invite_token" "text", "registration_payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  invitation_row public.patient_invitations%rowtype;
  psychologist_id uuid;
  new_patient_id uuid;
  new_appointment_id uuid;
  new_visit_id uuid;
  appointment_start timestamptz;
  appointment_end timestamptz;
  mrn_value text;
  birth_process_value public.birth_process;
  autism_indication_value public.autism_indication;
  adhd_indication_value public.adhd_indication;
begin
  if invite_token is null or btrim(invite_token) = '' then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVALID_TOKEN',
      'message', 'Token registrasi tidak valid.'
    );
  end if;

  select *
  into invitation_row
  from public.patient_invitations
  where token = invite_token
  limit 1;

  if not found then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVITATION_NOT_FOUND',
      'message', 'Undangan tidak ditemukan. Silakan minta link baru.'
    );
  end if;

  if coalesce(invitation_row.is_used, false) then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVITATION_USED',
      'message', 'Link registrasi sudah digunakan.'
    );
  end if;

  if invitation_row.expires_at < now() then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVITATION_EXPIRED',
      'message', 'Link registrasi sudah kedaluwarsa.'
    );
  end if;

  if coalesce(registration_payload ->> 'fullName', '') = '' then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVALID_PAYLOAD',
      'message', 'Data form tidak valid.'
    );
  end if;

  select id
  into psychologist_id
  from public.users
  where role in ('admin', 'psychologist')
  order by created_at asc
  limit 1;

  if psychologist_id is null then
    return jsonb_build_object(
      'status', 'error',
      'code', 'NO_PSYCHOLOGIST',
      'message', 'Tidak ada user psikolog/admin aktif untuk membuat jadwal awal.'
    );
  end if;

  birth_process_value := nullif(registration_payload ->> 'birthProcess', '')::public.birth_process;
  autism_indication_value := nullif(registration_payload ->> 'autismIndication', '')::public.autism_indication;
  adhd_indication_value := nullif(registration_payload ->> 'adhdIndication', '')::public.adhd_indication;

  mrn_value := 'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));

  insert into public.patients (
    mrn,
    full_name,
    email,
    phone
  )
  values (
    mrn_value,
    registration_payload ->> 'fullName',
    invitation_row.email,
    nullif(registration_payload ->> 'phone', '')
  )
  returning id into new_patient_id;

  insert into public.patient_personal_data (
    patient_id,
    full_name,
    sex,
    birth_date,
    address,
    religion,
    education,
    occupation,
    hobby,
    referral_source
  )
  values (
    new_patient_id,
    registration_payload ->> 'fullName',
    nullif(registration_payload ->> 'sex', ''),
    nullif(registration_payload ->> 'birthDate', '')::date,
    nullif(registration_payload ->> 'address', ''),
    nullif(registration_payload ->> 'religion', ''),
    nullif(registration_payload ->> 'education', ''),
    nullif(registration_payload ->> 'occupation', ''),
    nullif(registration_payload ->> 'hobby', ''),
    'Self registration invitation'
  );

  insert into public.patient_family_data (
    patient_id,
    guardian_name,
    guardian_relation,
    guardian_phone,
    guardian_address,
    father_name,
    father_age,
    father_education,
    father_occupation,
    mother_name,
    mother_age,
    mother_education,
    mother_occupation,
    marital_status,
    number_of_children,
    monthly_income,
    family_notes
  )
  values (
    new_patient_id,
    nullif(registration_payload ->> 'guardianName', ''),
    nullif(registration_payload ->> 'guardianRelation', ''),
    nullif(registration_payload ->> 'guardianPhone', ''),
    nullif(registration_payload ->> 'guardianAddress', ''),
    nullif(registration_payload ->> 'fatherName', ''),
    nullif(registration_payload ->> 'fatherAge', '')::integer,
    nullif(registration_payload ->> 'fatherEducation', ''),
    nullif(registration_payload ->> 'fatherOccupation', ''),
    nullif(registration_payload ->> 'motherName', ''),
    nullif(registration_payload ->> 'motherAge', '')::integer,
    nullif(registration_payload ->> 'motherEducation', ''),
    nullif(registration_payload ->> 'motherOccupation', ''),
    nullif(registration_payload ->> 'maritalStatus', ''),
    nullif(registration_payload ->> 'numberOfChildren', '')::integer,
    nullif(registration_payload ->> 'monthlyIncome', '')::numeric(12,2),
    nullif(registration_payload ->> 'familyNotes', '')
  );

  appointment_start := date_trunc('day', now()) + interval '1 day' + interval '9 hours';
  appointment_end := appointment_start + interval '45 minutes';

  insert into public.appointments (
    patient_id,
    psychologist_id,
    start_time,
    end_time,
    status,
    notes
  )
  values (
    new_patient_id,
    psychologist_id,
    appointment_start,
    appointment_end,
    'scheduled',
    'Auto-created from patient self-registration'
  )
  returning id into new_appointment_id;

  insert into public.patient_visits (
    patient_id,
    appointment_id,
    status
  )
  values (
    new_patient_id,
    new_appointment_id,
    'scheduled'
  )
  returning id into new_visit_id;

  insert into public.developmental_history (
    visit_id,
    mother_pregnancy_notes,
    birth_process,
    gestational_age_weeks,
    birth_weight_kg,
    birth_length_cm,
    walking_age_months,
    speaking_age_months,
    hearing_function,
    speech_articulation,
    vision_function,
    child_medical_history,
    special_notes
  )
  values (
    new_visit_id,
    nullif(registration_payload ->> 'motherPregnancyNotes', ''),
    birth_process_value,
    nullif(registration_payload ->> 'gestationalAgeWeeks', '')::integer,
    nullif(registration_payload ->> 'birthWeightKg', '')::numeric(5,2),
    nullif(registration_payload ->> 'birthLengthCm', '')::numeric(5,2),
    nullif(registration_payload ->> 'walkingAgeMonths', '')::integer,
    nullif(registration_payload ->> 'speakingAgeMonths', '')::integer,
    nullif(registration_payload ->> 'hearingFunction', ''),
    nullif(registration_payload ->> 'speechArticulation', ''),
    nullif(registration_payload ->> 'visionFunction', ''),
    nullif(registration_payload ->> 'childMedicalHistory', ''),
    nullif(registration_payload ->> 'specialNotes', '')
  );

  insert into public.cognitive_assessments (
    visit_id,
    knows_letters,
    knows_colors,
    writes,
    counts,
    reads,
    reading_spelling,
    fluent_reading,
    reversed_letters,
    autism_indication,
    adhd_indication,
    initial_conclusion,
    intervention_counseling_given,
    intervention_areas,
    other_medical_action,
    referral_action,
    assessment_result
  )
  values (
    new_visit_id,
    coalesce((registration_payload ->> 'knowsLetters')::boolean, false),
    coalesce((registration_payload ->> 'knowsColors')::boolean, false),
    coalesce((registration_payload ->> 'writes')::boolean, false),
    coalesce((registration_payload ->> 'counts')::boolean, false),
    coalesce((registration_payload ->> 'reads')::boolean, false),
    coalesce((registration_payload ->> 'readingSpelling')::boolean, false),
    coalesce((registration_payload ->> 'fluentReading')::boolean, false),
    coalesce((registration_payload ->> 'reversedLetters')::boolean, false),
    autism_indication_value,
    adhd_indication_value,
    nullif(registration_payload ->> 'initialConclusion', ''),
    coalesce((registration_payload ->> 'interventionCounselingGiven')::boolean, false),
    nullif(registration_payload ->> 'interventionAreas', ''),
    nullif(registration_payload ->> 'otherMedicalAction', ''),
    nullif(registration_payload ->> 'referralAction', ''),
    nullif(registration_payload ->> 'assessmentResult', '')
  );

  update public.patient_invitations
  set is_used = true,
      used_at = now()
  where id = invitation_row.id;

  return jsonb_build_object(
    'status', 'success',
    'message', 'Registrasi berhasil. Tim psikolog akan menghubungi Anda untuk sesi lanjutan.',
    'patientId', new_patient_id
  );
exception
  when others then
    return jsonb_build_object(
      'status', 'error',
      'code', 'SERVER_ERROR',
      'message', 'Gagal memproses registrasi: ' || sqlerrm
    );
end;
$$;


ALTER FUNCTION "public"."submit_patient_registration"("invite_token" "text", "registration_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_clinic_membership_profile_defaults"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  raw_meta jsonb;
  email_value text;
  phone_value text;
begin
  select au.raw_user_meta_data, au.email, au.phone
  into raw_meta, email_value, phone_value
  from auth.users au
  where au.id = new.user_id
  limit 1;

  if new.full_name is null or btrim(new.full_name) = '' then
    new.full_name := coalesce(
      nullif(btrim(coalesce(raw_meta ->> 'full_name', '')), ''),
      nullif(btrim(coalesce(raw_meta ->> 'name', '')), ''),
      nullif(btrim(coalesce(raw_meta ->> 'display_name', '')), ''),
      nullif(split_part(coalesce(email_value, ''), '@', 1), '')
    );
  end if;

  if new.email is null or btrim(new.email) = '' then
    new.email := nullif(lower(btrim(coalesce(email_value, ''))), '');
  end if;

  if new.phone is null or btrim(new.phone) = '' then
    new.phone := coalesce(
      nullif(btrim(coalesce(phone_value, '')), ''),
      nullif(btrim(coalesce(raw_meta ->> 'phone', '')), ''),
      nullif(btrim(coalesce(raw_meta ->> 'phone_number', '')), '')
    );
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."sync_clinic_membership_profile_defaults"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_patient_registration_by_user_id"("invite_token" "text", "registration_payload" "jsonb", "target_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  invitation_row public.patient_invitations%rowtype;
  auth_user_email text;
  patient_id_value uuid;
  clinic_patient_id_value uuid;
  practitioner_membership_id_value uuid;
  visit_id_value uuid;
  appointment_id_value uuid;
  appointment_start timestamptz;
  appointment_end timestamptz;
  birth_process_value public.birth_process;
  autism_indication_value public.autism_indication;
  adhd_indication_value public.adhd_indication;
  consent_text_value text := 'Saya menyetujui berbagi data medis saya dengan klinik tujuan untuk keperluan layanan psikologi.';
  consent_ip_value text;
  consent_user_agent_value text;
begin
  if invite_token is null or btrim(invite_token) = '' then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_TOKEN', 'message', 'Token registrasi tidak valid.');
  end if;

  if target_user_id is null then
    return jsonb_build_object('status', 'error', 'code', 'AUTH_USER_REQUIRED', 'message', 'Akun login pasien tidak ditemukan.');
  end if;

  if registration_payload is null then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_PAYLOAD', 'message', 'Data form tidak valid.');
  end if;

  select *
  into invitation_row
  from public.patient_invitations
  where token = invite_token
  limit 1
  for update;

  if not found then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_NOT_FOUND', 'message', 'Undangan tidak ditemukan.');
  end if;

  if invitation_row.flow <> 'registration_required'::public.patient_invitation_flow then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_FLOW', 'message', 'Undangan ini tidak membutuhkan registrasi penuh.');
  end if;

  if invitation_row.clinic_id is null then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_CLINIC_REQUIRED', 'message', 'Undangan belum terhubung ke klinik.');
  end if;

  if coalesce(invitation_row.is_used, false) then
    if invitation_row.used_reason = 'superseded'::public.patient_invitation_used_reason then
      return jsonb_build_object('status', 'error', 'code', 'INVITATION_SUPERSEDED', 'message', 'Link undangan ini sudah diganti dengan undangan terbaru.');
    end if;

    return jsonb_build_object('status', 'error', 'code', 'INVITATION_USED', 'message', 'Link registrasi sudah digunakan.');
  end if;

  if invitation_row.expires_at < now() then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_EXPIRED', 'message', 'Link registrasi sudah kedaluwarsa.');
  end if;

  if coalesce(registration_payload ->> 'fullName', '') = '' then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_PAYLOAD', 'message', 'Nama lengkap wajib diisi.');
  end if;

  if coalesce((registration_payload ->> 'agreeToDataSharing')::boolean, false) = false then
    return jsonb_build_object('status', 'error', 'code', 'CONSENT_REQUIRED', 'message', 'Persetujuan berbagi data wajib disetujui.');
  end if;

  select au.email
  into auth_user_email
  from auth.users au
  where au.id = target_user_id
  limit 1;

  if auth_user_email is null or lower(btrim(auth_user_email)) <> lower(btrim(invitation_row.email)) then
    return jsonb_build_object('status', 'error', 'code', 'EMAIL_MISMATCH', 'message', 'Email akun tidak cocok dengan email undangan.');
  end if;

  select p.id
  into patient_id_value
  from public.patients p
  where p.user_id = target_user_id
  limit 1;

  if patient_id_value is null then
    return jsonb_build_object('status', 'error', 'code', 'PATIENT_NOT_FOUND', 'message', 'Data pasien belum dibuat untuk akun ini.');
  end if;

  practitioner_membership_id_value := invitation_row.practitioner_membership_id;
  if practitioner_membership_id_value is null
     or not exists (
      select 1
      from public.clinic_memberships cm
      where cm.id = practitioner_membership_id_value
        and cm.is_active = true
        and cm.is_practitioner = true
     ) then
    select cm.id
    into practitioner_membership_id_value
    from public.clinic_memberships cm
    where cm.clinic_id = invitation_row.clinic_id
      and cm.is_active = true
      and cm.is_practitioner = true
    order by cm.is_owner desc, cm.created_at asc
    limit 1;
  end if;

  if practitioner_membership_id_value is null then
    return jsonb_build_object('status', 'error', 'code', 'NO_PRACTITIONER', 'message', 'Tidak ada practitioner aktif pada klinik ini.');
  end if;

  consent_ip_value := nullif(registration_payload ->> '_consentIp', '');
  consent_user_agent_value := nullif(registration_payload ->> '_consentUserAgent', '');

  if not exists (
    select 1
    from public.patient_clinic_consents pcc
    where pcc.clinic_id = invitation_row.clinic_id
      and pcc.patient_id = patient_id_value
      and pcc.revoked_at is null
  ) then
    insert into public.patient_clinic_consents (
      clinic_id,
      patient_id,
      invitation_id,
      consent_version,
      consent_text,
      source,
      accepted_at,
      accepted_ip,
      accepted_user_agent,
      created_at,
      updated_at
    )
    values (
      invitation_row.clinic_id,
      patient_id_value,
      invitation_row.id,
      'v1',
      consent_text_value,
      'registration_wizard'::public.consent_source,
      now(),
      consent_ip_value,
      consent_user_agent_value,
      now(),
      now()
    );
  end if;

  insert into public.clinic_patients (clinic_id, patient_id, mrn, is_active)
  values (
    invitation_row.clinic_id,
    patient_id_value,
    coalesce(
      (select p.mrn from public.patients p where p.id = patient_id_value),
      'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6))
    ),
    true
  )
  on conflict (clinic_id, patient_id) do update
  set is_active = true,
      updated_at = now()
  returning id into clinic_patient_id_value;

  birth_process_value := nullif(registration_payload ->> 'birthProcess', '')::public.birth_process;
  autism_indication_value := nullif(registration_payload ->> 'autismIndication', '')::public.autism_indication;
  adhd_indication_value := nullif(registration_payload ->> 'adhdIndication', '')::public.adhd_indication;

  update public.patients
  set full_name = registration_payload ->> 'fullName',
      email = invitation_row.email,
      phone = nullif(registration_payload ->> 'phone', ''),
      updated_at = now()
  where id = patient_id_value;

  insert into public.patient_personal_data (
    clinic_id,
    patient_id,
    full_name,
    sex,
    birth_date,
    address,
    religion,
    education,
    occupation,
    hobby,
    referral_source
  )
  values (
    invitation_row.clinic_id,
    patient_id_value,
    registration_payload ->> 'fullName',
    nullif(registration_payload ->> 'sex', ''),
    nullif(registration_payload ->> 'birthDate', '')::date,
    nullif(registration_payload ->> 'address', ''),
    nullif(registration_payload ->> 'religion', ''),
    nullif(registration_payload ->> 'education', ''),
    nullif(registration_payload ->> 'occupation', ''),
    nullif(registration_payload ->> 'hobby', ''),
    'Self registration invitation'
  )
  on conflict (clinic_id, patient_id) do update
  set full_name = excluded.full_name,
      sex = excluded.sex,
      birth_date = excluded.birth_date,
      address = excluded.address,
      religion = excluded.religion,
      education = excluded.education,
      occupation = excluded.occupation,
      hobby = excluded.hobby,
      referral_source = excluded.referral_source,
      updated_at = now();

  insert into public.patient_family_data (
    clinic_id,
    patient_id,
    guardian_name,
    guardian_relation,
    guardian_phone,
    guardian_address,
    father_name,
    father_age,
    father_education,
    father_occupation,
    mother_name,
    mother_age,
    mother_education,
    mother_occupation,
    marital_status,
    number_of_children,
    monthly_income,
    family_notes
  )
  values (
    invitation_row.clinic_id,
    patient_id_value,
    nullif(registration_payload ->> 'guardianName', ''),
    nullif(registration_payload ->> 'guardianRelation', ''),
    nullif(registration_payload ->> 'guardianPhone', ''),
    nullif(registration_payload ->> 'guardianAddress', ''),
    nullif(registration_payload ->> 'fatherName', ''),
    nullif(registration_payload ->> 'fatherAge', '')::integer,
    nullif(registration_payload ->> 'fatherEducation', ''),
    nullif(registration_payload ->> 'fatherOccupation', ''),
    nullif(registration_payload ->> 'motherName', ''),
    nullif(registration_payload ->> 'motherAge', '')::integer,
    nullif(registration_payload ->> 'motherEducation', ''),
    nullif(registration_payload ->> 'motherOccupation', ''),
    nullif(registration_payload ->> 'maritalStatus', ''),
    nullif(registration_payload ->> 'numberOfChildren', '')::integer,
    nullif(registration_payload ->> 'monthlyIncome', '')::numeric(12,2),
    nullif(registration_payload ->> 'familyNotes', '')
  )
  on conflict (clinic_id, patient_id) do update
  set guardian_name = excluded.guardian_name,
      guardian_relation = excluded.guardian_relation,
      guardian_phone = excluded.guardian_phone,
      guardian_address = excluded.guardian_address,
      father_name = excluded.father_name,
      father_age = excluded.father_age,
      father_education = excluded.father_education,
      father_occupation = excluded.father_occupation,
      mother_name = excluded.mother_name,
      mother_age = excluded.mother_age,
      mother_education = excluded.mother_education,
      mother_occupation = excluded.mother_occupation,
      marital_status = excluded.marital_status,
      number_of_children = excluded.number_of_children,
      monthly_income = excluded.monthly_income,
      family_notes = excluded.family_notes,
      updated_at = now();

  appointment_id_value := invitation_row.appointment_id;

  if appointment_id_value is null then
    appointment_start := coalesce(
      invitation_row.session_start_at,
      date_trunc('day', now()) + interval '1 day' + interval '9 hours'
    );
    appointment_end := coalesce(
      invitation_row.session_end_at,
      appointment_start + interval '45 minutes'
    );

    insert into public.appointments (
      clinic_id,
      clinic_patient_id,
      patient_id,
      practitioner_membership_id,
      start_time,
      end_time,
      status,
      notes
    )
    values (
      invitation_row.clinic_id,
      clinic_patient_id_value,
      patient_id_value,
      practitioner_membership_id_value,
      appointment_start,
      appointment_end,
      'scheduled',
      'Auto-created from patient registration + consent'
    )
    returning id into appointment_id_value;
  end if;

  select pv.id
  into visit_id_value
  from public.patient_visits pv
  where pv.appointment_id = appointment_id_value
  limit 1;

  if visit_id_value is null then
    insert into public.patient_visits (
      clinic_id,
      clinic_patient_id,
      patient_id,
      appointment_id,
      status
    )
    values (
      invitation_row.clinic_id,
      clinic_patient_id_value,
      patient_id_value,
      appointment_id_value,
      'scheduled'
    )
    returning id into visit_id_value;
  end if;

  insert into public.developmental_history (
    clinic_id,
    visit_id,
    mother_pregnancy_notes,
    birth_process,
    gestational_age_weeks,
    birth_weight_kg,
    birth_length_cm,
    walking_age_months,
    speaking_age_months,
    hearing_function,
    speech_articulation,
    vision_function,
    child_medical_history,
    special_notes
  )
  values (
    invitation_row.clinic_id,
    visit_id_value,
    nullif(registration_payload ->> 'motherPregnancyNotes', ''),
    birth_process_value,
    nullif(registration_payload ->> 'gestationalAgeWeeks', '')::integer,
    nullif(registration_payload ->> 'birthWeightKg', '')::numeric(5,2),
    nullif(registration_payload ->> 'birthLengthCm', '')::numeric(5,2),
    nullif(registration_payload ->> 'walkingAgeMonths', '')::integer,
    nullif(registration_payload ->> 'speakingAgeMonths', '')::integer,
    nullif(registration_payload ->> 'hearingFunction', ''),
    nullif(registration_payload ->> 'speechArticulation', ''),
    nullif(registration_payload ->> 'visionFunction', ''),
    nullif(registration_payload ->> 'childMedicalHistory', ''),
    nullif(registration_payload ->> 'specialNotes', '')
  )
  on conflict (visit_id) do update
  set mother_pregnancy_notes = excluded.mother_pregnancy_notes,
      birth_process = excluded.birth_process,
      gestational_age_weeks = excluded.gestational_age_weeks,
      birth_weight_kg = excluded.birth_weight_kg,
      birth_length_cm = excluded.birth_length_cm,
      walking_age_months = excluded.walking_age_months,
      speaking_age_months = excluded.speaking_age_months,
      hearing_function = excluded.hearing_function,
      speech_articulation = excluded.speech_articulation,
      vision_function = excluded.vision_function,
      child_medical_history = excluded.child_medical_history,
      special_notes = excluded.special_notes,
      clinic_id = excluded.clinic_id,
      updated_at = now();

  insert into public.cognitive_assessments (
    clinic_id,
    visit_id,
    knows_letters,
    knows_colors,
    writes,
    counts,
    reads,
    reading_spelling,
    fluent_reading,
    reversed_letters,
    autism_indication,
    adhd_indication,
    initial_conclusion,
    intervention_counseling_given,
    intervention_areas,
    other_medical_action,
    referral_action,
    assessment_result
  )
  values (
    invitation_row.clinic_id,
    visit_id_value,
    coalesce((registration_payload ->> 'knowsLetters')::boolean, false),
    coalesce((registration_payload ->> 'knowsColors')::boolean, false),
    coalesce((registration_payload ->> 'writes')::boolean, false),
    coalesce((registration_payload ->> 'counts')::boolean, false),
    coalesce((registration_payload ->> 'reads')::boolean, false),
    coalesce((registration_payload ->> 'readingSpelling')::boolean, false),
    coalesce((registration_payload ->> 'fluentReading')::boolean, false),
    coalesce((registration_payload ->> 'reversedLetters')::boolean, false),
    autism_indication_value,
    adhd_indication_value,
    nullif(registration_payload ->> 'initialConclusion', ''),
    coalesce((registration_payload ->> 'interventionCounselingGiven')::boolean, false),
    nullif(registration_payload ->> 'interventionAreas', ''),
    nullif(registration_payload ->> 'otherMedicalAction', ''),
    nullif(registration_payload ->> 'referralAction', ''),
    nullif(registration_payload ->> 'assessmentResult', '')
  )
  on conflict (visit_id) do update
  set knows_letters = excluded.knows_letters,
      knows_colors = excluded.knows_colors,
      writes = excluded.writes,
      counts = excluded.counts,
      reads = excluded.reads,
      reading_spelling = excluded.reading_spelling,
      fluent_reading = excluded.fluent_reading,
      reversed_letters = excluded.reversed_letters,
      autism_indication = excluded.autism_indication,
      adhd_indication = excluded.adhd_indication,
      initial_conclusion = excluded.initial_conclusion,
      intervention_counseling_given = excluded.intervention_counseling_given,
      intervention_areas = excluded.intervention_areas,
      other_medical_action = excluded.other_medical_action,
      referral_action = excluded.referral_action,
      assessment_result = excluded.assessment_result,
      clinic_id = excluded.clinic_id,
      updated_at = now();

  update public.patient_invitations
  set is_used = true,
      used_at = now(),
      used_reason = 'registration_completed'::public.patient_invitation_used_reason,
      appointment_id = appointment_id_value,
      practitioner_membership_id = practitioner_membership_id_value,
      target_patient_id = coalesce(target_patient_id, patient_id_value)
  where id = invitation_row.id;

  return jsonb_build_object(
    'status', 'success',
    'message', 'Registrasi berhasil. Jadwal sesi sudah dibuat sesuai undangan.',
    'patientId', patient_id_value,
    'clinicId', invitation_row.clinic_id,
    'clinicPatientId', clinic_patient_id_value,
    'appointmentId', appointment_id_value,
    'visitId', visit_id_value
  );
exception
  when others then
    return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal memproses registrasi: ' || sqlerrm);
end;
$$;


ALTER FUNCTION "public"."update_patient_registration_by_user_id"("invite_token" "text", "registration_payload" "jsonb", "target_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verify_referral_pin"("referral_id" "uuid", "input_pin" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  referral_row public.referrals_and_feedback%rowtype;
  clinic_name_value text;
  patient_name_value text;
  psychologist_name_value text;
  psychologist_email_value text;
  psychologist_sip_number_value text;
  psychologist_profession_value public.practitioner_profession;
begin
  if referral_id is null or input_pin is null or btrim(input_pin) = '' then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVALID_INPUT',
      'message', 'Input tidak valid.'
    );
  end if;

  select *
  into referral_row
  from public.referrals_and_feedback
  where id = referral_id
  limit 1;

  if not found then
    return jsonb_build_object(
      'status', 'error',
      'code', 'REFERRAL_NOT_FOUND',
      'message', 'Dokumen rujukan tidak ditemukan.'
    );
  end if;

  if referral_row.expires_at < now() then
    return jsonb_build_object(
      'status', 'error',
      'code', 'REFERRAL_EXPIRED',
      'message', 'Dokumen rujukan sudah kedaluwarsa.'
    );
  end if;

  if input_pin <> referral_row.secure_pin then
    return jsonb_build_object(
      'status', 'error',
      'code', 'INVALID_PIN',
      'message', 'PIN salah. Periksa kembali PIN 6 digit Anda.'
    );
  end if;

  select
    c.name,
    p.full_name,
    coalesce(
      nullif(btrim(cm.full_name), ''),
      nullif(split_part(coalesce(cm.email, au.email, ''), '@', 1), '')
    ) as psychologist_name,
    nullif(lower(btrim(coalesce(cm.email, au.email, ''))), '') as psychologist_email,
    nullif(btrim(coalesce(cm.sip_number, '')), '') as psychologist_sip_number,
    cm.profession
  into
    clinic_name_value,
    patient_name_value,
    psychologist_name_value,
    psychologist_email_value,
    psychologist_sip_number_value,
    psychologist_profession_value
  from public.referrals_and_feedback rf
  left join public.clinics c
    on c.id = rf.clinic_id
  left join public.patients p
    on p.id = rf.patient_id
  left join public.patient_visits pv
    on pv.id = rf.visit_id
  left join public.appointments a
    on a.id = pv.appointment_id
  left join public.clinic_memberships cm
    on cm.id = coalesce(rf.practitioner_membership_id, a.practitioner_membership_id)
  left join auth.users au
    on au.id = cm.user_id
  where rf.id = referral_row.id
  limit 1;

  return jsonb_build_object(
    'status', 'success',
    'message', 'PIN valid. Dokumen berhasil dibuka.',
    'data', jsonb_build_object(
      'id', referral_row.id,
      'destination', referral_row.destination,
      'notes', referral_row.notes,
      'createdAt', referral_row.created_at,
      'expiresAt', referral_row.expires_at,
      'clinicName', clinic_name_value,
      'patientName', patient_name_value,
      'psychologistName', psychologist_name_value,
      'psychologistEmail', psychologist_email_value,
      'psychologistSipNumber', psychologist_sip_number_value,
      'psychologistProfession', case
        when psychologist_profession_value is null then null
        else psychologist_profession_value::text
      end
    )
  );
end;
$$;


ALTER FUNCTION "public"."verify_referral_pin"("referral_id" "uuid", "input_pin" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."appointments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "start_time" timestamp with time zone NOT NULL,
    "end_time" timestamp with time zone NOT NULL,
    "status" "public"."appointment_status" DEFAULT 'scheduled'::"public"."appointment_status" NOT NULL,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "clinic_id" "uuid" NOT NULL,
    "clinic_patient_id" "uuid" NOT NULL,
    "practitioner_membership_id" "uuid" NOT NULL
);


ALTER TABLE "public"."appointments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."clinic_memberships" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "clinic_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "is_owner" boolean DEFAULT false NOT NULL,
    "is_staff" boolean DEFAULT false NOT NULL,
    "is_practitioner" boolean DEFAULT false NOT NULL,
    "profession" "public"."practitioner_profession",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "full_name" "text",
    "email" "text",
    "birth_date" "date",
    "ktp_number" character varying(32),
    "gender" character varying(20),
    "address" "text",
    "phone" character varying(32),
    "sip_number" character varying(64)
);


ALTER TABLE "public"."clinic_memberships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."clinic_patients" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "clinic_id" "uuid" NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "mrn" character varying(64) NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."clinic_patients" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."clinics" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "slug" character varying(120) NOT NULL,
    "owner_user_id" "uuid",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."clinics" OWNER TO "postgres";


COMMENT ON TABLE "public"."clinics" IS 'Infrastructure and Landing Page readiness finalized.';



CREATE TABLE IF NOT EXISTS "public"."cognitive_assessments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "visit_id" "uuid" NOT NULL,
    "knows_letters" boolean,
    "knows_colors" boolean,
    "writes" boolean,
    "counts" boolean,
    "reads" boolean,
    "reading_spelling" boolean,
    "fluent_reading" boolean,
    "reversed_letters" boolean,
    "autism_indication" "public"."autism_indication",
    "adhd_indication" "public"."adhd_indication",
    "initial_conclusion" "text",
    "intervention_counseling_given" boolean,
    "intervention_areas" "text",
    "other_medical_action" "text",
    "referral_action" "text",
    "assessment_result" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "clinic_id" "uuid" NOT NULL
);


ALTER TABLE "public"."cognitive_assessments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."developmental_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "visit_id" "uuid" NOT NULL,
    "mother_pregnancy_notes" "text",
    "birth_process" "public"."birth_process",
    "gestational_age_weeks" integer,
    "birth_weight_kg" numeric(5,2),
    "birth_length_cm" numeric(5,2),
    "walking_age_months" integer,
    "speaking_age_months" integer,
    "hearing_function" "text",
    "speech_articulation" "text",
    "vision_function" "text",
    "child_medical_history" "text",
    "special_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "clinic_id" "uuid" NOT NULL
);


ALTER TABLE "public"."developmental_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."patient_clinic_consents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "clinic_id" "uuid" NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "invitation_id" "uuid",
    "consent_version" character varying(20) DEFAULT 'v1'::character varying NOT NULL,
    "consent_text" "text" NOT NULL,
    "source" "public"."consent_source" DEFAULT 'registration_wizard'::"public"."consent_source" NOT NULL,
    "accepted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "accepted_ip" "text",
    "accepted_user_agent" "text",
    "revoked_at" timestamp with time zone,
    "revoked_reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."patient_clinic_consents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."patient_family_data" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "guardian_name" "text",
    "guardian_relation" character varying(50),
    "guardian_phone" character varying(32),
    "guardian_address" "text",
    "father_name" "text",
    "father_age" integer,
    "father_education" character varying(120),
    "father_occupation" character varying(120),
    "mother_name" "text",
    "mother_age" integer,
    "mother_education" character varying(120),
    "mother_occupation" character varying(120),
    "marital_status" character varying(40),
    "number_of_children" integer,
    "monthly_income" numeric(12,2),
    "family_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "clinic_id" "uuid" NOT NULL
);


ALTER TABLE "public"."patient_family_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."patient_invitations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "token" character varying(128) NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "is_used" boolean DEFAULT false NOT NULL,
    "used_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "clinic_id" "uuid" NOT NULL,
    "invited_by_membership_id" "uuid",
    "flow" "public"."patient_invitation_flow" DEFAULT 'registration_required'::"public"."patient_invitation_flow" NOT NULL,
    "session_start_at" timestamp with time zone,
    "session_end_at" timestamp with time zone,
    "session_timezone" "text" DEFAULT 'Asia/Jakarta'::"text",
    "target_patient_id" "uuid",
    "practitioner_membership_id" "uuid",
    "used_reason" "public"."patient_invitation_used_reason",
    "replaced_by_invitation_id" "uuid",
    "appointment_id" "uuid",
    CONSTRAINT "patient_invitations_session_range_chk" CHECK ((("session_start_at" IS NULL) OR ("session_end_at" IS NULL) OR ("session_end_at" > "session_start_at")))
);


ALTER TABLE "public"."patient_invitations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."patient_personal_data" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "case_number" character varying(64),
    "sex" character varying(1),
    "birth_date" "date",
    "address" "text",
    "religion" character varying(80),
    "education" character varying(120),
    "occupation" character varying(120),
    "hobby" character varying(120),
    "referral_source" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "full_name" "text",
    "clinic_id" "uuid" NOT NULL
);


ALTER TABLE "public"."patient_personal_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."patient_visits" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "appointment_id" "uuid" NOT NULL,
    "status" "public"."visit_status" DEFAULT 'scheduled'::"public"."visit_status" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "clinic_id" "uuid" NOT NULL,
    "clinic_patient_id" "uuid" NOT NULL
);


ALTER TABLE "public"."patient_visits" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."patients" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "mrn" character varying(64) NOT NULL,
    "full_name" "text" NOT NULL,
    "email" "text",
    "phone" character varying(32),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."patients" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."referrals_and_feedback" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "visit_id" "uuid" NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "destination" character varying(120) NOT NULL,
    "notes" "text" NOT NULL,
    "secure_pin" character varying(6) NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "clinic_id" "uuid" NOT NULL,
    "practitioner_membership_id" "uuid",
    CONSTRAINT "referrals_and_feedback_secure_pin_check" CHECK ((("secure_pin")::"text" ~ '^[0-9]{6}$'::"text"))
);


ALTER TABLE "public"."referrals_and_feedback" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."therapy_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "visit_id" "uuid" NOT NULL,
    "session_date" "date" NOT NULL,
    "session_time" time without time zone NOT NULL,
    "activity_type" character varying(120) NOT NULL,
    "subject" "text",
    "clinical_notes" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "clinic_id" "uuid" NOT NULL
);


ALTER TABLE "public"."therapy_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "role" "public"."user_role" DEFAULT 'clinic_staff'::"public"."user_role" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "users_role_supported_chk" CHECK ((("role")::"text" = ANY (ARRAY['clinic_staff'::"text", 'patient'::"text"])))
);


ALTER TABLE "public"."users" OWNER TO "postgres";


ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clinic_memberships"
    ADD CONSTRAINT "clinic_memberships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clinic_memberships"
    ADD CONSTRAINT "clinic_memberships_user_clinic_unique" UNIQUE ("clinic_id", "user_id");



ALTER TABLE ONLY "public"."clinic_patients"
    ADD CONSTRAINT "clinic_patients_mrn_unique" UNIQUE ("clinic_id", "mrn");



ALTER TABLE ONLY "public"."clinic_patients"
    ADD CONSTRAINT "clinic_patients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clinic_patients"
    ADD CONSTRAINT "clinic_patients_unique" UNIQUE ("clinic_id", "patient_id");



ALTER TABLE ONLY "public"."clinics"
    ADD CONSTRAINT "clinics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cognitive_assessments"
    ADD CONSTRAINT "cognitive_assessments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."developmental_history"
    ADD CONSTRAINT "developmental_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_clinic_consents"
    ADD CONSTRAINT "patient_clinic_consents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_family_data"
    ADD CONSTRAINT "patient_family_data_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_invitations"
    ADD CONSTRAINT "patient_invitations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_personal_data"
    ADD CONSTRAINT "patient_personal_data_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_visits"
    ADD CONSTRAINT "patient_visits_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patients"
    ADD CONSTRAINT "patients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referrals_and_feedback"
    ADD CONSTRAINT "referrals_and_feedback_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."therapy_sessions"
    ADD CONSTRAINT "therapy_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "appointments_clinic_id_idx" ON "public"."appointments" USING "btree" ("clinic_id");



CREATE INDEX "appointments_clinic_patient_id_idx" ON "public"."appointments" USING "btree" ("clinic_patient_id");



CREATE INDEX "appointments_patient_id_idx" ON "public"."appointments" USING "btree" ("patient_id");



CREATE INDEX "appointments_practitioner_membership_id_idx" ON "public"."appointments" USING "btree" ("practitioner_membership_id");



CREATE INDEX "appointments_start_time_idx" ON "public"."appointments" USING "btree" ("start_time");



CREATE INDEX "clinic_memberships_clinic_idx" ON "public"."clinic_memberships" USING "btree" ("clinic_id");



CREATE INDEX "clinic_memberships_user_idx" ON "public"."clinic_memberships" USING "btree" ("user_id");



CREATE INDEX "clinic_patients_clinic_idx" ON "public"."clinic_patients" USING "btree" ("clinic_id");



CREATE INDEX "clinic_patients_patient_idx" ON "public"."clinic_patients" USING "btree" ("patient_id");



CREATE UNIQUE INDEX "clinics_slug_unique" ON "public"."clinics" USING "btree" ("slug");



CREATE INDEX "cognitive_assessments_clinic_id_idx" ON "public"."cognitive_assessments" USING "btree" ("clinic_id");



CREATE UNIQUE INDEX "cognitive_assessments_visit_id_unique" ON "public"."cognitive_assessments" USING "btree" ("visit_id");



CREATE INDEX "developmental_history_clinic_id_idx" ON "public"."developmental_history" USING "btree" ("clinic_id");



CREATE UNIQUE INDEX "developmental_history_visit_id_unique" ON "public"."developmental_history" USING "btree" ("visit_id");



CREATE UNIQUE INDEX "patient_clinic_consents_active_unique" ON "public"."patient_clinic_consents" USING "btree" ("clinic_id", "patient_id") WHERE ("revoked_at" IS NULL);



CREATE INDEX "patient_clinic_consents_clinic_idx" ON "public"."patient_clinic_consents" USING "btree" ("clinic_id");



CREATE INDEX "patient_clinic_consents_invitation_idx" ON "public"."patient_clinic_consents" USING "btree" ("invitation_id");



CREATE INDEX "patient_clinic_consents_patient_idx" ON "public"."patient_clinic_consents" USING "btree" ("patient_id");



CREATE INDEX "patient_family_data_clinic_patient_idx" ON "public"."patient_family_data" USING "btree" ("clinic_id", "patient_id");



CREATE UNIQUE INDEX "patient_family_data_clinic_patient_unique" ON "public"."patient_family_data" USING "btree" ("clinic_id", "patient_id");



CREATE INDEX "patient_invitations_appointment_idx" ON "public"."patient_invitations" USING "btree" ("appointment_id");



CREATE INDEX "patient_invitations_clinic_id_idx" ON "public"."patient_invitations" USING "btree" ("clinic_id");



CREATE INDEX "patient_invitations_email_idx" ON "public"."patient_invitations" USING "btree" ("email");



CREATE INDEX "patient_invitations_flow_idx" ON "public"."patient_invitations" USING "btree" ("flow");



CREATE INDEX "patient_invitations_session_start_idx" ON "public"."patient_invitations" USING "btree" ("session_start_at");



CREATE INDEX "patient_invitations_target_patient_idx" ON "public"."patient_invitations" USING "btree" ("target_patient_id");



CREATE UNIQUE INDEX "patient_invitations_token_unique" ON "public"."patient_invitations" USING "btree" ("token");



CREATE INDEX "patient_personal_data_clinic_patient_idx" ON "public"."patient_personal_data" USING "btree" ("clinic_id", "patient_id");



CREATE UNIQUE INDEX "patient_personal_data_clinic_patient_unique" ON "public"."patient_personal_data" USING "btree" ("clinic_id", "patient_id");



CREATE UNIQUE INDEX "patient_visits_appointment_id_unique" ON "public"."patient_visits" USING "btree" ("appointment_id");



CREATE INDEX "patient_visits_clinic_id_idx" ON "public"."patient_visits" USING "btree" ("clinic_id");



CREATE INDEX "patient_visits_clinic_patient_id_idx" ON "public"."patient_visits" USING "btree" ("clinic_patient_id");



CREATE INDEX "patient_visits_patient_id_idx" ON "public"."patient_visits" USING "btree" ("patient_id");



CREATE UNIQUE INDEX "patients_mrn_unique" ON "public"."patients" USING "btree" ("mrn");



CREATE INDEX "patients_user_id_idx" ON "public"."patients" USING "btree" ("user_id");



CREATE INDEX "referrals_and_feedback_clinic_id_idx" ON "public"."referrals_and_feedback" USING "btree" ("clinic_id");



CREATE INDEX "referrals_and_feedback_patient_id_idx" ON "public"."referrals_and_feedback" USING "btree" ("patient_id");



CREATE INDEX "referrals_and_feedback_practitioner_membership_idx" ON "public"."referrals_and_feedback" USING "btree" ("practitioner_membership_id");



CREATE INDEX "referrals_and_feedback_secure_pin_idx" ON "public"."referrals_and_feedback" USING "btree" ("secure_pin");



CREATE INDEX "referrals_and_feedback_visit_id_idx" ON "public"."referrals_and_feedback" USING "btree" ("visit_id");



CREATE INDEX "therapy_sessions_clinic_id_idx" ON "public"."therapy_sessions" USING "btree" ("clinic_id");



CREATE INDEX "therapy_sessions_session_date_idx" ON "public"."therapy_sessions" USING "btree" ("session_date");



CREATE INDEX "therapy_sessions_visit_id_idx" ON "public"."therapy_sessions" USING "btree" ("visit_id");



CREATE OR REPLACE TRIGGER "trg_clinic_memberships_sync_profile" BEFORE INSERT OR UPDATE ON "public"."clinic_memberships" FOR EACH ROW EXECUTE FUNCTION "public"."sync_clinic_membership_profile_defaults"();



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_clinic_patient_id_fkey" FOREIGN KEY ("clinic_patient_id") REFERENCES "public"."clinic_patients"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_practitioner_membership_id_fkey" FOREIGN KEY ("practitioner_membership_id") REFERENCES "public"."clinic_memberships"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."clinic_memberships"
    ADD CONSTRAINT "clinic_memberships_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clinic_memberships"
    ADD CONSTRAINT "clinic_memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clinic_patients"
    ADD CONSTRAINT "clinic_patients_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clinic_patients"
    ADD CONSTRAINT "clinic_patients_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clinics"
    ADD CONSTRAINT "clinics_owner_user_id_fkey" FOREIGN KEY ("owner_user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."cognitive_assessments"
    ADD CONSTRAINT "cognitive_assessments_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cognitive_assessments"
    ADD CONSTRAINT "cognitive_assessments_visit_id_fkey" FOREIGN KEY ("visit_id") REFERENCES "public"."patient_visits"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."developmental_history"
    ADD CONSTRAINT "developmental_history_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."developmental_history"
    ADD CONSTRAINT "developmental_history_visit_id_fkey" FOREIGN KEY ("visit_id") REFERENCES "public"."patient_visits"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_clinic_consents"
    ADD CONSTRAINT "patient_clinic_consents_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_clinic_consents"
    ADD CONSTRAINT "patient_clinic_consents_invitation_id_fkey" FOREIGN KEY ("invitation_id") REFERENCES "public"."patient_invitations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."patient_clinic_consents"
    ADD CONSTRAINT "patient_clinic_consents_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_family_data"
    ADD CONSTRAINT "patient_family_data_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_family_data"
    ADD CONSTRAINT "patient_family_data_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_invitations"
    ADD CONSTRAINT "patient_invitations_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "public"."appointments"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."patient_invitations"
    ADD CONSTRAINT "patient_invitations_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_invitations"
    ADD CONSTRAINT "patient_invitations_invited_by_membership_id_fkey" FOREIGN KEY ("invited_by_membership_id") REFERENCES "public"."clinic_memberships"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."patient_invitations"
    ADD CONSTRAINT "patient_invitations_practitioner_membership_id_fkey" FOREIGN KEY ("practitioner_membership_id") REFERENCES "public"."clinic_memberships"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."patient_invitations"
    ADD CONSTRAINT "patient_invitations_replaced_by_invitation_id_fkey" FOREIGN KEY ("replaced_by_invitation_id") REFERENCES "public"."patient_invitations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."patient_invitations"
    ADD CONSTRAINT "patient_invitations_target_patient_id_fkey" FOREIGN KEY ("target_patient_id") REFERENCES "public"."patients"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."patient_personal_data"
    ADD CONSTRAINT "patient_personal_data_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_personal_data"
    ADD CONSTRAINT "patient_personal_data_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_visits"
    ADD CONSTRAINT "patient_visits_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "public"."appointments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_visits"
    ADD CONSTRAINT "patient_visits_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_visits"
    ADD CONSTRAINT "patient_visits_clinic_patient_id_fkey" FOREIGN KEY ("clinic_patient_id") REFERENCES "public"."clinic_patients"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."patient_visits"
    ADD CONSTRAINT "patient_visits_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patients"
    ADD CONSTRAINT "patients_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."referrals_and_feedback"
    ADD CONSTRAINT "referrals_and_feedback_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referrals_and_feedback"
    ADD CONSTRAINT "referrals_and_feedback_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referrals_and_feedback"
    ADD CONSTRAINT "referrals_and_feedback_practitioner_membership_id_fkey" FOREIGN KEY ("practitioner_membership_id") REFERENCES "public"."clinic_memberships"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."referrals_and_feedback"
    ADD CONSTRAINT "referrals_and_feedback_visit_id_fkey" FOREIGN KEY ("visit_id") REFERENCES "public"."patient_visits"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."therapy_sessions"
    ADD CONSTRAINT "therapy_sessions_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."therapy_sessions"
    ADD CONSTRAINT "therapy_sessions_visit_id_fkey" FOREIGN KEY ("visit_id") REFERENCES "public"."patient_visits"("id") ON DELETE CASCADE;



ALTER TABLE "public"."appointments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "appointments_clinic_ops_all" ON "public"."appointments" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."clinic_memberships" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "clinic_memberships_member_select" ON "public"."clinic_memberships" FOR SELECT TO "authenticated" USING ("public"."has_active_membership"("clinic_id"));



CREATE POLICY "clinic_memberships_owner_manage" ON "public"."clinic_memberships" TO "authenticated" USING ("public"."has_owner_access"("clinic_id")) WITH CHECK ("public"."has_owner_access"("clinic_id"));



ALTER TABLE "public"."clinic_patients" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "clinic_patients_ops_all" ON "public"."clinic_patients" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."clinics" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "clinics_member_select" ON "public"."clinics" FOR SELECT TO "authenticated" USING ("public"."has_active_membership"("id"));



CREATE POLICY "clinics_owner_manage" ON "public"."clinics" TO "authenticated" USING ("public"."has_owner_access"("id")) WITH CHECK ("public"."has_owner_access"("id"));



ALTER TABLE "public"."cognitive_assessments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cognitive_assessments_clinic_ops_all" ON "public"."cognitive_assessments" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."developmental_history" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "developmental_history_clinic_ops_all" ON "public"."developmental_history" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."patient_clinic_consents" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_clinic_consents_clinic_ops_all" ON "public"."patient_clinic_consents" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."patient_family_data" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_family_data_clinic_ops_all" ON "public"."patient_family_data" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."patient_invitations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_invitations_clinic_ops_all" ON "public"."patient_invitations" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."patient_personal_data" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_personal_data_clinic_ops_all" ON "public"."patient_personal_data" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."patient_visits" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_visits_clinic_ops_all" ON "public"."patient_visits" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."patients" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patients_clinic_access_all" ON "public"."patients" TO "authenticated" USING ("public"."has_patient_access"("id")) WITH CHECK ("public"."is_portal_staff"());



ALTER TABLE "public"."referrals_and_feedback" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "referrals_and_feedback_clinic_practitioner_all" ON "public"."referrals_and_feedback" TO "authenticated" USING ("public"."has_practitioner_access"("clinic_id")) WITH CHECK ("public"."has_practitioner_access"("clinic_id"));



ALTER TABLE "public"."therapy_sessions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "therapy_sessions_clinic_practitioner_all" ON "public"."therapy_sessions" TO "authenticated" USING ("public"."has_practitioner_access"("clinic_id")) WITH CHECK ("public"."has_practitioner_access"("clinic_id"));



ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "users_select_own" ON "public"."users" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "consent_ip" "text", "consent_user_agent" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "consent_ip" "text", "consent_user_agent" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "consent_ip" "text", "consent_user_agent" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."add_clinic_member_by_email"("target_clinic_id" "uuid", "member_email" "text", "assign_staff" boolean, "assign_practitioner" boolean, "member_profession" "public"."practitioner_profession", "actor_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."add_clinic_member_by_email"("target_clinic_id" "uuid", "member_email" "text", "assign_staff" boolean, "assign_practitioner" boolean, "member_profession" "public"."practitioner_profession", "actor_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_clinic_member_by_email"("target_clinic_id" "uuid", "member_email" "text", "assign_staff" boolean, "assign_practitioner" boolean, "member_profession" "public"."practitioner_profession", "actor_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_patient_from_auth_user"("auth_email" "text", "auth_user_id" "uuid", "invite_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_patient_from_auth_user"("auth_email" "text", "auth_user_id" "uuid", "invite_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_patient_from_auth_user"("auth_email" "text", "auth_user_id" "uuid", "invite_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_patient_invitation_with_schedule"("target_clinic_id" "uuid", "invited_by_membership_id" "uuid", "patient_email" "text", "session_date" "date", "session_time" time without time zone, "duration_minutes" integer, "session_timezone" "text", "invitation_ttl_hours" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."create_patient_invitation_with_schedule"("target_clinic_id" "uuid", "invited_by_membership_id" "uuid", "patient_email" "text", "session_date" "date", "session_time" time without time zone, "duration_minutes" integer, "session_timezone" "text", "invitation_ttl_hours" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_patient_invitation_with_schedule"("target_clinic_id" "uuid", "invited_by_membership_id" "uuid", "patient_email" "text", "session_date" "date", "session_time" time without time zone, "duration_minutes" integer, "session_timezone" "text", "invitation_ttl_hours" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_invitation_by_token"("invite_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_invitation_by_token"("invite_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_invitation_by_token"("invite_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."has_active_membership"("target_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."has_active_membership"("target_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_active_membership"("target_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."has_ops_access"("target_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."has_ops_access"("target_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_ops_access"("target_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."has_owner_access"("target_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."has_owner_access"("target_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_owner_access"("target_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."has_patient_access"("target_patient_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."has_patient_access"("target_patient_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_patient_access"("target_patient_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."has_practitioner_access"("target_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."has_practitioner_access"("target_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_practitioner_access"("target_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_portal_staff"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_portal_staff"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_portal_staff"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."save_therapy_session_entry"("target_clinic_id" "uuid", "target_patient_id" "uuid", "target_visit_id" "uuid", "input_session_date" "date", "input_session_time" time without time zone, "input_activity_type" "text", "input_subject" "text", "input_clinical_notes" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."save_therapy_session_entry"("target_clinic_id" "uuid", "target_patient_id" "uuid", "target_visit_id" "uuid", "input_session_date" "date", "input_session_time" time without time zone, "input_activity_type" "text", "input_subject" "text", "input_clinical_notes" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."save_therapy_session_entry"("target_clinic_id" "uuid", "target_patient_id" "uuid", "target_visit_id" "uuid", "input_session_date" "date", "input_session_time" time without time zone, "input_activity_type" "text", "input_subject" "text", "input_clinical_notes" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."submit_patient_registration"("invite_token" "text", "registration_payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."submit_patient_registration"("invite_token" "text", "registration_payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."submit_patient_registration"("invite_token" "text", "registration_payload" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_clinic_membership_profile_defaults"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_clinic_membership_profile_defaults"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_clinic_membership_profile_defaults"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_patient_registration_by_user_id"("invite_token" "text", "registration_payload" "jsonb", "target_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."update_patient_registration_by_user_id"("invite_token" "text", "registration_payload" "jsonb", "target_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_patient_registration_by_user_id"("invite_token" "text", "registration_payload" "jsonb", "target_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."verify_referral_pin"("referral_id" "uuid", "input_pin" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."verify_referral_pin"("referral_id" "uuid", "input_pin" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."verify_referral_pin"("referral_id" "uuid", "input_pin" "text") TO "service_role";



GRANT ALL ON TABLE "public"."appointments" TO "anon";
GRANT ALL ON TABLE "public"."appointments" TO "authenticated";
GRANT ALL ON TABLE "public"."appointments" TO "service_role";



GRANT ALL ON TABLE "public"."clinic_memberships" TO "anon";
GRANT ALL ON TABLE "public"."clinic_memberships" TO "authenticated";
GRANT ALL ON TABLE "public"."clinic_memberships" TO "service_role";



GRANT ALL ON TABLE "public"."clinic_patients" TO "anon";
GRANT ALL ON TABLE "public"."clinic_patients" TO "authenticated";
GRANT ALL ON TABLE "public"."clinic_patients" TO "service_role";



GRANT ALL ON TABLE "public"."clinics" TO "anon";
GRANT ALL ON TABLE "public"."clinics" TO "authenticated";
GRANT ALL ON TABLE "public"."clinics" TO "service_role";



GRANT ALL ON TABLE "public"."cognitive_assessments" TO "anon";
GRANT ALL ON TABLE "public"."cognitive_assessments" TO "authenticated";
GRANT ALL ON TABLE "public"."cognitive_assessments" TO "service_role";



GRANT ALL ON TABLE "public"."developmental_history" TO "anon";
GRANT ALL ON TABLE "public"."developmental_history" TO "authenticated";
GRANT ALL ON TABLE "public"."developmental_history" TO "service_role";



GRANT ALL ON TABLE "public"."patient_clinic_consents" TO "anon";
GRANT ALL ON TABLE "public"."patient_clinic_consents" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_clinic_consents" TO "service_role";



GRANT ALL ON TABLE "public"."patient_family_data" TO "anon";
GRANT ALL ON TABLE "public"."patient_family_data" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_family_data" TO "service_role";



GRANT ALL ON TABLE "public"."patient_invitations" TO "anon";
GRANT ALL ON TABLE "public"."patient_invitations" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_invitations" TO "service_role";



GRANT ALL ON TABLE "public"."patient_personal_data" TO "anon";
GRANT ALL ON TABLE "public"."patient_personal_data" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_personal_data" TO "service_role";



GRANT ALL ON TABLE "public"."patient_visits" TO "anon";
GRANT ALL ON TABLE "public"."patient_visits" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_visits" TO "service_role";



GRANT ALL ON TABLE "public"."patients" TO "anon";
GRANT ALL ON TABLE "public"."patients" TO "authenticated";
GRANT ALL ON TABLE "public"."patients" TO "service_role";



GRANT ALL ON TABLE "public"."referrals_and_feedback" TO "anon";
GRANT ALL ON TABLE "public"."referrals_and_feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."referrals_and_feedback" TO "service_role";



GRANT ALL ON TABLE "public"."therapy_sessions" TO "anon";
GRANT ALL ON TABLE "public"."therapy_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."therapy_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







