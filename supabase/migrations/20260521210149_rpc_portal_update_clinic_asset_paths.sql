


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


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."adhd_indication" AS ENUM (
    'possible_adhd',
    'not_adhd'
);


ALTER TYPE "public"."adhd_indication" OWNER TO "postgres";


CREATE TYPE "public"."admin_level_enum" AS ENUM (
    'STAFF',
    'ADMIN',
    'SUPER_ADMIN'
);


ALTER TYPE "public"."admin_level_enum" OWNER TO "postgres";


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


CREATE TYPE "public"."clinic_extension_request_status_enum" AS ENUM (
    'PENDING',
    'APPROVED',
    'REJECTED'
);


ALTER TYPE "public"."clinic_extension_request_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."consent_source" AS ENUM (
    'registration_wizard',
    'invite_consent_page',
    'backfill'
);


ALTER TYPE "public"."consent_source" OWNER TO "postgres";


CREATE TYPE "public"."demo_request_status_enum" AS ENUM (
    'pending',
    'contacted',
    'completed',
    'cancelled'
);


ALTER TYPE "public"."demo_request_status_enum" OWNER TO "postgres";


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
    'clinic_staff',
    'patient'
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
    AS $$ declare invitation_row public.patient_invitations%rowtype; clinic_patient_id_value uuid; practitioner_membership_id_value uuid; appointment_id_value uuid; visit_id_value uuid; session_start_at_value timestamptz; session_end_at_value timestamptz; consent_text_value text := 'Saya menyetujui berbagi data medis saya dengan klinik tujuan untuk keperluan layanan psikologi.'; begin if invite_token is null or btrim(invite_token) = '' then return jsonb_build_object('status', 'error', 'code', 'INVALID_TOKEN', 'message', 'Token undangan tidak valid.'); end if; select * into invitation_row from public.patient_invitations pi where pi.token = invite_token limit 1 for update; if not found then return jsonb_build_object('status', 'error', 'code', 'INVITATION_NOT_FOUND', 'message', 'Undangan tidak ditemukan.'); end if; if invitation_row.flow <> 'consent_required'::public.patient_invitation_flow then return jsonb_build_object('status', 'error', 'code', 'INVALID_FLOW', 'message', 'Undangan ini tidak menggunakan flow persetujuan data.'); end if; if coalesce(invitation_row.is_used, false) then if invitation_row.used_reason = 'superseded'::public.patient_invitation_used_reason then return jsonb_build_object('status', 'error', 'code', 'INVITATION_SUPERSEDED', 'message', 'Link undangan ini sudah diganti dengan undangan terbaru.'); end if; return jsonb_build_object('status', 'error', 'code', 'INVITATION_USED', 'message', 'Link undangan sudah digunakan.'); end if; if invitation_row.expires_at < now() then return jsonb_build_object('status', 'error', 'code', 'INVITATION_EXPIRED', 'message', 'Link undangan sudah kedaluwarsa.'); end if; if invitation_row.target_patient_id is null then return jsonb_build_object('status', 'error', 'code', 'PATIENT_NOT_FOUND', 'message', 'Data pasien untuk undangan ini belum tersedia.'); end if; if invitation_row.clinic_id is null then return jsonb_build_object('status', 'error', 'code', 'INVITATION_CLINIC_REQUIRED', 'message', 'Undangan belum terhubung ke klinik.'); end if; practitioner_membership_id_value := invitation_row.practitioner_membership_id; if practitioner_membership_id_value is null or not exists (select 1 from public.clinic_memberships cm where cm.id = practitioner_membership_id_value and cm.is_active = true and cm.is_practitioner = true) then select cm.id into practitioner_membership_id_value from public.clinic_memberships cm where cm.clinic_id = invitation_row.clinic_id and cm.is_active = true and cm.is_practitioner = true order by cm.is_owner desc, cm.created_at asc limit 1; end if; if practitioner_membership_id_value is null then return jsonb_build_object('status', 'error', 'code', 'NO_PRACTITIONER', 'message', 'Tidak ada practitioner aktif pada klinik ini.'); end if; if not exists (select 1 from public.patient_clinic_consents pcc where pcc.clinic_id = invitation_row.clinic_id and pcc.patient_id = invitation_row.target_patient_id and pcc.revoked_at is null) then insert into public.patient_clinic_consents (clinic_id, patient_id, invitation_id, consent_version, consent_text, source, accepted_at, accepted_ip, accepted_user_agent, created_at, updated_at) values (invitation_row.clinic_id, invitation_row.target_patient_id, invitation_row.id, 'v1', consent_text_value, 'invite_consent_page'::public.consent_source, now(), nullif(consent_ip, ''), nullif(consent_user_agent, ''), now(), now()); end if; insert into public.clinic_patients (clinic_id, patient_id, mrn, is_active) values (invitation_row.clinic_id, invitation_row.target_patient_id, coalesce((select p.mrn from public.patients p where p.id = invitation_row.target_patient_id), 'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6))), true) on conflict (clinic_id, patient_id) do update set is_active = true, updated_at = now() returning id into clinic_patient_id_value; appointment_id_value := invitation_row.appointment_id; if appointment_id_value is null then session_start_at_value := coalesce(invitation_row.session_start_at, date_trunc('day', now()) + interval '1 day' + interval '9 hours'); session_end_at_value := coalesce(invitation_row.session_end_at, session_start_at_value + interval '45 minutes'); insert into public.appointments (clinic_id, clinic_patient_id, patient_id, practitioner_membership_id, start_time, end_time, status, notes) values (invitation_row.clinic_id, clinic_patient_id_value, invitation_row.target_patient_id, practitioner_membership_id_value, session_start_at_value, session_end_at_value, 'scheduled', 'Auto-created after consent acceptance') returning id into appointment_id_value; end if; select pv.id into visit_id_value from public.patient_visits pv where pv.appointment_id = appointment_id_value limit 1; if visit_id_value is null then insert into public.patient_visits (clinic_id, clinic_patient_id, patient_id, appointment_id, status) values (invitation_row.clinic_id, clinic_patient_id_value, invitation_row.target_patient_id, appointment_id_value, 'scheduled') returning id into visit_id_value; end if; update public.patient_invitations set is_used = true, used_at = now(), used_reason = 'consent_accepted'::public.patient_invitation_used_reason, appointment_id = appointment_id_value, practitioner_membership_id = practitioner_membership_id_value where id = invitation_row.id; return jsonb_build_object('status', 'success', 'message', 'Persetujuan data berhasil. Jadwal sesi sudah dikonfirmasi.', 'patientId', invitation_row.target_patient_id, 'clinicId', invitation_row.clinic_id, 'appointmentId', appointment_id_value, 'visitId', visit_id_value); exception when others then return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal memproses persetujuan: ' || sqlerrm); end; $$;


ALTER FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "consent_ip" "text", "consent_user_agent" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "signature_id" "uuid", "consent_ip" "text" DEFAULT NULL::"text", "consent_user_agent" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ declare invitation_row public.patient_invitations%rowtype; clinic_patient_id_value uuid; practitioner_membership_id_value uuid; appointment_id_value uuid; visit_id_value uuid; session_start_at_value timestamptz; session_end_at_value timestamptz; consent_text_value text := 'Saya menyetujui berbagi data medis saya dengan klinik tujuan untuk keperluan layanan psikologi.'; begin if invite_token is null or btrim(invite_token) = '' then return jsonb_build_object('status', 'error', 'code', 'INVALID_TOKEN', 'message', 'Token undangan tidak valid.'); end if; if signature_id is null then return jsonb_build_object('status', 'error', 'code', 'SIGNATURE_REQUIRED', 'message', 'Tanda tangan digital wajib diisi.'); end if; select * into invitation_row from public.patient_invitations pi where pi.token = invite_token limit 1 for update; if not found then return jsonb_build_object('status', 'error', 'code', 'INVITATION_NOT_FOUND', 'message', 'Undangan tidak ditemukan.'); end if; if invitation_row.flow <> 'consent_required'::public.patient_invitation_flow then return jsonb_build_object('status', 'error', 'code', 'INVALID_FLOW', 'message', 'Undangan ini tidak menggunakan flow persetujuan data.'); end if; if coalesce(invitation_row.is_used, false) then if invitation_row.used_reason = 'superseded'::public.patient_invitation_used_reason then return jsonb_build_object('status', 'error', 'code', 'INVITATION_SUPERSEDED', 'message', 'Link undangan ini sudah diganti dengan undangan terbaru.'); end if; return jsonb_build_object('status', 'error', 'code', 'INVITATION_USED', 'message', 'Link undangan sudah digunakan.'); end if; if invitation_row.expires_at < now() then return jsonb_build_object('status', 'error', 'code', 'INVITATION_EXPIRED', 'message', 'Link undangan sudah kedaluwarsa.'); end if; if invitation_row.target_patient_id is null then return jsonb_build_object('status', 'error', 'code', 'PATIENT_NOT_FOUND', 'message', 'Data pasien untuk undangan ini belum tersedia.'); end if; if invitation_row.clinic_id is null then return jsonb_build_object('status', 'error', 'code', 'INVITATION_CLINIC_REQUIRED', 'message', 'Undangan belum terhubung ke klinik.'); end if; if not exists (select 1 from public.patient_signatures ps where ps.id = signature_id and ps.patient_id = invitation_row.target_patient_id) then return jsonb_build_object('status', 'error', 'code', 'SIGNATURE_INVALID', 'message', 'Tanda tangan digital tidak valid untuk pasien ini.'); end if; practitioner_membership_id_value := invitation_row.practitioner_membership_id; if practitioner_membership_id_value is null or not exists (select 1 from public.clinic_memberships cm where cm.id = practitioner_membership_id_value and cm.is_active = true and cm.is_practitioner = true) then select cm.id into practitioner_membership_id_value from public.clinic_memberships cm where cm.clinic_id = invitation_row.clinic_id and cm.is_active = true and cm.is_practitioner = true order by cm.is_owner desc, cm.created_at asc limit 1; end if; if practitioner_membership_id_value is null then return jsonb_build_object('status', 'error', 'code', 'NO_PRACTITIONER', 'message', 'Tidak ada practitioner aktif pada klinik ini.'); end if; if not exists (select 1 from public.patient_clinic_consents pcc where pcc.clinic_id = invitation_row.clinic_id and pcc.patient_id = invitation_row.target_patient_id and pcc.revoked_at is null) then insert into public.patient_clinic_consents (clinic_id, patient_id, invitation_id, consent_version, consent_text, source, accepted_at, accepted_ip, accepted_user_agent, signature_id, created_at, updated_at) values (invitation_row.clinic_id, invitation_row.target_patient_id, invitation_row.id, 'v1', consent_text_value, 'invite_consent_page'::public.consent_source, now(), nullif(consent_ip, ''), nullif(consent_user_agent, ''), signature_id, now(), now()); end if; insert into public.clinic_patients (clinic_id, patient_id, mrn, is_active) values (invitation_row.clinic_id, invitation_row.target_patient_id, coalesce((select p.mrn from public.patients p where p.id = invitation_row.target_patient_id), 'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6))), true) on conflict (clinic_id, patient_id) do update set is_active = true, updated_at = now() returning id into clinic_patient_id_value; appointment_id_value := invitation_row.appointment_id; if appointment_id_value is null then session_start_at_value := coalesce(invitation_row.session_start_at, date_trunc('day', now()) + interval '1 day' + interval '9 hours'); session_end_at_value := coalesce(invitation_row.session_end_at, session_start_at_value + interval '45 minutes'); insert into public.appointments (clinic_id, clinic_patient_id, patient_id, practitioner_membership_id, start_time, end_time, status, notes) values (invitation_row.clinic_id, clinic_patient_id_value, invitation_row.target_patient_id, practitioner_membership_id_value, session_start_at_value, session_end_at_value, 'scheduled', 'Auto-created after consent acceptance') returning id into appointment_id_value; end if; select pv.id into visit_id_value from public.patient_visits pv where pv.appointment_id = appointment_id_value limit 1; if visit_id_value is null then insert into public.patient_visits (clinic_id, clinic_patient_id, patient_id, appointment_id, status) values (invitation_row.clinic_id, clinic_patient_id_value, invitation_row.target_patient_id, appointment_id_value, 'scheduled') returning id into visit_id_value; end if; update public.patient_invitations set is_used = true, used_at = now(), used_reason = 'consent_accepted'::public.patient_invitation_used_reason, appointment_id = appointment_id_value, practitioner_membership_id = practitioner_membership_id_value where id = invitation_row.id; return jsonb_build_object('status', 'success', 'message', 'Persetujuan data berhasil. Jadwal sesi sudah dikonfirmasi.', 'patientId', invitation_row.target_patient_id, 'clinicId', invitation_row.clinic_id, 'appointmentId', appointment_id_value, 'visitId', visit_id_value); exception when others then return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal memproses persetujuan: ' || sqlerrm); end; $$;


ALTER FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "signature_id" "uuid", "consent_ip" "text", "consent_user_agent" "text") OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "public"."admin_add_clinic_member"("p_clinic_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_is_staff" boolean DEFAULT false, "p_is_practitioner" boolean DEFAULT false, "p_profession" "public"."practitioner_profession" DEFAULT NULL::"public"."practitioner_profession") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ DECLARE v_membership_id uuid; v_profession public.practitioner_profession; BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RETURN jsonb_build_object('status', 'error', 'code', 'FORBIDDEN', 'message', 'Caller is not an LBSD admin.'); END IF; IF NOT EXISTS (SELECT 1 FROM public.clinics WHERE id = p_clinic_id) THEN RETURN jsonb_build_object('status', 'error', 'code', 'CLINIC_NOT_FOUND', 'message', 'Clinic does not exist.'); END IF; v_profession := CASE WHEN p_is_practitioner THEN COALESCE(p_profession, 'psychologist'::public.practitioner_profession) ELSE NULL END; INSERT INTO public.users (id, role) VALUES (p_user_id, 'clinic_staff'::public.user_role) ON CONFLICT (id) DO UPDATE SET role = 'clinic_staff'::public.user_role, updated_at = now(); INSERT INTO public.clinic_memberships (clinic_id, user_id, is_owner, is_staff, is_practitioner, profession, full_name, email, is_active) VALUES (p_clinic_id, p_user_id, false, p_is_staff, p_is_practitioner, v_profession, p_full_name, p_email, true) ON CONFLICT (clinic_id, user_id) DO UPDATE SET is_staff = EXCLUDED.is_staff, is_practitioner = EXCLUDED.is_practitioner, profession = EXCLUDED.profession, full_name = EXCLUDED.full_name, email = EXCLUDED.email, is_active = true, updated_at = now() RETURNING id INTO v_membership_id; RETURN jsonb_build_object('status', 'success', 'message', 'Member added successfully.', 'membershipId', v_membership_id, 'userId', p_user_id); EXCEPTION WHEN others THEN RETURN jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Failed to add member: ' || SQLERRM); END; $$;


ALTER FUNCTION "public"."admin_add_clinic_member"("p_clinic_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_is_staff" boolean, "p_is_practitioner" boolean, "p_profession" "public"."practitioner_profession") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_get_clinic_detail"("p_clinic_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ DECLARE v_result jsonb; BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RETURN jsonb_build_object('status','error','code','FORBIDDEN','message','Caller is not an LBSD admin.'); END IF; SELECT jsonb_build_object('clinic_id', c.id, 'clinic_name', c.name, 'clinic_slug', c.slug, 'is_active', c.is_active, 'owner_user_id', c.owner_user_id, 'created_at', c.created_at, 'memberships', COALESCE((SELECT jsonb_agg(jsonb_build_object('membership_id', cm.id, 'user_id', cm.user_id, 'full_name', COALESCE(cm.full_name, SPLIT_PART(au.email, '@', 1)), 'email', COALESCE(cm.email, LOWER(au.email)), 'phone', cm.phone, 'is_owner', cm.is_owner, 'is_staff', cm.is_staff, 'is_practitioner', cm.is_practitioner, 'profession', cm.profession, 'is_active', cm.is_active, 'created_at', cm.created_at) ORDER BY cm.is_owner DESC, cm.created_at ASC) FROM public.clinic_memberships cm LEFT JOIN auth.users au ON au.id = cm.user_id WHERE cm.clinic_id = c.id), '[]'::jsonb)) INTO v_result FROM public.clinics c WHERE c.id = p_clinic_id; IF v_result IS NULL THEN RETURN jsonb_build_object('status','error','code','NOT_FOUND','message','Clinic not found.'); END IF; RETURN v_result; END; $$;


ALTER FUNCTION "public"."admin_get_clinic_detail"("p_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_list_clinics"() RETURNS TABLE("clinic_id" "uuid", "clinic_name" "text", "clinic_slug" "text", "is_active" boolean, "owner_name" "text", "owner_email" "text", "total_memberships" bigint, "active_memberships" bigint, "created_at" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ SELECT c.id, c.name, c.slug::text, c.is_active, COALESCE(cm_owner.full_name, au.raw_user_meta_data->>'full_name', au.raw_user_meta_data->>'name', SPLIT_PART(au.email, '@', 1)) AS owner_name, COALESCE(cm_owner.email, LOWER(au.email)) AS owner_email, COUNT(cm.id) AS total_memberships, COUNT(cm.id) FILTER (WHERE cm.is_active = true) AS active_memberships, c.created_at FROM public.clinics c LEFT JOIN LATERAL (SELECT cm2.user_id, cm2.full_name, cm2.email FROM public.clinic_memberships cm2 WHERE cm2.clinic_id = c.id AND cm2.is_owner = true AND cm2.is_active = true ORDER BY cm2.created_at ASC LIMIT 1) cm_owner ON true LEFT JOIN auth.users au ON au.id = cm_owner.user_id LEFT JOIN public.clinic_memberships cm ON cm.clinic_id = c.id WHERE public.is_admin_at_least('STAFF') GROUP BY c.id, c.name, c.slug, c.is_active, c.created_at, cm_owner.full_name, cm_owner.email, au.raw_user_meta_data, au.email ORDER BY c.created_at DESC; $$;


ALTER FUNCTION "public"."admin_list_clinics"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."approve_clinic_extension_request"("p_request_id" "uuid", "p_added_days" integer) RETURNS TABLE("request_id" "uuid", "clinic_id" "uuid", "approved_at" timestamp with time zone, "new_expired_date" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$ DECLARE v_request public.clinic_extension_requests%ROWTYPE; v_current_expired_date timestamptz; v_approved_at timestamptz := timezone('utc', now()); v_new_expired_date timestamptz; BEGIN IF NOT public.is_admin_at_least('ADMIN') THEN RAISE EXCEPTION 'Hanya admin yang dapat menyetujui pengajuan perpanjangan.'; END IF; IF coalesce(p_added_days, 0) <= 0 THEN RAISE EXCEPTION 'Durasi perpanjangan harus lebih dari 0 hari.'; END IF; SELECT * INTO v_request FROM public.clinic_extension_requests cer WHERE cer.id = p_request_id FOR UPDATE; IF v_request.id IS NULL THEN RAISE EXCEPTION 'Pengajuan perpanjangan tidak ditemukan.'; END IF; IF v_request.status <> 'PENDING' THEN RAISE EXCEPTION 'Hanya pengajuan berstatus PENDING yang dapat disetujui.'; END IF; SELECT c.expired_date INTO v_current_expired_date FROM public.clinics c WHERE c.id = v_request.clinic_id FOR UPDATE; v_new_expired_date := (CASE WHEN v_current_expired_date IS NULL OR v_current_expired_date < v_approved_at THEN v_approved_at ELSE v_current_expired_date END) + make_interval(days => p_added_days); UPDATE public.clinic_extension_requests SET status = 'APPROVED', approved_at = v_approved_at, approved_by = auth.uid(), added_days = p_added_days WHERE id = v_request.id; UPDATE public.clinics SET expired_date = v_new_expired_date, updated_at = timezone('utc', now()) WHERE id = v_request.clinic_id; RETURN QUERY SELECT v_request.id, v_request.clinic_id, v_approved_at, v_new_expired_date; END; $$;


ALTER FUNCTION "public"."approve_clinic_extension_request"("p_request_id" "uuid", "p_added_days" integer) OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text" DEFAULT NULL::"text", "owner_user_id" "uuid" DEFAULT "auth"."uid"(), "permit_number" "text" DEFAULT NULL::"text", "owner_ktp_number" "text" DEFAULT NULL::"text", "phone_number" "text" DEFAULT NULL::"text", "address_line" "text" DEFAULT NULL::"text", "rt_rw" "text" DEFAULT NULL::"text", "province_name" "text" DEFAULT NULL::"text", "city_name" "text" DEFAULT NULL::"text", "district_name" "text" DEFAULT NULL::"text", "subdistrict_name" "text" DEFAULT NULL::"text", "postal_code" "text" DEFAULT NULL::"text", "expired_date" timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ declare normalized_name text; base_slug text; final_slug text; suffix int := 0; created_clinic_id uuid; existing_clinic_id uuid; owner_membership_id uuid; begin if owner_user_id is null then return jsonb_build_object('status', 'error', 'code', 'AUTH_REQUIRED', 'message', 'Akun login tidak ditemukan.'); end if; normalized_name := nullif(btrim(clinic_name), ''); if normalized_name is null then return jsonb_build_object('status', 'error', 'code', 'INVALID_CLINIC_NAME', 'message', 'Nama klinik wajib diisi.'); end if; base_slug := nullif(regexp_replace(lower(coalesce(clinic_slug, normalized_name)), '[^a-z0-9]+', '-', 'g'), ''); base_slug := trim(both '-' from coalesce(base_slug, 'clinic')); if base_slug = '' then base_slug := 'clinic'; end if; final_slug := base_slug; while exists (select 1 from public.clinics c where c.slug = final_slug) loop suffix := suffix + 1; final_slug := base_slug || '-' || suffix::text; end loop; insert into public.users (id, role) values (owner_user_id, 'clinic_staff'::public.user_role) on conflict (id) do update set role = 'clinic_staff'::public.user_role, updated_at = now(); select cm.clinic_id, cm.id into existing_clinic_id, owner_membership_id from public.clinic_memberships cm where cm.user_id = owner_user_id and cm.is_owner = true and cm.is_active = true order by cm.created_at asc limit 1; if existing_clinic_id is not null then update public.clinics c set permit_number = coalesce(nullif(btrim(create_clinic_with_owner.permit_number), ''), c.permit_number), owner_ktp_number = coalesce(nullif(btrim(create_clinic_with_owner.owner_ktp_number), ''), c.owner_ktp_number), phone_number = coalesce(nullif(btrim(create_clinic_with_owner.phone_number), ''), c.phone_number), address_line = coalesce(nullif(btrim(create_clinic_with_owner.address_line), ''), c.address_line), rt_rw = coalesce(nullif(btrim(create_clinic_with_owner.rt_rw), ''), c.rt_rw), province_name = coalesce(nullif(btrim(create_clinic_with_owner.province_name), ''), c.province_name), city_name = coalesce(nullif(btrim(create_clinic_with_owner.city_name), ''), c.city_name), district_name = coalesce(nullif(btrim(create_clinic_with_owner.district_name), ''), c.district_name), subdistrict_name = coalesce(nullif(btrim(create_clinic_with_owner.subdistrict_name), ''), c.subdistrict_name), postal_code = coalesce(nullif(btrim(create_clinic_with_owner.postal_code), ''), c.postal_code), expired_date = coalesce(create_clinic_with_owner.expired_date, c.expired_date), updated_at = now() where c.id = existing_clinic_id; return jsonb_build_object('status', 'success', 'message', 'Owner sudah memiliki klinik aktif.', 'clinicId', existing_clinic_id, 'membershipId', owner_membership_id); end if; insert into public.clinics (name, slug, owner_user_id, expired_date, permit_number, owner_ktp_number, phone_number, address_line, rt_rw, province_name, city_name, district_name, subdistrict_name, postal_code) values (normalized_name, final_slug, owner_user_id, create_clinic_with_owner.expired_date, nullif(btrim(create_clinic_with_owner.permit_number), ''), nullif(btrim(create_clinic_with_owner.owner_ktp_number), ''), nullif(btrim(create_clinic_with_owner.phone_number), ''), nullif(btrim(create_clinic_with_owner.address_line), ''), nullif(btrim(create_clinic_with_owner.rt_rw), ''), nullif(btrim(create_clinic_with_owner.province_name), ''), nullif(btrim(create_clinic_with_owner.city_name), ''), nullif(btrim(create_clinic_with_owner.district_name), ''), nullif(btrim(create_clinic_with_owner.subdistrict_name), ''), nullif(btrim(create_clinic_with_owner.postal_code), '')) returning id into created_clinic_id; insert into public.clinic_memberships (clinic_id, user_id, is_owner, is_staff, is_practitioner, profession, is_active) values (created_clinic_id, owner_user_id, true, true, true, 'psychologist'::public.practitioner_profession, true) returning id into owner_membership_id; return jsonb_build_object('status', 'success', 'message', 'Klinik berhasil dibuat.', 'clinicId', created_clinic_id, 'membershipId', owner_membership_id); exception when others then return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal membuat klinik: ' || sqlerrm); end; $$;


ALTER FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid", "permit_number" "text", "owner_ktp_number" "text", "phone_number" "text", "address_line" "text", "rt_rw" "text", "province_name" "text", "city_name" "text", "district_name" "text", "subdistrict_name" "text", "postal_code" "text", "expired_date" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text" DEFAULT NULL::"text", "owner_user_id" "uuid" DEFAULT "auth"."uid"(), "permit_number" "text" DEFAULT NULL::"text", "owner_ktp_number" "text" DEFAULT NULL::"text", "phone_number" "text" DEFAULT NULL::"text", "address_line" "text" DEFAULT NULL::"text", "rt_rw" "text" DEFAULT NULL::"text", "province_name" "text" DEFAULT NULL::"text", "city_name" "text" DEFAULT NULL::"text", "district_name" "text" DEFAULT NULL::"text", "subdistrict_name" "text" DEFAULT NULL::"text", "postal_code" "text" DEFAULT NULL::"text", "full_address" "text" DEFAULT NULL::"text", "expired_date" timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ declare normalized_name text; base_slug text; final_slug text; suffix int := 0; created_clinic_id uuid; existing_clinic_id uuid; owner_membership_id uuid; begin if owner_user_id is null then return jsonb_build_object('status', 'error', 'code', 'AUTH_REQUIRED', 'message', 'Akun login tidak ditemukan.'); end if; normalized_name := nullif(btrim(clinic_name), ''); if normalized_name is null then return jsonb_build_object('status', 'error', 'code', 'INVALID_CLINIC_NAME', 'message', 'Nama klinik wajib diisi.'); end if; base_slug := nullif(regexp_replace(lower(coalesce(clinic_slug, normalized_name)), '[^a-z0-9]+', '-', 'g'), ''); base_slug := trim(both '-' from coalesce(base_slug, 'clinic')); if base_slug = '' then base_slug := 'clinic'; end if; final_slug := base_slug; while exists (select 1 from public.clinics c where c.slug = final_slug) loop suffix := suffix + 1; final_slug := base_slug || '-' || suffix::text; end loop; insert into public.users (id, role) values (owner_user_id, 'clinic_staff'::public.user_role) on conflict (id) do update set role = 'clinic_staff'::public.user_role, updated_at = now(); select cm.clinic_id, cm.id into existing_clinic_id, owner_membership_id from public.clinic_memberships cm where cm.user_id = owner_user_id and cm.is_owner = true and cm.is_active = true order by cm.created_at asc limit 1; if existing_clinic_id is not null then update public.clinics c set permit_number = coalesce(nullif(btrim(create_clinic_with_owner.permit_number), ''), c.permit_number), owner_ktp_number = coalesce(nullif(btrim(create_clinic_with_owner.owner_ktp_number), ''), c.owner_ktp_number), phone_number = coalesce(nullif(btrim(create_clinic_with_owner.phone_number), ''), c.phone_number), address_line = coalesce(nullif(btrim(create_clinic_with_owner.address_line), ''), c.address_line), rt_rw = coalesce(nullif(btrim(create_clinic_with_owner.rt_rw), ''), c.rt_rw), province_name = coalesce(nullif(btrim(create_clinic_with_owner.province_name), ''), c.province_name), city_name = coalesce(nullif(btrim(create_clinic_with_owner.city_name), ''), c.city_name), district_name = coalesce(nullif(btrim(create_clinic_with_owner.district_name), ''), c.district_name), subdistrict_name = coalesce(nullif(btrim(create_clinic_with_owner.subdistrict_name), ''), c.subdistrict_name), postal_code = coalesce(nullif(btrim(create_clinic_with_owner.postal_code), ''), c.postal_code), full_address = coalesce(nullif(btrim(create_clinic_with_owner.full_address), ''), c.full_address), expired_date = coalesce(create_clinic_with_owner.expired_date, c.expired_date), updated_at = now() where c.id = existing_clinic_id; return jsonb_build_object('status', 'success', 'message', 'Owner sudah memiliki klinik aktif.', 'clinicId', existing_clinic_id, 'membershipId', owner_membership_id); end if; insert into public.clinics (name, slug, owner_user_id, expired_date, permit_number, owner_ktp_number, phone_number, address_line, rt_rw, province_name, city_name, district_name, subdistrict_name, postal_code, full_address) values (normalized_name, final_slug, owner_user_id, create_clinic_with_owner.expired_date, nullif(btrim(create_clinic_with_owner.permit_number), ''), nullif(btrim(create_clinic_with_owner.owner_ktp_number), ''), nullif(btrim(create_clinic_with_owner.phone_number), ''), nullif(btrim(create_clinic_with_owner.address_line), ''), nullif(btrim(create_clinic_with_owner.rt_rw), ''), nullif(btrim(create_clinic_with_owner.province_name), ''), nullif(btrim(create_clinic_with_owner.city_name), ''), nullif(btrim(create_clinic_with_owner.district_name), ''), nullif(btrim(create_clinic_with_owner.subdistrict_name), ''), nullif(btrim(create_clinic_with_owner.postal_code), ''), nullif(btrim(create_clinic_with_owner.full_address), '')) returning id into created_clinic_id; insert into public.clinic_memberships (clinic_id, user_id, is_owner, is_staff, is_practitioner, profession, is_active) values (created_clinic_id, owner_user_id, true, true, true, 'psychologist'::public.practitioner_profession, true) returning id into owner_membership_id; return jsonb_build_object('status', 'success', 'message', 'Klinik berhasil dibuat.', 'clinicId', created_clinic_id, 'membershipId', owner_membership_id); exception when others then return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal membuat klinik: ' || sqlerrm); end; $$;


ALTER FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid", "permit_number" "text", "owner_ktp_number" "text", "phone_number" "text", "address_line" "text", "rt_rw" "text", "province_name" "text", "city_name" "text", "district_name" "text", "subdistrict_name" "text", "postal_code" "text", "full_address" "text", "expired_date" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_patient_from_auth_user"("auth_email" "text", "auth_user_id" "uuid", "invite_token" "text", "auth_phone" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  invitation_row public.patient_invitations%rowtype;
  auth_user_email text;
  auth_user_phone text;
  auth_user_full_name text;
  patient_id_value uuid;
  mrn_value text;
begin
  if invite_token is null or btrim(invite_token) = '' then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_TOKEN', 'message', 'Token registrasi tidak valid.');
  end if;

  if auth_user_id is null then
    return jsonb_build_object('status', 'error', 'code', 'AUTH_USER_REQUIRED', 'message', 'Akun login pasien tidak ditemukan.');
  end if;

  select * into invitation_row
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

  if invitation_row.contact_type = 'phone' then
    select au.phone,
           coalesce(au.raw_user_meta_data ->> 'full_name', split_part(coalesce(au.phone, auth_phone, invitation_row.phone, 'Pasien'), '@', 1))
    into auth_user_phone, auth_user_full_name
    from auth.users au where au.id = auth_user_id limit 1;

    if auth_user_phone is null then
      return jsonb_build_object('status', 'error', 'code', 'AUTH_USER_NOT_FOUND', 'message', 'User auth pasien tidak ditemukan.');
    end if;
  else
    if auth_email is null or btrim(auth_email) = '' then
      return jsonb_build_object('status', 'error', 'code', 'AUTH_EMAIL_REQUIRED', 'message', 'Email akun login pasien tidak ditemukan.');
    end if;

    select au.email,
           coalesce(au.raw_user_meta_data ->> 'full_name', split_part(coalesce(au.email, auth_email, invitation_row.email, 'Pasien'), '@', 1))
    into auth_user_email, auth_user_full_name
    from auth.users au where au.id = auth_user_id limit 1;

    if auth_user_email is null then
      return jsonb_build_object('status', 'error', 'code', 'AUTH_USER_NOT_FOUND', 'message', 'User auth pasien tidak ditemukan.');
    end if;

    if lower(btrim(auth_email)) <> lower(btrim(auth_user_email))
       or lower(btrim(auth_email)) <> lower(btrim(invitation_row.email)) then
      return jsonb_build_object('status', 'error', 'code', 'EMAIL_MISMATCH', 'message', 'Email akun tidak cocok dengan email undangan.');
    end if;
  end if;

  insert into public.users (id, role)
  values (auth_user_id, 'patient'::public.user_role)
  on conflict (id) do update
    set role = case
      when public.users.role::text = 'clinic_staff' then public.users.role
      else 'patient'::public.user_role
    end,
    updated_at = now();

  select p.id into patient_id_value
  from public.patients p where p.user_id = auth_user_id limit 1;

  if patient_id_value is null then
    select 'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || lpad((floor(random() * 9000) + 1000)::text, 4, '0')
    into mrn_value;

    insert into public.patients (user_id, mrn, full_name, email, phone, created_at, updated_at)
    values (
      auth_user_id,
      mrn_value,
      coalesce(nullif(auth_user_full_name, ''), 'Pasien Tanpa Nama'),
      coalesce(invitation_row.email, auth_user_email),
      coalesce(invitation_row.phone, auth_user_phone, auth_phone),
      now(),
      now()
    )
    returning id into patient_id_value;
  end if;

  update public.patient_invitations
  set target_patient_id = patient_id_value
  where token = invite_token;

  return jsonb_build_object('status', 'success', 'message', 'Akun pasien berhasil disiapkan.');
end;
$$;


ALTER FUNCTION "public"."create_patient_from_auth_user"("auth_email" "text", "auth_user_id" "uuid", "invite_token" "text", "auth_phone" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_patient_invitation_with_schedule"("target_clinic_id" "uuid", "invited_by_membership_id" "uuid", "patient_email" "text" DEFAULT NULL::"text", "patient_phone" "text" DEFAULT NULL::"text", "contact_type" "text" DEFAULT 'email'::"text", "session_date" "date" DEFAULT NULL::"date", "session_time" time without time zone DEFAULT NULL::time without time zone, "duration_minutes" integer DEFAULT 45, "session_timezone" "text" DEFAULT 'Asia/Jakarta'::"text", "invitation_ttl_hours" integer DEFAULT 72) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  normalized_email text;
  normalized_phone text;
  resolved_contact_type text;
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
  token_seed text;
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
    select 1 from public.clinic_memberships cm
    where cm.id = invited_by_membership_id
      and cm.clinic_id = target_clinic_id
      and cm.user_id = auth.uid()
      and cm.is_active = true
  ) then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_MEMBERSHIP', 'message', 'Membership pengundang tidak ditemukan pada klinik aktif.');
  end if;

  select c.name into clinic_name_value
  from public.clinics c
  where c.id = target_clinic_id and c.is_active = true
  limit 1;

  if clinic_name_value is null then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_CLINIC', 'message', 'Klinik tidak aktif atau tidak ditemukan.');
  end if;

  resolved_contact_type := coalesce(nullif(btrim(contact_type), ''), 'email');

  if resolved_contact_type = 'email' then
    normalized_email := lower(btrim(patient_email));
    if normalized_email is null or normalized_email = '' then
      return jsonb_build_object('status', 'error', 'code', 'INVALID_EMAIL', 'message', 'Email pasien wajib diisi.');
    end if;
    token_seed := normalized_email;
  else
    normalized_phone := btrim(patient_phone);
    if normalized_phone is null or normalized_phone = '' then
      return jsonb_build_object('status', 'error', 'code', 'INVALID_PHONE', 'message', 'Nomor HP pasien wajib diisi.');
    end if;
    token_seed := normalized_phone;
  end if;

  if session_date is null or session_time is null then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_SCHEDULE', 'message', 'Tanggal dan waktu sesi wajib diisi.');
  end if;

  if duration_minutes is null or duration_minutes < 15 or duration_minutes > 180 then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_DURATION', 'message', 'Durasi sesi harus di antara 15 dan 180 menit.');
  end if;

  session_timezone_value := coalesce(nullif(btrim(session_timezone), ''), 'Asia/Jakarta');
  expires_at_value := now() + make_interval(hours => greatest(invitation_ttl_hours, 1));
  token_value := md5(random()::text || clock_timestamp()::text || token_seed || coalesce(auth.uid()::text, ''))
    || md5(random()::text || clock_timestamp()::text || txid_current()::text);
  session_start_at_value := ((session_date::timestamp + session_time) at time zone session_timezone_value);
  session_end_at_value := session_start_at_value + make_interval(mins => duration_minutes);

  select cm.id into practitioner_membership_id_value
  from public.clinic_memberships cm
  where cm.clinic_id = target_clinic_id
    and cm.is_active = true
    and cm.is_practitioner = true
  order by cm.is_owner desc, cm.created_at asc
  limit 1;

  if practitioner_membership_id_value is null then
    return jsonb_build_object('status', 'error', 'code', 'NO_PRACTITIONER', 'message', 'Tidak ada practitioner aktif pada klinik ini.');
  end if;

  if resolved_contact_type = 'phone' then
    resolved_flow := 'registration_required'::public.patient_invitation_flow;
    patient_id_value := null;
  else
    select au.id, p.id
    into auth_user_id_value, patient_id_value
    from auth.users au
    left join public.patients p on p.user_id = au.id
    where lower(au.email) = normalized_email
    order by p.created_at asc nulls last
    limit 1;

    if auth_user_id_value is null or patient_id_value is null then
      resolved_flow := 'registration_required'::public.patient_invitation_flow;
      patient_id_value := null;
    else
      select exists (
        select 1 from public.patient_clinic_consents pcc
        where pcc.clinic_id = target_clinic_id
          and pcc.patient_id = patient_id_value
          and pcc.revoked_at is null
      ) into has_active_consent;

      if has_active_consent then
        resolved_flow := 'info_only'::public.patient_invitation_flow;
      else
        resolved_flow := 'consent_required'::public.patient_invitation_flow;
      end if;
    end if;
  end if;

  if resolved_contact_type = 'email' then
    update public.patient_invitations pi
    set is_used = true, used_at = now(),
        used_reason = 'superseded'::public.patient_invitation_used_reason,
        replaced_by_invitation_id = null
    where pi.clinic_id = target_clinic_id
      and pi.contact_type = 'email'
      and lower(pi.email) = normalized_email
      and pi.is_used = false;
  else
    update public.patient_invitations pi
    set is_used = true, used_at = now(),
        used_reason = 'superseded'::public.patient_invitation_used_reason,
        replaced_by_invitation_id = null
    where pi.clinic_id = target_clinic_id
      and pi.contact_type = 'phone'
      and pi.phone = normalized_phone
      and pi.is_used = false;
  end if;

  insert into public.patient_invitations (
    clinic_id, invited_by_membership_id,
    email, phone, contact_type,
    token, expires_at, flow,
    target_patient_id, practitioner_membership_id,
    session_start_at, session_end_at, session_timezone
  ) values (
    target_clinic_id, invited_by_membership_id,
    normalized_email, normalized_phone, resolved_contact_type,
    token_value, expires_at_value, resolved_flow,
    patient_id_value, practitioner_membership_id_value,
    session_start_at_value, session_end_at_value, session_timezone_value
  ) returning id into invitation_id_value;

  if resolved_flow = 'info_only'::public.patient_invitation_flow then
    update public.patient_invitations
    set is_used = true, used_at = now(),
        used_reason = 'info_only_notified'::public.patient_invitation_used_reason
    where id = invitation_id_value;
  end if;

  return jsonb_build_object(
    'status', 'success',
    'flow', resolved_flow::text,
    'token', token_value,
    'invitationId', invitation_id_value::text
  );
end;
$$;


ALTER FUNCTION "public"."create_patient_invitation_with_schedule"("target_clinic_id" "uuid", "invited_by_membership_id" "uuid", "patient_email" "text", "patient_phone" "text", "contact_type" "text", "session_date" "date", "session_time" time without time zone, "duration_minutes" integer, "session_timezone" "text", "invitation_ttl_hours" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."edge_check_rate_limit"("p_function_name" "text", "p_identifier" "text", "p_window_seconds" integer, "p_limit" integer) RETURNS TABLE("allowed" boolean, "current_count" integer, "retry_after_seconds" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_now timestamptz := now();
  v_window_start timestamptz;
  v_current_count integer;
  v_oldest_in_window timestamptz;
BEGIN
  IF coalesce(trim(p_function_name), '') = '' OR coalesce(trim(p_identifier), '') = '' THEN
    RAISE EXCEPTION 'function_name and identifier are required';
  END IF;
  IF p_window_seconds <= 0 OR p_limit <= 0 THEN
    RAISE EXCEPTION 'window_seconds and limit must be positive';
  END IF;

  v_window_start := v_now - make_interval(secs => p_window_seconds);

  DELETE FROM public.edge_rate_limit_events
  WHERE function_name = p_function_name
    AND identifier = p_identifier
    AND created_at < v_window_start;

  SELECT count(*), min(created_at)
  INTO v_current_count, v_oldest_in_window
  FROM public.edge_rate_limit_events
  WHERE function_name = p_function_name
    AND identifier = p_identifier
    AND created_at >= v_window_start;

  IF v_current_count < p_limit THEN
    INSERT INTO public.edge_rate_limit_events(function_name, identifier, created_at)
    VALUES (p_function_name, p_identifier, v_now);
    RETURN QUERY SELECT true, v_current_count + 1, 0;
  ELSE
    RETURN QUERY
    SELECT false, v_current_count,
      GREATEST(0, p_window_seconds - floor(extract(epoch from (v_now - v_oldest_in_window)))::integer);
  END IF;
END;
$$;


ALTER FUNCTION "public"."edge_check_rate_limit"("p_function_name" "text", "p_identifier" "text", "p_window_seconds" integer, "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_b2b_update_reminder"("p_clinic_id" "uuid") RETURNS "jsonb"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ SELECT jsonb_build_object('should_show', COALESCE(t.updated_at > COALESCE(a.signed_at::timestamptz, '-infinity'::timestamptz) AND t.updated_at > now() - interval '7 days', false), 'message', 'Dokumen PKS telah diperbarui. Silakan tandatangani ulang di halaman Profil Klinik.') FROM public.b2b_agreement_templates t LEFT JOIN public.b2b_agreements a ON a.clinic_id = p_clinic_id AND a.id = (SELECT id FROM public.b2b_agreements WHERE clinic_id = p_clinic_id ORDER BY signed_at DESC LIMIT 1) WHERE t.is_active = true LIMIT 1; $$;


ALTER FUNCTION "public"."get_b2b_update_reminder"("p_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_clinics_with_pending_extension"() RETURNS TABLE("id" "uuid", "name" "text", "slug" character varying, "is_active" boolean, "owner_user_id" "uuid", "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "expired_date" timestamp with time zone, "is_agreement_signed" boolean, "permit_number" "text", "owner_ktp_number" "text", "phone_number" "text", "address_line" "text", "rt_rw" "text", "province_name" "text", "city_name" "text", "district_name" "text", "subdistrict_name" "text", "postal_code" "text")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
begin
  if not is_admin_at_least('STAFF') then
    raise exception 'PERMISSION_DENIED';
  end if;
  return query
  SELECT DISTINCT c.id, c.name, c.slug, c.is_active, c.owner_user_id,
    c.created_at, c.updated_at, c.expired_date, c.is_agreement_signed,
    c.permit_number, c.owner_ktp_number, c.phone_number, c.address_line,
    c.rt_rw, c.province_name, c.city_name, c.district_name, c.subdistrict_name,
    c.postal_code
  FROM public.clinics c
  INNER JOIN public.clinic_extension_requests cer
    ON cer.clinic_id = c.id AND cer.status = 'PENDING'
  ORDER BY c.created_at DESC;
end;
$$;


ALTER FUNCTION "public"."get_clinics_with_pending_extension"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_invitation_by_token"("invite_token" "text") RETURNS TABLE("email" "text", "phone" "text", "contact_type" "text", "expires_at" timestamp with time zone, "is_used" boolean, "clinic_id" "uuid", "clinic_name" "text", "flow" "public"."patient_invitation_flow", "used_reason" "public"."patient_invitation_used_reason", "session_start_at" timestamp with time zone, "session_end_at" timestamp with time zone, "session_timezone" "text", "target_patient_id" "uuid")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select
    pi.email, pi.phone, pi.contact_type,
    pi.expires_at, pi.is_used,
    pi.clinic_id, c.name as clinic_name,
    pi.flow, pi.used_reason,
    pi.session_start_at, pi.session_end_at, pi.session_timezone,
    pi.target_patient_id
  from public.patient_invitations pi
  left join public.clinics c on c.id = pi.clinic_id
  where pi.token = invite_token
  limit 1;
$$;


ALTER FUNCTION "public"."get_invitation_by_token"("invite_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_reference_data"("table_name" "text") RETURNS TABLE("id" "uuid", "name" "text", "order_index" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN
  CASE table_name
    WHEN 'religion' THEN
      RETURN QUERY SELECT r.id, r.name, r.order_index FROM public.religion r ORDER BY r.order_index ASC, r.name ASC;
    WHEN 'education' THEN
      RETURN QUERY SELECT e.id, e.name, e.order_index FROM public.education e ORDER BY e.order_index ASC, e.name ASC;
    WHEN 'occupation' THEN
      RETURN QUERY SELECT o.id, o.name, o.order_index FROM public.occupation o ORDER BY o.order_index ASC, o.name ASC;
    WHEN 'marital_status' THEN
      RETURN QUERY SELECT ms.id, ms.name, ms.order_index FROM public.marital_status ms ORDER BY ms.order_index ASC, ms.name ASC;
    ELSE
      RAISE EXCEPTION 'Unsupported reference table: %', table_name USING ERRCODE = '22023';
  END CASE;
END;
$$;


ALTER FUNCTION "public"."get_reference_data"("table_name" "text") OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "public"."is_admin_at_least"("p_min_role" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'pg_catalog', 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_profiles ap
    WHERE ap.id = auth.uid()
      AND ap.is_active = true
      AND (
        upper(coalesce(p_min_role, '')) = 'STAFF'
        OR (upper(coalesce(p_min_role, '')) = 'ADMIN' AND ap.admin_level IN ('ADMIN', 'SUPER_ADMIN'))
        OR (upper(coalesce(p_min_role, '')) = 'SUPER_ADMIN' AND ap.admin_level = 'SUPER_ADMIN')
      )
  );
$$;


ALTER FUNCTION "public"."is_admin_at_least"("p_min_role" "text") OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "public"."is_registered_profile_email"("p_email" "text") RETURNS boolean
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'public'
    AS $$ select exists (select 1 from public.users u left join public.clinic_memberships cm on cm.user_id = u.id where lower(trim(coalesce(cm.email, ''))) = lower(trim(p_email)) and u.role = 'clinic_staff' limit 1); $$;


ALTER FUNCTION "public"."is_registered_profile_email"("p_email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reject_clinic_extension_request"("p_request_id" "uuid") RETURNS TABLE("request_id" "uuid", "clinic_id" "uuid", "rejected_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$ DECLARE v_request public.clinic_extension_requests%ROWTYPE; v_rejected_at timestamptz := timezone('utc', now()); BEGIN IF NOT public.is_admin_at_least('ADMIN') THEN RAISE EXCEPTION 'Hanya admin yang dapat menolak pengajuan perpanjangan.'; END IF; SELECT * INTO v_request FROM public.clinic_extension_requests cer WHERE cer.id = p_request_id FOR UPDATE; IF v_request.id IS NULL THEN RAISE EXCEPTION 'Pengajuan perpanjangan tidak ditemukan.'; END IF; IF v_request.status <> 'PENDING' THEN RAISE EXCEPTION 'Hanya pengajuan berstatus PENDING yang dapat ditolak.'; END IF; UPDATE public.clinic_extension_requests SET status = 'REJECTED', approved_at = NULL, approved_by = NULL, added_days = NULL WHERE id = v_request.id; RETURN QUERY SELECT v_request.id, v_request.clinic_id, v_rejected_at; END; $$;


ALTER FUNCTION "public"."reject_clinic_extension_request"("p_request_id" "uuid") OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "public"."rpc_admin_b2b_template_delete"("p_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; DELETE FROM public.b2b_agreement_templates WHERE id = p_id; END; $$;


ALTER FUNCTION "public"."rpc_admin_b2b_template_delete"("p_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_b2b_template_upsert"("p_id" "uuid", "p_title" "text", "p_content" "text", "p_is_active" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN
  IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF;
  IF p_is_active THEN UPDATE public.b2b_agreement_templates SET is_active = false WHERE is_active = true AND (p_id IS NULL OR id <> p_id); END IF;
  IF p_id IS NULL THEN INSERT INTO public.b2b_agreement_templates(title, content, is_active) VALUES (p_title, p_content, p_is_active);
  ELSE UPDATE public.b2b_agreement_templates SET title = p_title, content = p_content, is_active = p_is_active, updated_at = now() WHERE id = p_id; END IF;
END; $$;


ALTER FUNCTION "public"."rpc_admin_b2b_template_upsert"("p_id" "uuid", "p_title" "text", "p_content" "text", "p_is_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_clinic_followups"("p_clinic_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; RETURN jsonb_build_object('invitations', COALESCE((SELECT jsonb_agg(to_jsonb(i) ORDER BY i.created_at DESC) FROM (SELECT * FROM public.b2b_invitations WHERE clinic_id = p_clinic_id ORDER BY created_at DESC LIMIT 5) i), '[]'::jsonb), 'pendingExtensionRequest', (SELECT to_jsonb(e) FROM (SELECT id, status, requested_at, approved_at, added_days FROM public.clinic_extension_requests WHERE clinic_id = p_clinic_id AND status = 'PENDING' ORDER BY requested_at DESC LIMIT 1) e)); END; $$;


ALTER FUNCTION "public"."rpc_admin_clinic_followups"("p_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_consent_template_delete"("p_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; DELETE FROM public.consent_templates WHERE id = p_id; END; $$;


ALTER FUNCTION "public"."rpc_admin_consent_template_delete"("p_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_consent_template_upsert"("p_id" "uuid", "p_title" "text", "p_body" "text", "p_is_active" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; IF p_is_active THEN UPDATE public.consent_templates SET is_active = false WHERE is_active = true AND (p_id IS NULL OR id <> p_id); END IF; IF p_id IS NULL THEN INSERT INTO public.consent_templates(title, body, is_active) VALUES (p_title, p_body, p_is_active); ELSE UPDATE public.consent_templates SET title = p_title, body = p_body, is_active = p_is_active, updated_at = now() WHERE id = p_id; END IF; END; $$;


ALTER FUNCTION "public"."rpc_admin_consent_template_upsert"("p_id" "uuid", "p_title" "text", "p_body" "text", "p_is_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_dashboard"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
DECLARE
  now_ts timestamptz := now();
  soon_ts timestamptz := now() + interval '30 days';
BEGIN
  IF NOT public.is_admin_at_least('STAFF') THEN
    RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501';
  END IF;
  RETURN jsonb_build_object(
    'pendingDemoRequests', (SELECT count(*) FROM public.demo_requests WHERE status = 'pending'),
    'activeClinicsCount', (SELECT count(*) FROM public.clinics WHERE is_active = true),
    'expiringClinicsCount', (SELECT count(*) FROM public.clinics WHERE expired_date < soon_ts AND expired_date > now_ts),
    'pendingExtensionRequests', COALESCE((
      SELECT jsonb_agg(jsonb_build_object('id', cer.id, 'clinic_id', cer.clinic_id, 'requested_at', cer.requested_at, 'clinics', jsonb_build_object('name', c.name)) ORDER BY cer.requested_at DESC)
      FROM public.clinic_extension_requests cer
      LEFT JOIN public.clinics c ON c.id = cer.clinic_id
      WHERE cer.status = 'PENDING'
    ), '[]'::jsonb)
  );
END;
$$;


ALTER FUNCTION "public"."rpc_admin_dashboard"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_get_clinic_edit"("p_clinic_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; RETURN (SELECT to_jsonb(c) FROM public.clinics c WHERE c.id = p_clinic_id); END; $$;


ALTER FUNCTION "public"."rpc_admin_get_clinic_edit"("p_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_list_consent_templates"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; RETURN COALESCE((SELECT jsonb_agg(to_jsonb(ct) ORDER BY ct.created_at DESC) FROM public.consent_templates ct), '[]'::jsonb); END; $$;


ALTER FUNCTION "public"."rpc_admin_list_consent_templates"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_list_demo_requests"("p_status" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; RETURN COALESCE((SELECT jsonb_agg(to_jsonb(d) ORDER BY d.created_at DESC) FROM public.demo_requests d WHERE d.email_delivery_status = p_status), '[]'::jsonb); END; $$;


ALTER FUNCTION "public"."rpc_admin_list_demo_requests"("p_status" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_list_profiles"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN
  IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF;
  RETURN COALESCE((SELECT jsonb_agg(to_jsonb(ap) - 'created_by' - 'updated_by' ORDER BY ap.created_at DESC) FROM public.admin_profiles ap), '[]'::jsonb);
END;
$$;


ALTER FUNCTION "public"."rpc_admin_list_profiles"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_mark_demo_registered"("p_demo_request_id" "uuid", "p_clinic_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; UPDATE public.demo_requests SET registration_status = 'registered', registered_clinic_id = p_clinic_id, registered_at = now() WHERE id = p_demo_request_id; END; $$;


ALTER FUNCTION "public"."rpc_admin_mark_demo_registered"("p_demo_request_id" "uuid", "p_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_set_profile_active"("p_id" "uuid", "p_is_active" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN
  IF NOT public.is_admin_at_least('SUPER_ADMIN') THEN RAISE EXCEPTION 'Super admin access required' USING ERRCODE = '42501'; END IF;
  UPDATE public.admin_profiles SET is_active = p_is_active, updated_at = now(), updated_by = auth.uid() WHERE id = p_id;
END;
$$;


ALTER FUNCTION "public"."rpc_admin_set_profile_active"("p_id" "uuid", "p_is_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_admin_upsert_profile"("p_id" "uuid", "p_full_name" "text", "p_email" "text", "p_phone" "text", "p_admin_level" "public"."admin_level_enum", "p_is_active" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN
  IF NOT public.is_admin_at_least('SUPER_ADMIN') THEN RAISE EXCEPTION 'Super admin access required' USING ERRCODE = '42501'; END IF;
  INSERT INTO public.admin_profiles(id, full_name, email, phone, admin_level, is_active, created_by, updated_by)
  VALUES (p_id, p_full_name, p_email, p_phone, p_admin_level, p_is_active, auth.uid(), auth.uid())
  ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, email = EXCLUDED.email, phone = EXCLUDED.phone, admin_level = EXCLUDED.admin_level, is_active = EXCLUDED.is_active, updated_at = now(), updated_by = auth.uid();
END;
$$;


ALTER FUNCTION "public"."rpc_admin_upsert_profile"("p_id" "uuid", "p_full_name" "text", "p_email" "text", "p_phone" "text", "p_admin_level" "public"."admin_level_enum", "p_is_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_create_patient_consent"("p_visit_id" "uuid", "p_patient_id" "uuid", "p_consent_type" "text", "p_signed_by_name" "text", "p_notes" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
DECLARE new_id uuid;
BEGIN IF NOT public.has_patient_access(p_patient_id) THEN RAISE EXCEPTION 'Patient access required' USING ERRCODE = '42501'; END IF; INSERT INTO public.patient_consents(visit_id, patient_id, consent_type, signed_by_name, notes) VALUES (p_visit_id, p_patient_id, p_consent_type, p_signed_by_name, p_notes) RETURNING id INTO new_id; RETURN new_id; END; $$;


ALTER FUNCTION "public"."rpc_create_patient_consent"("p_visit_id" "uuid", "p_patient_id" "uuid", "p_consent_type" "text", "p_signed_by_name" "text", "p_notes" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_get_active_consent_template"() RETURNS "jsonb"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$ SELECT to_jsonb(t) FROM (SELECT id, title, body FROM public.consent_templates WHERE is_active = true LIMIT 1) t; $$;


ALTER FUNCTION "public"."rpc_get_active_consent_template"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_get_admin_profile"() RETURNS TABLE("id" "uuid", "full_name" "text", "email" "text", "phone" "text", "admin_level" "public"."admin_level_enum", "is_active" boolean)
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
  SELECT ap.id, ap.full_name, ap.email, ap.phone, ap.admin_level, ap.is_active
  FROM public.admin_profiles ap
  WHERE ap.id = auth.uid()
    AND ap.is_active = true
  LIMIT 1;
$$;


ALTER FUNCTION "public"."rpc_get_admin_profile"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_get_portal_session"() RETURNS TABLE("profile_role" "public"."user_role", "membership_id" "uuid", "clinic_id" "uuid", "is_owner" boolean, "is_staff" boolean, "is_practitioner" boolean, "profession" "public"."practitioner_profession", "is_active" boolean, "clinic" "jsonb")
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
  SELECT
    u.role AS profile_role,
    cm.id AS membership_id,
    cm.clinic_id,
    cm.is_owner,
    cm.is_staff,
    cm.is_practitioner,
    cm.profession,
    cm.is_active,
    jsonb_build_object(
      'id', c.id,
      'name', c.name,
      'slug', c.slug,
      'is_active', c.is_active,
      'expired_date', c.expired_date,
      'is_agreement_signed', c.is_agreement_signed
    ) AS clinic
  FROM public.users u
  LEFT JOIN public.clinic_memberships cm
    ON cm.user_id = u.id
   AND cm.is_active = true
  LEFT JOIN public.clinics c
    ON c.id = cm.clinic_id
  WHERE u.id = auth.uid()
    AND u.role = 'clinic_staff'::public.user_role
  ORDER BY cm.is_owner DESC NULLS LAST, cm.created_at ASC NULLS LAST;
$$;


ALTER FUNCTION "public"."rpc_get_portal_session"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_mutate_reference_data"("table_name" "text", "row_id" "uuid", "row_name" "text", "row_order_index" integer, "op" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $_$
DECLARE sql text; target regclass;
BEGIN
  IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF;
  target := CASE table_name WHEN 'religion' THEN 'public.religion'::regclass WHEN 'education' THEN 'public.education'::regclass WHEN 'occupation' THEN 'public.occupation'::regclass WHEN 'marital_status' THEN 'public.marital_status'::regclass ELSE NULL END;
  IF target IS NULL THEN RAISE EXCEPTION 'Unsupported reference table: %', table_name USING ERRCODE = '22023'; END IF;
  IF op = 'delete' THEN EXECUTE format('DELETE FROM %s WHERE id = $1', target) USING row_id; RETURN; END IF;
  IF row_id IS NULL THEN EXECUTE format('INSERT INTO %s(name, order_index, created_by, updated_by) VALUES ($1, $2, $3, $3)', target) USING row_name, row_order_index, auth.uid();
  ELSE EXECUTE format('UPDATE %s SET name = $1, order_index = $2, updated_at = now(), updated_by = $3 WHERE id = $4', target) USING row_name, row_order_index, auth.uid(), row_id; END IF;
END;
$_$;


ALTER FUNCTION "public"."rpc_mutate_reference_data"("table_name" "text", "row_id" "uuid", "row_name" "text", "row_order_index" integer, "op" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_patient_consents"("p_visit_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN RETURN COALESCE((SELECT jsonb_agg(to_jsonb(pc) ORDER BY pc.signed_at DESC) FROM public.patient_consents pc WHERE pc.visit_id = p_visit_id AND public.has_patient_access(pc.patient_id)), '[]'::jsonb); END; $$;


ALTER FUNCTION "public"."rpc_patient_consents"("p_visit_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_portal_clinic_agreement"("p_clinic_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN
  IF NOT public.has_active_membership(p_clinic_id) THEN RAISE EXCEPTION 'Clinic access required' USING ERRCODE = '42501'; END IF;
  RETURN jsonb_build_object('clinic', (SELECT to_jsonb(c) FROM (SELECT id, name, expired_date, is_agreement_signed FROM public.clinics WHERE id = p_clinic_id) c), 'activeTemplate', (SELECT to_jsonb(t) FROM (SELECT id, title, content FROM public.b2b_agreement_templates WHERE is_active = true LIMIT 1) t), 'latestAgreement', (SELECT to_jsonb(a) FROM (SELECT id, template_id, signed_by_name, signed_at, signature_image_path FROM public.b2b_agreements WHERE clinic_id = p_clinic_id ORDER BY signed_at DESC LIMIT 1) a), 'latestExtensionRequest', (SELECT to_jsonb(e) FROM (SELECT id, status, requested_at, approved_at, added_days FROM public.clinic_extension_requests WHERE clinic_id = p_clinic_id ORDER BY requested_at DESC LIMIT 1) e));
END; $$;


ALTER FUNCTION "public"."rpc_portal_clinic_agreement"("p_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_portal_clinic_memberships"("p_clinic_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN IF NOT public.has_active_membership(p_clinic_id) THEN RAISE EXCEPTION 'Clinic access required' USING ERRCODE = '42501'; END IF; RETURN COALESCE((SELECT jsonb_agg(to_jsonb(cm) ORDER BY cm.is_owner DESC, cm.created_at ASC) FROM (SELECT id, user_id, full_name, email, birth_date, ktp_number, gender, address, phone, sip_number, is_owner, is_staff, is_practitioner, profession, is_active, created_at FROM public.clinic_memberships WHERE clinic_id = p_clinic_id) cm), '[]'::jsonb); END; $$;


ALTER FUNCTION "public"."rpc_portal_clinic_memberships"("p_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_portal_dashboard"("p_clinic_id" "uuid", "p_start" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_end" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_mode" "text" DEFAULT 'dashboard'::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
DECLARE rows_json jsonb;
BEGIN
  IF NOT public.has_active_membership(p_clinic_id) THEN RAISE EXCEPTION 'Clinic access required' USING ERRCODE = '42501'; END IF;
  SELECT COALESCE(jsonb_agg(jsonb_build_object('id', a.id, 'patient_id', a.patient_id, 'start_time', a.start_time, 'end_time', a.end_time, 'status', a.status, 'patient', jsonb_build_object('id', p.id, 'full_name', p.full_name, 'phone', p.phone)) ORDER BY a.start_time ASC), '[]'::jsonb)
  INTO rows_json FROM public.appointments a LEFT JOIN public.patients p ON p.id = a.patient_id
  WHERE a.clinic_id = p_clinic_id AND (p_start IS NULL OR a.start_time >= p_start) AND (p_end IS NULL OR a.start_time <= p_end) LIMIT 100;
  RETURN rows_json;
END; $$;


ALTER FUNCTION "public"."rpc_portal_dashboard"("p_clinic_id" "uuid", "p_start" timestamp with time zone, "p_end" timestamp with time zone, "p_mode" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_portal_get_clinic_profile"("p_clinic_id" "uuid") RETURNS "jsonb"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ SELECT jsonb_build_object('id', c.id, 'name', c.name, 'slug', c.slug, 'is_active', c.is_active, 'expired_date', c.expired_date, 'permit_number', c.permit_number, 'owner_ktp_number', c.owner_ktp_number, 'phone_number', c.phone_number, 'address_line', c.address_line, 'rt_rw', c.rt_rw, 'province_name', c.province_name, 'city_name', c.city_name, 'district_name', c.district_name, 'subdistrict_name', c.subdistrict_name, 'postal_code', c.postal_code, 'full_address', c.full_address, 'profile_picture_path', c.profile_picture_path, 'stamp_path', c.stamp_path, 'signature_path', c.signature_path, 'updated_at', c.updated_at, 'owner_name', (SELECT cm.full_name FROM public.clinic_memberships cm WHERE cm.clinic_id = p_clinic_id AND cm.is_owner = true AND cm.is_active = true ORDER BY cm.created_at ASC LIMIT 1), 'owner_email', (SELECT cm.email FROM public.clinic_memberships cm WHERE cm.clinic_id = p_clinic_id AND cm.is_owner = true AND cm.is_active = true ORDER BY cm.created_at ASC LIMIT 1)) FROM public.clinics c WHERE c.id = p_clinic_id AND public.has_active_membership(p_clinic_id); $$;


ALTER FUNCTION "public"."rpc_portal_get_clinic_profile"("p_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_portal_patient_workspace"("p_clinic_id" "uuid", "p_patient_id" "uuid", "p_appointment_id" "uuid" DEFAULT NULL::"uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
DECLARE cp record; pat record; visit_ids uuid[]; latest_visit uuid; can_practitioner boolean := public.has_practitioner_access(p_clinic_id);
BEGIN
  IF NOT public.has_active_membership(p_clinic_id) THEN RAISE EXCEPTION 'Clinic access required' USING ERRCODE = '42501'; END IF;
  SELECT id, patient_id, mrn INTO cp FROM public.clinic_patients WHERE clinic_id = p_clinic_id AND patient_id = p_patient_id LIMIT 1;
  IF cp.id IS NULL THEN RETURN jsonb_build_object('notFound', true); END IF;
  SELECT id, full_name, email, phone INTO pat FROM public.patients WHERE id = cp.patient_id;
  SELECT array_agg(id ORDER BY created_at DESC), (array_agg(id ORDER BY created_at DESC))[1] INTO visit_ids, latest_visit FROM (SELECT id, created_at FROM public.patient_visits WHERE clinic_id = p_clinic_id AND patient_id = pat.id ORDER BY created_at DESC LIMIT 30) v;
  RETURN jsonb_build_object(
    'notFound', false, 'canPractitioner', can_practitioner,
    'patient', jsonb_build_object('id', pat.id, 'mrn', cp.mrn, 'fullName', pat.full_name, 'email', pat.email, 'phone', pat.phone),
    'visitId', latest_visit,
    'personalData', (SELECT to_jsonb(x) FROM public.patient_personal_data x WHERE clinic_id = p_clinic_id AND patient_id = pat.id LIMIT 1),
    'familyData', (SELECT to_jsonb(x) FROM public.patient_family_data x WHERE clinic_id = p_clinic_id AND patient_id = pat.id LIMIT 1),
    'developmentalHistory', (SELECT to_jsonb(x) FROM public.developmental_history x WHERE clinic_id = p_clinic_id AND visit_id = latest_visit LIMIT 1),
    'cognitiveAssessment', (SELECT to_jsonb(x) FROM public.cognitive_assessments x WHERE clinic_id = p_clinic_id AND visit_id = latest_visit LIMIT 1),
    'recentVisits', COALESCE((SELECT jsonb_agg(jsonb_build_object('id', id, 'created_at', created_at) ORDER BY created_at DESC) FROM public.patient_visits WHERE clinic_id = p_clinic_id AND patient_id = pat.id LIMIT 30), '[]'::jsonb),
    'recentTherapySessions', CASE WHEN can_practitioner THEN COALESCE((SELECT jsonb_agg(to_jsonb(s) ORDER BY session_date DESC, session_time DESC) FROM (SELECT id, session_date, session_time, activity_type, subject, clinical_notes FROM public.therapy_sessions WHERE clinic_id = p_clinic_id AND visit_id = ANY(COALESCE(visit_ids, ARRAY[]::uuid[])) ORDER BY session_date DESC, session_time DESC LIMIT 20) s), '[]'::jsonb) ELSE '[]'::jsonb END,
    'recentReferrals', CASE WHEN can_practitioner THEN COALESCE((SELECT jsonb_agg(to_jsonb(r) ORDER BY created_at DESC) FROM (SELECT id, destination, notes, expires_at, created_at FROM public.referrals_and_feedback WHERE clinic_id = p_clinic_id AND patient_id = pat.id AND visit_id = ANY(COALESCE(visit_ids, ARRAY[]::uuid[])) ORDER BY created_at DESC LIMIT 20) r), '[]'::jsonb) ELSE '[]'::jsonb END,
    'recentAppointments', COALESCE((SELECT jsonb_agg(to_jsonb(a) ORDER BY start_time DESC) FROM (SELECT id, start_time, end_time, status, notes FROM public.appointments WHERE clinic_id = p_clinic_id AND patient_id = pat.id ORDER BY start_time DESC LIMIT 30) a), '[]'::jsonb),
    'prefillAppointment', (SELECT to_jsonb(a) FROM (SELECT start_time FROM public.appointments WHERE id = p_appointment_id AND clinic_id = p_clinic_id AND patient_id = pat.id LIMIT 1) a)
  );
END; $$;


ALTER FUNCTION "public"."rpc_portal_patient_workspace"("p_clinic_id" "uuid", "p_patient_id" "uuid", "p_appointment_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_portal_patients"("p_clinic_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN
  IF NOT public.has_active_membership(p_clinic_id) THEN RAISE EXCEPTION 'Clinic access required' USING ERRCODE = '42501'; END IF;
  RETURN COALESCE((SELECT jsonb_agg(jsonb_build_object('id', cp.id, 'mrn', cp.mrn, 'created_at', cp.created_at, 'patient_id', cp.patient_id, 'patient', jsonb_build_object('id', p.id, 'full_name', p.full_name, 'email', p.email, 'phone', p.phone), 'personal_full_name', ppd.full_name) ORDER BY cp.created_at DESC) FROM public.clinic_patients cp LEFT JOIN public.patients p ON p.id = cp.patient_id LEFT JOIN public.patient_personal_data ppd ON ppd.clinic_id = cp.clinic_id AND ppd.patient_id = cp.patient_id WHERE cp.clinic_id = p_clinic_id LIMIT 100), '[]'::jsonb);
END; $$;


ALTER FUNCTION "public"."rpc_portal_patients"("p_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_portal_submit_clinic_agreement"("p_clinic_id" "uuid", "p_template_id" "uuid", "p_signed_by_name" "text", "p_signature_image_path" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
DECLARE agreement_id uuid; already_signed boolean;
BEGIN
  IF NOT public.has_owner_access(p_clinic_id) THEN RAISE EXCEPTION 'Owner access required' USING ERRCODE = '42501'; END IF;
  SELECT is_agreement_signed INTO already_signed FROM public.clinics WHERE id = p_clinic_id;
  INSERT INTO public.b2b_agreements(clinic_id, template_id, signed_by_name, signature_image_path) VALUES (p_clinic_id, p_template_id, p_signed_by_name, p_signature_image_path) RETURNING id INTO agreement_id;
  IF already_signed THEN INSERT INTO public.clinic_extension_requests(clinic_id, b2b_agreement_id) VALUES (p_clinic_id, agreement_id); ELSE UPDATE public.clinics SET is_agreement_signed = true WHERE id = p_clinic_id; END IF;
  RETURN agreement_id;
END; $$;


ALTER FUNCTION "public"."rpc_portal_submit_clinic_agreement"("p_clinic_id" "uuid", "p_template_id" "uuid", "p_signed_by_name" "text", "p_signature_image_path" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_portal_update_clinic_asset_paths"("p_clinic_id" "uuid", "p_profile_picture_path" "text" DEFAULT NULL::"text", "p_stamp_path" "text" DEFAULT NULL::"text", "p_signature_path" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ BEGIN IF NOT public.has_active_membership(p_clinic_id) THEN RAISE EXCEPTION 'Clinic access required' USING ERRCODE = '42501'; END IF; UPDATE public.clinics SET profile_picture_path = COALESCE(p_profile_picture_path, profile_picture_path), stamp_path = COALESCE(p_stamp_path, stamp_path), signature_path = COALESCE(p_signature_path, signature_path), updated_at = now() WHERE id = p_clinic_id; END; $$;


ALTER FUNCTION "public"."rpc_portal_update_clinic_asset_paths"("p_clinic_id" "uuid", "p_profile_picture_path" "text", "p_stamp_path" "text", "p_signature_path" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rpc_update_patient_consent_signature"("p_id" "uuid", "p_signature_path" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_catalog'
    AS $$
BEGIN UPDATE public.patient_consents pc SET signature_path = p_signature_path WHERE pc.id = p_id AND public.has_patient_access(pc.patient_id); END; $$;


ALTER FUNCTION "public"."rpc_update_patient_consent_signature"("p_id" "uuid", "p_signature_path" "text") OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "public"."set_admin_profiles_audit_fields"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_at := COALESCE(NEW.created_at, now());
    NEW.updated_at := COALESCE(NEW.updated_at, NEW.created_at, now());

    IF NEW.created_by IS NULL AND auth.uid() IS NOT NULL THEN
      NEW.created_by := auth.uid();
    END IF;

    IF NEW.updated_by IS NULL AND auth.uid() IS NOT NULL THEN
      NEW.updated_by := auth.uid();
    END IF;
  ELSE
    NEW.updated_at := now();

    IF auth.uid() IS NOT NULL THEN
      NEW.updated_by := auth.uid();
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_admin_profiles_audit_fields"() OWNER TO "postgres";


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

  select cm.user_id
  into psychologist_id
  from public.clinic_memberships cm
  where cm.clinic_id = invitation_row.clinic_id
    and cm.is_practitioner = true
  order by cm.created_at asc
  limit 1;

  if psychologist_id is null then
    return jsonb_build_object(
      'status', 'error',
      'code', 'NO_PSYCHOLOGIST',
      'message', 'Tidak ada psikolog aktif di klinik ini untuk membuat jadwal awal.'
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
  auth_user_phone text;
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
  signature_id_value uuid;
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

  signature_id_value := nullif(registration_payload ->> 'signatureId', '')::uuid;
  if signature_id_value is null then
    return jsonb_build_object('status', 'error', 'code', 'SIGNATURE_REQUIRED', 'message', 'Tanda tangan digital wajib diisi.');
  end if;

  if invitation_row.contact_type = 'phone' then
    select au.phone
    into auth_user_phone
    from auth.users au
    where au.id = target_user_id
    limit 1;

    if auth_user_phone is null or btrim(auth_user_phone) = '' then
      return jsonb_build_object('status', 'error', 'code', 'AUTH_USER_NOT_FOUND', 'message', 'Nomor HP akun pasien tidak ditemukan.');
    end if;

    if regexp_replace(auth_user_phone, '\D', '', 'g') <> regexp_replace(coalesce(invitation_row.phone, ''), '\D', '', 'g') then
      return jsonb_build_object('status', 'error', 'code', 'PHONE_MISMATCH', 'message', 'Nomor HP akun tidak cocok dengan nomor HP undangan.');
    end if;
  else
    select au.email
    into auth_user_email
    from auth.users au
    where au.id = target_user_id
    limit 1;

    if auth_user_email is null or lower(btrim(auth_user_email)) <> lower(btrim(coalesce(invitation_row.email, ''))) then
      return jsonb_build_object('status', 'error', 'code', 'EMAIL_MISMATCH', 'message', 'Email akun tidak cocok dengan email undangan.');
    end if;
  end if;

  select p.id
  into patient_id_value
  from public.patients p
  where p.user_id = target_user_id
  limit 1;

  if patient_id_value is null then
    return jsonb_build_object('status', 'error', 'code', 'PATIENT_NOT_FOUND', 'message', 'Data pasien belum dibuat untuk akun ini.');
  end if;

  if not exists (
    select 1 from public.patient_signatures ps
    where ps.id = signature_id_value
      and ps.patient_id = patient_id_value
  ) then
    return jsonb_build_object('status', 'error', 'code', 'SIGNATURE_INVALID', 'message', 'Tanda tangan digital tidak valid untuk pasien ini.');
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
      signature_id,
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
      signature_id_value,
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

  update public.patients p
  set full_name = registration_payload ->> 'fullName',
      email = case when invitation_row.contact_type = 'email' then invitation_row.email else p.email end,
      phone = coalesce(nullif(registration_payload ->> 'phone', ''), nullif(invitation_row.phone, ''), p.phone),
      updated_at = now()
  where p.id = patient_id_value;

  insert into public.patient_personal_data (
    clinic_id, patient_id, full_name, sex, birth_date, address, religion, education, occupation, hobby, referral_source,
    religion_id, other_religion, education_id, other_education, occupation_id, other_occupation,
    province_domain_id, city_domain_id, district_domain_id, subdistrict_domain_id, postal_code_domain_id, address_line, rt_rw
  ) values (
    invitation_row.clinic_id, patient_id_value, registration_payload ->> 'fullName', nullif(registration_payload ->> 'sex', ''), nullif(registration_payload ->> 'birthDate', '')::date,
    coalesce(nullif(registration_payload ->> 'address', ''), nullif(registration_payload ->> 'addressLine', '')),
    coalesce((select r.name from public.religion r where r.id = nullif(registration_payload ->> 'religionId', '')::uuid), nullif(registration_payload ->> 'otherReligion', ''), nullif(registration_payload ->> 'religion', '')),
    coalesce((select e.name from public.education e where e.id = nullif(registration_payload ->> 'educationId', '')::uuid), nullif(registration_payload ->> 'otherEducation', ''), nullif(registration_payload ->> 'education', '')),
    coalesce((select o.name from public.occupation o where o.id = nullif(registration_payload ->> 'occupationId', '')::uuid), nullif(registration_payload ->> 'otherOccupation', ''), nullif(registration_payload ->> 'occupation', '')),
    nullif(registration_payload ->> 'hobby', ''), 'Self registration invitation',
    nullif(registration_payload ->> 'religionId', '')::uuid, nullif(registration_payload ->> 'otherReligion', ''),
    nullif(registration_payload ->> 'educationId', '')::uuid, nullif(registration_payload ->> 'otherEducation', ''),
    nullif(registration_payload ->> 'occupationId', '')::uuid, nullif(registration_payload ->> 'otherOccupation', ''),
    nullif(registration_payload ->> 'provinceDomainId', '')::bigint, nullif(registration_payload ->> 'cityDomainId', '')::bigint,
    nullif(registration_payload ->> 'districtDomainId', '')::bigint, nullif(registration_payload ->> 'subdistrictDomainId', '')::bigint,
    nullif(registration_payload ->> 'postalCodeDomainId', '')::bigint, nullif(registration_payload ->> 'addressLine', ''), nullif(registration_payload ->> 'rtRw', '')
  )
  on conflict (clinic_id, patient_id) do update
  set full_name = excluded.full_name, sex = excluded.sex, birth_date = excluded.birth_date, address = excluded.address,
      religion = excluded.religion, education = excluded.education, occupation = excluded.occupation, hobby = excluded.hobby,
      referral_source = excluded.referral_source, religion_id = excluded.religion_id, other_religion = excluded.other_religion,
      education_id = excluded.education_id, other_education = excluded.other_education, occupation_id = excluded.occupation_id,
      other_occupation = excluded.other_occupation, province_domain_id = excluded.province_domain_id, city_domain_id = excluded.city_domain_id,
      district_domain_id = excluded.district_domain_id, subdistrict_domain_id = excluded.subdistrict_domain_id,
      postal_code_domain_id = excluded.postal_code_domain_id, address_line = excluded.address_line, rt_rw = excluded.rt_rw,
      updated_at = now();

  insert into public.patient_family_data (
    clinic_id, patient_id, guardian_name, guardian_relation, guardian_phone, guardian_address, father_name, father_age, father_education,
    father_occupation, mother_name, mother_age, mother_education, mother_occupation, marital_status, number_of_children, monthly_income,
    family_notes, guardian_province_domain_id, guardian_city_domain_id, guardian_district_domain_id, guardian_subdistrict_domain_id,
    guardian_postal_code_domain_id, guardian_address_line, guardian_rt_rw, father_education_id, other_father_education,
    father_occupation_id, other_father_occupation, mother_education_id, other_mother_education, mother_occupation_id,
    other_mother_occupation, marital_status_id, other_marital_status
  ) values (
    invitation_row.clinic_id, patient_id_value, nullif(registration_payload ->> 'guardianName', ''), nullif(registration_payload ->> 'guardianRelation', ''),
    nullif(registration_payload ->> 'guardianPhone', ''), coalesce(nullif(registration_payload ->> 'guardianAddress', ''), nullif(registration_payload ->> 'guardianAddressLine', '')),
    nullif(registration_payload ->> 'fatherName', ''), nullif(registration_payload ->> 'fatherAge', '')::bigint,
    coalesce((select e.name from public.education e where e.id = nullif(registration_payload ->> 'fatherEducationId', '')::uuid), nullif(registration_payload ->> 'otherFatherEducation', ''), nullif(registration_payload ->> 'fatherEducation', '')),
    coalesce((select o.name from public.occupation o where o.id = nullif(registration_payload ->> 'fatherOccupationId', '')::uuid), nullif(registration_payload ->> 'otherFatherOccupation', ''), nullif(registration_payload ->> 'fatherOccupation', '')),
    nullif(registration_payload ->> 'motherName', ''), nullif(registration_payload ->> 'motherAge', '')::bigint,
    coalesce((select e.name from public.education e where e.id = nullif(registration_payload ->> 'motherEducationId', '')::uuid), nullif(registration_payload ->> 'otherMotherEducation', ''), nullif(registration_payload ->> 'motherEducation', '')),
    coalesce((select o.name from public.occupation o where o.id = nullif(registration_payload ->> 'motherOccupationId', '')::uuid), nullif(registration_payload ->> 'otherMotherOccupation', ''), nullif(registration_payload ->> 'motherOccupation', '')),
    coalesce((select ms.name from public.marital_status ms where ms.id = nullif(registration_payload ->> 'maritalStatusId', '')::uuid), nullif(registration_payload ->> 'otherMaritalStatus', ''), nullif(registration_payload ->> 'maritalStatus', '')),
    nullif(registration_payload ->> 'numberOfChildren', '')::bigint, nullif(registration_payload ->> 'monthlyIncome', '')::numeric(12,2), nullif(registration_payload ->> 'familyNotes', ''),
    nullif(registration_payload ->> 'guardianProvinceDomainId', '')::bigint, nullif(registration_payload ->> 'guardianCityDomainId', '')::bigint,
    nullif(registration_payload ->> 'guardianDistrictDomainId', '')::bigint, nullif(registration_payload ->> 'guardianSubdistrictDomainId', '')::bigint,
    nullif(registration_payload ->> 'guardianPostalCodeDomainId', '')::bigint, nullif(registration_payload ->> 'guardianAddressLine', ''), nullif(registration_payload ->> 'guardianRtRw', ''),
    nullif(registration_payload ->> 'fatherEducationId', '')::uuid, nullif(registration_payload ->> 'otherFatherEducation', ''),
    nullif(registration_payload ->> 'fatherOccupationId', '')::uuid, nullif(registration_payload ->> 'otherFatherOccupation', ''),
    nullif(registration_payload ->> 'motherEducationId', '')::uuid, nullif(registration_payload ->> 'otherMotherEducation', ''),
    nullif(registration_payload ->> 'motherOccupationId', '')::uuid, nullif(registration_payload ->> 'otherMotherOccupation', ''),
    nullif(registration_payload ->> 'maritalStatusId', '')::uuid, nullif(registration_payload ->> 'otherMaritalStatus', '')
  )
  on conflict (clinic_id, patient_id) do update
  set guardian_name = excluded.guardian_name, guardian_relation = excluded.guardian_relation, guardian_phone = excluded.guardian_phone,
      guardian_address = excluded.guardian_address, father_name = excluded.father_name, father_age = excluded.father_age,
      father_education = excluded.father_education, father_occupation = excluded.father_occupation, mother_name = excluded.mother_name,
      mother_age = excluded.mother_age, mother_education = excluded.mother_education, mother_occupation = excluded.mother_occupation,
      marital_status = excluded.marital_status, number_of_children = excluded.number_of_children, monthly_income = excluded.monthly_income,
      family_notes = excluded.family_notes, guardian_province_domain_id = excluded.guardian_province_domain_id,
      guardian_city_domain_id = excluded.guardian_city_domain_id, guardian_district_domain_id = excluded.guardian_district_domain_id,
      guardian_subdistrict_domain_id = excluded.guardian_subdistrict_domain_id, guardian_postal_code_domain_id = excluded.guardian_postal_code_domain_id,
      guardian_address_line = excluded.guardian_address_line, guardian_rt_rw = excluded.guardian_rt_rw, father_education_id = excluded.father_education_id,
      other_father_education = excluded.other_father_education, father_occupation_id = excluded.father_occupation_id,
      other_father_occupation = excluded.other_father_occupation, mother_education_id = excluded.mother_education_id,
      other_mother_education = excluded.other_mother_education, mother_occupation_id = excluded.mother_occupation_id,
      other_mother_occupation = excluded.other_mother_occupation, marital_status_id = excluded.marital_status_id,
      other_marital_status = excluded.other_marital_status, updated_at = now();

  appointment_id_value := invitation_row.appointment_id;
  if appointment_id_value is null then
    appointment_start := coalesce(invitation_row.session_start_at, date_trunc('day', now()) + interval '1 day' + interval '9 hours');
    appointment_end := coalesce(invitation_row.session_end_at, appointment_start + interval '45 minutes');

    insert into public.appointments (clinic_id, clinic_patient_id, patient_id, practitioner_membership_id, start_time, end_time, status, notes)
    values (invitation_row.clinic_id, clinic_patient_id_value, patient_id_value, practitioner_membership_id_value, appointment_start, appointment_end, 'scheduled', 'Auto-created from patient registration + consent')
    returning id into appointment_id_value;
  end if;

  select pv.id into visit_id_value from public.patient_visits pv where pv.appointment_id = appointment_id_value limit 1;
  if visit_id_value is null then
    insert into public.patient_visits (clinic_id, clinic_patient_id, patient_id, appointment_id, status)
    values (invitation_row.clinic_id, clinic_patient_id_value, patient_id_value, appointment_id_value, 'scheduled')
    returning id into visit_id_value;
  end if;

  insert into public.developmental_history (
    clinic_id, visit_id, mother_pregnancy_notes, birth_process, gestational_age_weeks, birth_weight_kg, birth_length_cm,
    walking_age_months, speaking_age_months, hearing_function, speech_articulation, vision_function, child_medical_history, special_notes
  ) values (
    invitation_row.clinic_id, visit_id_value, nullif(registration_payload ->> 'motherPregnancyNotes', ''), birth_process_value,
    nullif(registration_payload ->> 'gestationalAgeWeeks', '')::bigint, nullif(registration_payload ->> 'birthWeightKg', '')::numeric(5,2),
    nullif(registration_payload ->> 'birthLengthCm', '')::numeric(5,2), nullif(registration_payload ->> 'walkingAgeMonths', '')::bigint,
    nullif(registration_payload ->> 'speakingAgeMonths', '')::bigint, nullif(registration_payload ->> 'hearingFunction', ''),
    nullif(registration_payload ->> 'speechArticulation', ''), nullif(registration_payload ->> 'visionFunction', ''),
    nullif(registration_payload ->> 'childMedicalHistory', ''), nullif(registration_payload ->> 'specialNotes', '')
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
    clinic_id, visit_id, knows_letters, knows_colors, writes, counts, reads, reading_spelling, fluent_reading,
    reversed_letters, autism_indication, adhd_indication, initial_conclusion, intervention_counseling_given,
    intervention_areas, other_medical_action, referral_action, assessment_result
  ) values (
    invitation_row.clinic_id, visit_id_value, coalesce((registration_payload ->> 'knowsLetters')::boolean, false),
    coalesce((registration_payload ->> 'knowsColors')::boolean, false), coalesce((registration_payload ->> 'writes')::boolean, false),
    coalesce((registration_payload ->> 'counts')::boolean, false), coalesce((registration_payload ->> 'reads')::boolean, false),
    coalesce((registration_payload ->> 'readingSpelling')::boolean, false), coalesce((registration_payload ->> 'fluentReading')::boolean, false),
    coalesce((registration_payload ->> 'reversedLetters')::boolean, false), autism_indication_value, adhd_indication_value,
    nullif(registration_payload ->> 'initialConclusion', ''), coalesce((registration_payload ->> 'interventionCounselingGiven')::boolean, false),
    nullif(registration_payload ->> 'interventionAreas', ''), nullif(registration_payload ->> 'otherMedicalAction', ''),
    nullif(registration_payload ->> 'referralAction', ''), nullif(registration_payload ->> 'assessmentResult', '')
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

  return jsonb_build_object('status', 'success', 'message', 'Registrasi berhasil. Jadwal sesi sudah dibuat sesuai undangan.', 'patientId', patient_id_value, 'clinicId', invitation_row.clinic_id, 'clinicPatientId', clinic_patient_id_value, 'appointmentId', appointment_id_value, 'visitId', visit_id_value);
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


CREATE TABLE IF NOT EXISTS "public"."address_city" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "city_id" integer NOT NULL,
    "city_name" character varying(100) NOT NULL,
    "prov_id" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."address_city" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."address_district" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "dis_id" integer NOT NULL,
    "dis_name" character varying(100) NOT NULL,
    "city_id" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."address_district" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."address_postal_code" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "postal_id" integer NOT NULL,
    "postal_code" character varying(5) NOT NULL,
    "subdis_id" integer NOT NULL,
    "dis_id" integer NOT NULL,
    "city_id" integer NOT NULL,
    "prov_id" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."address_postal_code" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."address_province" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "prov_id" integer NOT NULL,
    "prov_name" character varying(100) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."address_province" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."address_subdistrict" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "subdis_id" integer NOT NULL,
    "subdis_name" character varying(100) NOT NULL,
    "dis_id" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."address_subdistrict" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_profiles" (
    "id" "uuid" NOT NULL,
    "full_name" "text" NOT NULL,
    "email" "text",
    "phone" "text",
    "admin_level" "public"."admin_level_enum" DEFAULT 'ADMIN'::"public"."admin_level_enum" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid"
);


ALTER TABLE "public"."admin_profiles" OWNER TO "postgres";


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


CREATE TABLE IF NOT EXISTS "public"."b2b_agreement_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "is_active" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."b2b_agreement_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."b2b_agreements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "clinic_id" "uuid" NOT NULL,
    "template_id" "uuid" NOT NULL,
    "signed_by_name" "text" NOT NULL,
    "signed_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "signature_image_path" "text" NOT NULL,
    CONSTRAINT "b2b_agreements_signature_image_path_check" CHECK (("btrim"("signature_image_path") <> ''::"text")),
    CONSTRAINT "b2b_agreements_signed_by_name_check" CHECK (("btrim"("signed_by_name") <> ''::"text"))
);


ALTER TABLE "public"."b2b_agreements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."b2b_invitations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "clinic_id" "uuid" NOT NULL,
    "token_hash" "text" NOT NULL,
    "template_id" "uuid",
    "status" "text" DEFAULT 'pending'::"text",
    "signed_at" timestamp with time zone,
    "signature_url" "text",
    "signature_storage_path" "text",
    "signed_by_name" "text",
    "signed_by_position" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "b2b_invitations_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'signed'::"text", 'expired'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."b2b_invitations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."clinic_extension_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "clinic_id" "uuid" NOT NULL,
    "b2b_agreement_id" "uuid" NOT NULL,
    "status" "public"."clinic_extension_request_status_enum" DEFAULT 'PENDING'::"public"."clinic_extension_request_status_enum" NOT NULL,
    "requested_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "approved_at" timestamp with time zone,
    "approved_by" "uuid",
    "added_days" integer,
    CONSTRAINT "clinic_extension_requests_added_days_check" CHECK ((("added_days" IS NULL) OR ("added_days" > 0))),
    CONSTRAINT "clinic_extension_requests_approval_fields_check" CHECK (((("status" = 'PENDING'::"public"."clinic_extension_request_status_enum") AND ("approved_at" IS NULL) AND ("approved_by" IS NULL) AND ("added_days" IS NULL)) OR (("status" = 'REJECTED'::"public"."clinic_extension_request_status_enum") AND ("approved_at" IS NULL) AND ("approved_by" IS NULL) AND ("added_days" IS NULL)) OR (("status" = 'APPROVED'::"public"."clinic_extension_request_status_enum") AND ("approved_at" IS NOT NULL) AND ("approved_by" IS NOT NULL) AND ("added_days" IS NOT NULL))))
);


ALTER TABLE "public"."clinic_extension_requests" OWNER TO "postgres";


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
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expired_date" timestamp with time zone,
    "is_agreement_signed" boolean DEFAULT false,
    "permit_number" "text",
    "owner_ktp_number" "text",
    "phone_number" "text",
    "address_line" "text",
    "rt_rw" "text",
    "province_name" "text",
    "city_name" "text",
    "district_name" "text",
    "subdistrict_name" "text",
    "postal_code" "text",
    "full_address" "text",
    "profile_picture_path" "text",
    "stamp_path" "text",
    "signature_path" "text"
);


ALTER TABLE "public"."clinics" OWNER TO "postgres";


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


CREATE TABLE IF NOT EXISTS "public"."consent_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "body" "text" NOT NULL,
    "is_active" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "consent_templates_body_check" CHECK (("btrim"("body") <> ''::"text")),
    CONSTRAINT "consent_templates_title_check" CHECK (("btrim"("title") <> ''::"text"))
);


ALTER TABLE "public"."consent_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."demo_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "clinic_name" "text" NOT NULL,
    "clinic_type" "text",
    "pic_name" "text" NOT NULL,
    "pic_role" "text",
    "email" "text" NOT NULL,
    "whatsapp" "text" NOT NULL,
    "province_id" "uuid",
    "city_id" "uuid",
    "district_id" "uuid",
    "subdistrict_id" "uuid",
    "postal_code_id" "uuid",
    "province_name" "text",
    "city_name" "text",
    "district_name" "text",
    "subdistrict_name" "text",
    "postal_code" "text",
    "message" "text",
    "referral_source" "text",
    "status" "public"."demo_request_status_enum" DEFAULT 'pending'::"public"."demo_request_status_enum" NOT NULL,
    "submitted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "address_line" "text",
    "rt_rw" "text",
    "subscribe" boolean DEFAULT false NOT NULL,
    "privacy" boolean DEFAULT true NOT NULL,
    "fullname" "text",
    "position" "text",
    "client_ip" "text",
    "user_agent" "text",
    "email_delivery_status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "email_delivery_error" "text",
    "registration_status" "text" DEFAULT 'not_registered'::"text" NOT NULL,
    "registered_at" timestamp with time zone,
    "registered_clinic_id" "uuid",
    CONSTRAINT "demo_requests_email_delivery_status_check" CHECK (("email_delivery_status" = ANY (ARRAY['pending'::"text", 'sent'::"text", 'failed'::"text"]))),
    CONSTRAINT "demo_requests_registration_status_check" CHECK (("registration_status" = ANY (ARRAY['registered'::"text", 'not_registered'::"text"])))
);


ALTER TABLE "public"."demo_requests" OWNER TO "postgres";


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


CREATE TABLE IF NOT EXISTS "public"."edge_rate_limit_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "function_name" "text" NOT NULL,
    "identifier" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."edge_rate_limit_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."education" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "order_index" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid"
);


ALTER TABLE "public"."education" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."marital_status" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "order_index" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid"
);


ALTER TABLE "public"."marital_status" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."occupation" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "order_index" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid"
);


ALTER TABLE "public"."occupation" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."otp_verifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "otp_code" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "is_verified" boolean DEFAULT false,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "created_by" "uuid",
    "updated_by" "uuid"
);


ALTER TABLE "public"."otp_verifications" OWNER TO "postgres";


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
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "signature_id" "uuid"
);


ALTER TABLE "public"."patient_clinic_consents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."patient_consents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "visit_id" "uuid",
    "patient_id" "uuid" NOT NULL,
    "consent_type" "text" NOT NULL,
    "signed_by_name" "text" NOT NULL,
    "signature_path" "text",
    "notes" "text" DEFAULT ''::"text",
    "signed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "patient_consents_consent_type_check" CHECK (("consent_type" = ANY (ARRAY['informed'::"text", 'general'::"text"])))
);


ALTER TABLE "public"."patient_consents" OWNER TO "postgres";


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
    "clinic_id" "uuid" NOT NULL,
    "guardian_province_domain_id" bigint,
    "guardian_city_domain_id" bigint,
    "guardian_district_domain_id" bigint,
    "guardian_subdistrict_domain_id" bigint,
    "guardian_postal_code_domain_id" bigint,
    "guardian_address_line" "text",
    "guardian_rt_rw" character varying(10),
    "father_education_id" "uuid",
    "other_father_education" "text",
    "father_occupation_id" "uuid",
    "other_father_occupation" "text",
    "mother_education_id" "uuid",
    "other_mother_education" "text",
    "mother_occupation_id" "uuid",
    "other_mother_occupation" "text",
    "marital_status_id" "uuid",
    "other_marital_status" "text"
);


ALTER TABLE "public"."patient_family_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."patient_invitations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text",
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
    "phone" "text",
    "contact_type" "text" DEFAULT 'email'::"text" NOT NULL,
    CONSTRAINT "patient_invitations_contact_presence_chk" CHECK (((("contact_type" = 'email'::"text") AND ("email" IS NOT NULL)) OR (("contact_type" = 'phone'::"text") AND ("phone" IS NOT NULL)))),
    CONSTRAINT "patient_invitations_contact_type_chk" CHECK (("contact_type" = ANY (ARRAY['email'::"text", 'phone'::"text"]))),
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
    "clinic_id" "uuid" NOT NULL,
    "religion_id" "uuid",
    "other_religion" "text",
    "education_id" "uuid",
    "other_education" "text",
    "occupation_id" "uuid",
    "other_occupation" "text",
    "province_domain_id" bigint,
    "city_domain_id" bigint,
    "district_domain_id" bigint,
    "subdistrict_domain_id" bigint,
    "postal_code_domain_id" bigint,
    "address_line" "text",
    "rt_rw" character varying(10)
);


ALTER TABLE "public"."patient_personal_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."patient_signatures" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "patient_id" "uuid" NOT NULL,
    "storage_bucket" "text" DEFAULT 'patient_signatures'::"text" NOT NULL,
    "storage_path" "text" NOT NULL,
    "signed_by_name" "text" NOT NULL,
    "signed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "locked_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "signed_ip" "text",
    "signed_user_agent" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."patient_signatures" OWNER TO "postgres";


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


CREATE TABLE IF NOT EXISTS "public"."religion" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "order_index" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid"
);


ALTER TABLE "public"."religion" OWNER TO "postgres";


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


ALTER TABLE ONLY "public"."address_city"
    ADD CONSTRAINT "address_city_city_id_key" UNIQUE ("city_id");



ALTER TABLE ONLY "public"."address_city"
    ADD CONSTRAINT "address_city_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."address_district"
    ADD CONSTRAINT "address_district_dis_id_key" UNIQUE ("dis_id");



ALTER TABLE ONLY "public"."address_district"
    ADD CONSTRAINT "address_district_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."address_postal_code"
    ADD CONSTRAINT "address_postal_code_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."address_postal_code"
    ADD CONSTRAINT "address_postal_code_postal_id_key" UNIQUE ("postal_id");



ALTER TABLE ONLY "public"."address_province"
    ADD CONSTRAINT "address_province_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."address_province"
    ADD CONSTRAINT "address_province_prov_id_key" UNIQUE ("prov_id");



ALTER TABLE ONLY "public"."address_subdistrict"
    ADD CONSTRAINT "address_subdistrict_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."address_subdistrict"
    ADD CONSTRAINT "address_subdistrict_subdis_id_key" UNIQUE ("subdis_id");



ALTER TABLE ONLY "public"."admin_profiles"
    ADD CONSTRAINT "admin_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."b2b_agreement_templates"
    ADD CONSTRAINT "b2b_agreement_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."b2b_agreements"
    ADD CONSTRAINT "b2b_agreements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."b2b_invitations"
    ADD CONSTRAINT "b2b_invitations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."b2b_invitations"
    ADD CONSTRAINT "b2b_invitations_token_hash_key" UNIQUE ("token_hash");



ALTER TABLE ONLY "public"."clinic_extension_requests"
    ADD CONSTRAINT "clinic_extension_requests_pkey" PRIMARY KEY ("id");



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



ALTER TABLE ONLY "public"."consent_templates"
    ADD CONSTRAINT "consent_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."developmental_history"
    ADD CONSTRAINT "developmental_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."edge_rate_limit_events"
    ADD CONSTRAINT "edge_rate_limit_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."education"
    ADD CONSTRAINT "education_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."marital_status"
    ADD CONSTRAINT "marital_status_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."occupation"
    ADD CONSTRAINT "occupation_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."otp_verifications"
    ADD CONSTRAINT "otp_verifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_clinic_consents"
    ADD CONSTRAINT "patient_clinic_consents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_consents"
    ADD CONSTRAINT "patient_consents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_family_data"
    ADD CONSTRAINT "patient_family_data_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_invitations"
    ADD CONSTRAINT "patient_invitations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_personal_data"
    ADD CONSTRAINT "patient_personal_data_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_signatures"
    ADD CONSTRAINT "patient_signatures_patient_id_key" UNIQUE ("patient_id");



ALTER TABLE ONLY "public"."patient_signatures"
    ADD CONSTRAINT "patient_signatures_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patient_visits"
    ADD CONSTRAINT "patient_visits_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."patients"
    ADD CONSTRAINT "patients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referrals_and_feedback"
    ADD CONSTRAINT "referrals_and_feedback_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."religion"
    ADD CONSTRAINT "religion_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."therapy_sessions"
    ADD CONSTRAINT "therapy_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "appointments_clinic_id_idx" ON "public"."appointments" USING "btree" ("clinic_id");



CREATE INDEX "appointments_clinic_patient_id_idx" ON "public"."appointments" USING "btree" ("clinic_patient_id");



CREATE INDEX "appointments_patient_id_idx" ON "public"."appointments" USING "btree" ("patient_id");



CREATE INDEX "appointments_practitioner_membership_id_idx" ON "public"."appointments" USING "btree" ("practitioner_membership_id");



CREATE INDEX "appointments_start_time_idx" ON "public"."appointments" USING "btree" ("start_time");



CREATE UNIQUE INDEX "clinic_extension_requests_b2b_agreement_id_key" ON "public"."clinic_extension_requests" USING "btree" ("b2b_agreement_id");



CREATE INDEX "clinic_extension_requests_clinic_id_requested_at_idx" ON "public"."clinic_extension_requests" USING "btree" ("clinic_id", "requested_at" DESC);



CREATE UNIQUE INDEX "clinic_extension_requests_pending_unique_idx" ON "public"."clinic_extension_requests" USING "btree" ("clinic_id") WHERE ("status" = 'PENDING'::"public"."clinic_extension_request_status_enum");



CREATE INDEX "clinic_memberships_clinic_idx" ON "public"."clinic_memberships" USING "btree" ("clinic_id");



CREATE INDEX "clinic_memberships_user_idx" ON "public"."clinic_memberships" USING "btree" ("user_id");



CREATE INDEX "clinic_patients_clinic_idx" ON "public"."clinic_patients" USING "btree" ("clinic_id");



CREATE INDEX "clinic_patients_patient_idx" ON "public"."clinic_patients" USING "btree" ("patient_id");



CREATE UNIQUE INDEX "clinics_slug_unique" ON "public"."clinics" USING "btree" ("slug");



CREATE INDEX "cognitive_assessments_clinic_id_idx" ON "public"."cognitive_assessments" USING "btree" ("clinic_id");



CREATE UNIQUE INDEX "cognitive_assessments_visit_id_unique" ON "public"."cognitive_assessments" USING "btree" ("visit_id");



CREATE UNIQUE INDEX "consent_templates_single_active_idx" ON "public"."consent_templates" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "developmental_history_clinic_id_idx" ON "public"."developmental_history" USING "btree" ("clinic_id");



CREATE UNIQUE INDEX "developmental_history_visit_id_unique" ON "public"."developmental_history" USING "btree" ("visit_id");



CREATE INDEX "edge_rate_limit_events_lookup_idx" ON "public"."edge_rate_limit_events" USING "btree" ("function_name", "identifier", "created_at");



CREATE UNIQUE INDEX "education_name_unique_idx" ON "public"."education" USING "btree" ("lower"("name"));



CREATE UNIQUE INDEX "idx_admin_profiles_email_lower" ON "public"."admin_profiles" USING "btree" ("lower"("email")) WHERE ("email" IS NOT NULL);



CREATE INDEX "idx_b2b_agreements_clinic_id" ON "public"."b2b_agreements" USING "btree" ("clinic_id");



CREATE INDEX "idx_b2b_agreements_template_id" ON "public"."b2b_agreements" USING "btree" ("template_id");



CREATE INDEX "idx_b2b_invitations_clinic_id" ON "public"."b2b_invitations" USING "btree" ("clinic_id");



CREATE INDEX "idx_b2b_invitations_created_by" ON "public"."b2b_invitations" USING "btree" ("created_by");



CREATE INDEX "idx_b2b_invitations_template_id" ON "public"."b2b_invitations" USING "btree" ("template_id");



CREATE INDEX "idx_clinics_owner_user_id" ON "public"."clinics" USING "btree" ("owner_user_id");



CREATE INDEX "idx_otp_verifications_email_created_at" ON "public"."otp_verifications" USING "btree" ("email", "created_at" DESC);



CREATE INDEX "idx_patient_consents_patient_id" ON "public"."patient_consents" USING "btree" ("patient_id");



CREATE INDEX "idx_patient_consents_visit_id" ON "public"."patient_consents" USING "btree" ("visit_id");



CREATE INDEX "idx_patient_family_data_father_education" ON "public"."patient_family_data" USING "btree" ("father_education_id");



CREATE INDEX "idx_patient_family_data_father_occupation" ON "public"."patient_family_data" USING "btree" ("father_occupation_id");



CREATE INDEX "idx_patient_family_data_marital_status" ON "public"."patient_family_data" USING "btree" ("marital_status_id");



CREATE INDEX "idx_patient_family_data_mother_education" ON "public"."patient_family_data" USING "btree" ("mother_education_id");



CREATE INDEX "idx_patient_family_data_mother_occupation" ON "public"."patient_family_data" USING "btree" ("mother_occupation_id");



CREATE INDEX "idx_patient_invitations_invited_by" ON "public"."patient_invitations" USING "btree" ("invited_by_membership_id");



CREATE INDEX "idx_patient_invitations_practitioner" ON "public"."patient_invitations" USING "btree" ("practitioner_membership_id");



CREATE INDEX "idx_patient_personal_data_education_id" ON "public"."patient_personal_data" USING "btree" ("education_id");



CREATE INDEX "idx_patient_personal_data_occupation_id" ON "public"."patient_personal_data" USING "btree" ("occupation_id");



CREATE INDEX "idx_patient_personal_data_religion_id" ON "public"."patient_personal_data" USING "btree" ("religion_id");



CREATE INDEX "idx_patient_signatures_patient_id" ON "public"."patient_signatures" USING "btree" ("patient_id");



CREATE UNIQUE INDEX "marital_status_name_unique_idx" ON "public"."marital_status" USING "btree" ("lower"("name"));



CREATE UNIQUE INDEX "occupation_name_unique_idx" ON "public"."occupation" USING "btree" ("lower"("name"));



CREATE UNIQUE INDEX "patient_clinic_consents_active_unique" ON "public"."patient_clinic_consents" USING "btree" ("clinic_id", "patient_id") WHERE ("revoked_at" IS NULL);



CREATE INDEX "patient_clinic_consents_clinic_idx" ON "public"."patient_clinic_consents" USING "btree" ("clinic_id");



CREATE INDEX "patient_clinic_consents_invitation_idx" ON "public"."patient_clinic_consents" USING "btree" ("invitation_id");



CREATE INDEX "patient_clinic_consents_patient_idx" ON "public"."patient_clinic_consents" USING "btree" ("patient_id");



CREATE INDEX "patient_clinic_consents_signature_idx" ON "public"."patient_clinic_consents" USING "btree" ("signature_id");



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



CREATE UNIQUE INDEX "religion_name_unique_idx" ON "public"."religion" USING "btree" ("lower"("name"));



CREATE INDEX "therapy_sessions_clinic_id_idx" ON "public"."therapy_sessions" USING "btree" ("clinic_id");



CREATE INDEX "therapy_sessions_session_date_idx" ON "public"."therapy_sessions" USING "btree" ("session_date");



CREATE INDEX "therapy_sessions_visit_id_idx" ON "public"."therapy_sessions" USING "btree" ("visit_id");



CREATE OR REPLACE TRIGGER "trg_admin_profiles_audit_fields" BEFORE INSERT OR UPDATE ON "public"."admin_profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_admin_profiles_audit_fields"();



CREATE OR REPLACE TRIGGER "trg_clinic_memberships_sync_profile" BEFORE INSERT OR UPDATE ON "public"."clinic_memberships" FOR EACH ROW EXECUTE FUNCTION "public"."sync_clinic_membership_profile_defaults"();



ALTER TABLE ONLY "public"."address_city"
    ADD CONSTRAINT "address_city_prov_id_fkey" FOREIGN KEY ("prov_id") REFERENCES "public"."address_province"("prov_id");



ALTER TABLE ONLY "public"."address_district"
    ADD CONSTRAINT "address_district_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "public"."address_city"("city_id");



ALTER TABLE ONLY "public"."address_postal_code"
    ADD CONSTRAINT "address_postal_code_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "public"."address_city"("city_id");



ALTER TABLE ONLY "public"."address_postal_code"
    ADD CONSTRAINT "address_postal_code_dis_id_fkey" FOREIGN KEY ("dis_id") REFERENCES "public"."address_district"("dis_id");



ALTER TABLE ONLY "public"."address_postal_code"
    ADD CONSTRAINT "address_postal_code_prov_id_fkey" FOREIGN KEY ("prov_id") REFERENCES "public"."address_province"("prov_id");



ALTER TABLE ONLY "public"."address_postal_code"
    ADD CONSTRAINT "address_postal_code_subdis_id_fkey" FOREIGN KEY ("subdis_id") REFERENCES "public"."address_subdistrict"("subdis_id");



ALTER TABLE ONLY "public"."address_subdistrict"
    ADD CONSTRAINT "address_subdistrict_dis_id_fkey" FOREIGN KEY ("dis_id") REFERENCES "public"."address_district"("dis_id");



ALTER TABLE ONLY "public"."admin_profiles"
    ADD CONSTRAINT "admin_profiles_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."admin_profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."admin_profiles"
    ADD CONSTRAINT "admin_profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_profiles"
    ADD CONSTRAINT "admin_profiles_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."admin_profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_clinic_patient_id_fkey" FOREIGN KEY ("clinic_patient_id") REFERENCES "public"."clinic_patients"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_practitioner_membership_id_fkey" FOREIGN KEY ("practitioner_membership_id") REFERENCES "public"."clinic_memberships"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."b2b_agreements"
    ADD CONSTRAINT "b2b_agreements_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."b2b_agreements"
    ADD CONSTRAINT "b2b_agreements_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "public"."b2b_agreement_templates"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."b2b_invitations"
    ADD CONSTRAINT "b2b_invitations_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."b2b_invitations"
    ADD CONSTRAINT "b2b_invitations_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."b2b_invitations"
    ADD CONSTRAINT "b2b_invitations_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "public"."b2b_agreement_templates"("id");



ALTER TABLE ONLY "public"."clinic_extension_requests"
    ADD CONSTRAINT "clinic_extension_requests_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "public"."admin_profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."clinic_extension_requests"
    ADD CONSTRAINT "clinic_extension_requests_b2b_agreement_id_fkey" FOREIGN KEY ("b2b_agreement_id") REFERENCES "public"."b2b_agreements"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."clinic_extension_requests"
    ADD CONSTRAINT "clinic_extension_requests_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



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



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "public"."address_city"("id");



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_district_id_fkey" FOREIGN KEY ("district_id") REFERENCES "public"."address_district"("id");



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_postal_code_id_fkey" FOREIGN KEY ("postal_code_id") REFERENCES "public"."address_postal_code"("id");



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_province_id_fkey" FOREIGN KEY ("province_id") REFERENCES "public"."address_province"("id");



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_registered_clinic_id_fkey" FOREIGN KEY ("registered_clinic_id") REFERENCES "public"."clinics"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_subdistrict_id_fkey" FOREIGN KEY ("subdistrict_id") REFERENCES "public"."address_subdistrict"("id");



ALTER TABLE ONLY "public"."developmental_history"
    ADD CONSTRAINT "developmental_history_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."developmental_history"
    ADD CONSTRAINT "developmental_history_visit_id_fkey" FOREIGN KEY ("visit_id") REFERENCES "public"."patient_visits"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."education"
    ADD CONSTRAINT "education_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."education"
    ADD CONSTRAINT "education_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."marital_status"
    ADD CONSTRAINT "marital_status_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."marital_status"
    ADD CONSTRAINT "marital_status_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."occupation"
    ADD CONSTRAINT "occupation_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."occupation"
    ADD CONSTRAINT "occupation_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."patient_clinic_consents"
    ADD CONSTRAINT "patient_clinic_consents_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_clinic_consents"
    ADD CONSTRAINT "patient_clinic_consents_invitation_id_fkey" FOREIGN KEY ("invitation_id") REFERENCES "public"."patient_invitations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."patient_clinic_consents"
    ADD CONSTRAINT "patient_clinic_consents_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_clinic_consents"
    ADD CONSTRAINT "patient_clinic_consents_signature_id_fkey" FOREIGN KEY ("signature_id") REFERENCES "public"."patient_signatures"("id");



ALTER TABLE ONLY "public"."patient_consents"
    ADD CONSTRAINT "patient_consents_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_consents"
    ADD CONSTRAINT "patient_consents_visit_id_fkey" FOREIGN KEY ("visit_id") REFERENCES "public"."patient_visits"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_family_data"
    ADD CONSTRAINT "patient_family_data_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_family_data"
    ADD CONSTRAINT "patient_family_data_father_education_id_fkey" FOREIGN KEY ("father_education_id") REFERENCES "public"."education"("id");



ALTER TABLE ONLY "public"."patient_family_data"
    ADD CONSTRAINT "patient_family_data_father_occupation_id_fkey" FOREIGN KEY ("father_occupation_id") REFERENCES "public"."occupation"("id");



ALTER TABLE ONLY "public"."patient_family_data"
    ADD CONSTRAINT "patient_family_data_marital_status_id_fkey" FOREIGN KEY ("marital_status_id") REFERENCES "public"."marital_status"("id");



ALTER TABLE ONLY "public"."patient_family_data"
    ADD CONSTRAINT "patient_family_data_mother_education_id_fkey" FOREIGN KEY ("mother_education_id") REFERENCES "public"."education"("id");



ALTER TABLE ONLY "public"."patient_family_data"
    ADD CONSTRAINT "patient_family_data_mother_occupation_id_fkey" FOREIGN KEY ("mother_occupation_id") REFERENCES "public"."occupation"("id");



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
    ADD CONSTRAINT "patient_personal_data_education_id_fkey" FOREIGN KEY ("education_id") REFERENCES "public"."education"("id");



ALTER TABLE ONLY "public"."patient_personal_data"
    ADD CONSTRAINT "patient_personal_data_occupation_id_fkey" FOREIGN KEY ("occupation_id") REFERENCES "public"."occupation"("id");



ALTER TABLE ONLY "public"."patient_personal_data"
    ADD CONSTRAINT "patient_personal_data_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."patient_personal_data"
    ADD CONSTRAINT "patient_personal_data_religion_id_fkey" FOREIGN KEY ("religion_id") REFERENCES "public"."religion"("id");



ALTER TABLE ONLY "public"."patient_signatures"
    ADD CONSTRAINT "patient_signatures_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;



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



ALTER TABLE ONLY "public"."religion"
    ADD CONSTRAINT "religion_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."religion"
    ADD CONSTRAINT "religion_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."therapy_sessions"
    ADD CONSTRAINT "therapy_sessions_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."therapy_sessions"
    ADD CONSTRAINT "therapy_sessions_visit_id_fkey" FOREIGN KEY ("visit_id") REFERENCES "public"."patient_visits"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE "public"."address_city" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."address_district" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."address_postal_code" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."address_province" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."address_subdistrict" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_all_b2b_invitations" ON "public"."b2b_invitations" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admin_profiles"
  WHERE (("admin_profiles"."id" = "auth"."uid"()) AND ("admin_profiles"."is_active" = true)))));



CREATE POLICY "admin_all_b2b_templates" ON "public"."b2b_agreement_templates" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admin_profiles"
  WHERE (("admin_profiles"."id" = "auth"."uid"()) AND ("admin_profiles"."is_active" = true)))));



ALTER TABLE "public"."admin_profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_profiles_admin_insert" ON "public"."admin_profiles" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('ADMIN'::"text"));



CREATE POLICY "admin_profiles_admin_select" ON "public"."admin_profiles" FOR SELECT TO "authenticated" USING ("public"."is_admin_at_least"('ADMIN'::"text"));



CREATE POLICY "admin_profiles_admin_update" ON "public"."admin_profiles" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('ADMIN'::"text")) WITH CHECK ("public"."is_admin_at_least"('ADMIN'::"text"));



CREATE POLICY "admin_profiles_read_own_profile" ON "public"."admin_profiles" FOR SELECT TO "authenticated" USING (("id" = "auth"."uid"()));



CREATE POLICY "admin_profiles_super_admin_delete" ON "public"."admin_profiles" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('SUPER_ADMIN'::"text"));



CREATE POLICY "admin_read_demo_request" ON "public"."demo_requests" FOR SELECT TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text"));



ALTER TABLE "public"."appointments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "appointments_clinic_ops_all" ON "public"."appointments" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."b2b_agreement_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."b2b_agreements" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "b2b_agreements_owner_insert" ON "public"."b2b_agreements" FOR INSERT TO "authenticated" WITH CHECK ("public"."has_owner_access"("clinic_id"));



CREATE POLICY "b2b_agreements_select" ON "public"."b2b_agreements" FOR SELECT TO "authenticated" USING (("public"."is_admin_at_least"('STAFF'::"text") OR "public"."has_active_membership"("clinic_id")));



ALTER TABLE "public"."b2b_invitations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."clinic_extension_requests" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "clinic_extension_requests_insert" ON "public"."clinic_extension_requests" FOR INSERT TO "authenticated" WITH CHECK (("public"."is_admin_at_least"('STAFF'::"text") OR "public"."has_owner_access"("clinic_id")));



CREATE POLICY "clinic_extension_requests_select" ON "public"."clinic_extension_requests" FOR SELECT TO "authenticated" USING (("public"."is_admin_at_least"('STAFF'::"text") OR "public"."has_active_membership"("clinic_id")));



CREATE POLICY "clinic_extension_requests_update" ON "public"."clinic_extension_requests" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")) WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text"));



ALTER TABLE "public"."clinic_memberships" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "clinic_memberships_member_select" ON "public"."clinic_memberships" FOR SELECT TO "authenticated" USING ("public"."has_active_membership"("clinic_id"));



CREATE POLICY "clinic_memberships_owner_manage" ON "public"."clinic_memberships" TO "authenticated" USING ("public"."has_owner_access"("clinic_id")) WITH CHECK ("public"."has_owner_access"("clinic_id"));



CREATE POLICY "clinic_owner_read_b2b_invitations" ON "public"."b2b_invitations" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."clinic_memberships"
  WHERE (("clinic_memberships"."clinic_id" = "b2b_invitations"."clinic_id") AND ("clinic_memberships"."user_id" = "auth"."uid"()) AND ("clinic_memberships"."is_owner" = true) AND ("clinic_memberships"."is_active" = true)))));



ALTER TABLE "public"."clinic_patients" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "clinic_patients_ops_all" ON "public"."clinic_patients" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."clinics" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "clinics_member_select" ON "public"."clinics" FOR SELECT TO "authenticated" USING ("public"."has_active_membership"("id"));



CREATE POLICY "clinics_owner_manage" ON "public"."clinics" TO "authenticated" USING ("public"."has_owner_access"("id")) WITH CHECK ("public"."has_owner_access"("id"));



ALTER TABLE "public"."cognitive_assessments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cognitive_assessments_clinic_ops_all" ON "public"."cognitive_assessments" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."consent_templates" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "consent_templates_delete" ON "public"."consent_templates" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('ADMIN'::"text"));



CREATE POLICY "consent_templates_insert" ON "public"."consent_templates" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('ADMIN'::"text"));



CREATE POLICY "consent_templates_select" ON "public"."consent_templates" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "consent_templates_update" ON "public"."consent_templates" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('ADMIN'::"text")) WITH CHECK ("public"."is_admin_at_least"('ADMIN'::"text"));



ALTER TABLE "public"."demo_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."developmental_history" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "developmental_history_clinic_ops_all" ON "public"."developmental_history" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."edge_rate_limit_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."education" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "education_admin_delete" ON "public"."education" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "education_admin_insert" ON "public"."education" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "education_admin_update" ON "public"."education" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")) WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "education_select_all" ON "public"."education" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "insert_demo_request" ON "public"."demo_requests" FOR INSERT TO "authenticated", "anon" WITH CHECK (false);



ALTER TABLE "public"."marital_status" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "marital_status_admin_delete" ON "public"."marital_status" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "marital_status_admin_insert" ON "public"."marital_status" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "marital_status_admin_update" ON "public"."marital_status" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")) WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "marital_status_select_all" ON "public"."marital_status" FOR SELECT TO "authenticated", "anon" USING (true);



ALTER TABLE "public"."occupation" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "occupation_admin_delete" ON "public"."occupation" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "occupation_admin_insert" ON "public"."occupation" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "occupation_admin_update" ON "public"."occupation" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")) WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "occupation_select_all" ON "public"."occupation" FOR SELECT TO "authenticated", "anon" USING (true);



ALTER TABLE "public"."otp_verifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."patient_clinic_consents" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_clinic_consents_clinic_ops_all" ON "public"."patient_clinic_consents" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."patient_consents" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_consents_insert" ON "public"."patient_consents" FOR INSERT TO "authenticated" WITH CHECK ("public"."has_patient_access"("patient_id"));



CREATE POLICY "patient_consents_select" ON "public"."patient_consents" FOR SELECT TO "authenticated" USING ("public"."has_patient_access"("patient_id"));



CREATE POLICY "patient_consents_update" ON "public"."patient_consents" FOR UPDATE TO "authenticated" USING ("public"."has_patient_access"("patient_id")) WITH CHECK ("public"."has_patient_access"("patient_id"));



ALTER TABLE "public"."patient_family_data" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_family_data_clinic_ops_all" ON "public"."patient_family_data" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."patient_invitations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_invitations_clinic_ops_all" ON "public"."patient_invitations" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."patient_personal_data" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_personal_data_clinic_ops_all" ON "public"."patient_personal_data" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."patient_signatures" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_signatures_clinic_ops_select" ON "public"."patient_signatures" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."clinic_patients" "cp"
  WHERE (("cp"."patient_id" = "patient_signatures"."patient_id") AND "public"."has_ops_access"("cp"."clinic_id")))));



ALTER TABLE "public"."patient_visits" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patient_visits_clinic_ops_all" ON "public"."patient_visits" TO "authenticated" USING ("public"."has_ops_access"("clinic_id")) WITH CHECK ("public"."has_ops_access"("clinic_id"));



ALTER TABLE "public"."patients" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "patients_clinic_access_all" ON "public"."patients" TO "authenticated" USING ("public"."has_patient_access"("id")) WITH CHECK ("public"."is_portal_staff"());



CREATE POLICY "public_read_active_b2b_template" ON "public"."b2b_agreement_templates" FOR SELECT TO "anon" USING (("is_active" = true));



CREATE POLICY "public_read_address_city" ON "public"."address_city" FOR SELECT USING (true);



CREATE POLICY "public_read_address_district" ON "public"."address_district" FOR SELECT USING (true);



CREATE POLICY "public_read_address_postal_code" ON "public"."address_postal_code" FOR SELECT USING (true);



CREATE POLICY "public_read_address_province" ON "public"."address_province" FOR SELECT USING (true);



CREATE POLICY "public_read_address_subdistrict" ON "public"."address_subdistrict" FOR SELECT USING (true);



CREATE POLICY "public_read_pending_b2b_invitation" ON "public"."b2b_invitations" FOR SELECT TO "anon" USING (("status" = 'pending'::"text"));



CREATE POLICY "public_update_b2b_invitation" ON "public"."b2b_invitations" FOR UPDATE TO "anon" USING (("status" = 'pending'::"text")) WITH CHECK (("status" = 'signed'::"text"));



ALTER TABLE "public"."referrals_and_feedback" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "referrals_and_feedback_clinic_practitioner_all" ON "public"."referrals_and_feedback" TO "authenticated" USING ("public"."has_practitioner_access"("clinic_id")) WITH CHECK ("public"."has_practitioner_access"("clinic_id"));



ALTER TABLE "public"."religion" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "religion_admin_delete" ON "public"."religion" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "religion_admin_insert" ON "public"."religion" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "religion_admin_update" ON "public"."religion" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")) WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text"));



CREATE POLICY "religion_select_all" ON "public"."religion" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "service_role_manage_edge_rate_limit_events" ON "public"."edge_rate_limit_events" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service_role_read_demo_request" ON "public"."demo_requests" FOR SELECT TO "service_role" USING (true);



CREATE POLICY "service_role_update_demo_request" ON "public"."demo_requests" FOR UPDATE TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."therapy_sessions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "therapy_sessions_clinic_practitioner_all" ON "public"."therapy_sessions" TO "authenticated" USING ("public"."has_practitioner_access"("clinic_id")) WITH CHECK ("public"."has_practitioner_access"("clinic_id"));



ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "users_select_own" ON "public"."users" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";































































































































































GRANT ALL ON FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "consent_ip" "text", "consent_user_agent" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "consent_ip" "text", "consent_user_agent" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "consent_ip" "text", "consent_user_agent" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "signature_id" "uuid", "consent_ip" "text", "consent_user_agent" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "signature_id" "uuid", "consent_ip" "text", "consent_user_agent" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "signature_id" "uuid", "consent_ip" "text", "consent_user_agent" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."add_clinic_member_by_email"("target_clinic_id" "uuid", "member_email" "text", "assign_staff" boolean, "assign_practitioner" boolean, "member_profession" "public"."practitioner_profession", "actor_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."add_clinic_member_by_email"("target_clinic_id" "uuid", "member_email" "text", "assign_staff" boolean, "assign_practitioner" boolean, "member_profession" "public"."practitioner_profession", "actor_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_clinic_member_by_email"("target_clinic_id" "uuid", "member_email" "text", "assign_staff" boolean, "assign_practitioner" boolean, "member_profession" "public"."practitioner_profession", "actor_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_add_clinic_member"("p_clinic_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_is_staff" boolean, "p_is_practitioner" boolean, "p_profession" "public"."practitioner_profession") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_add_clinic_member"("p_clinic_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_is_staff" boolean, "p_is_practitioner" boolean, "p_profession" "public"."practitioner_profession") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_add_clinic_member"("p_clinic_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_is_staff" boolean, "p_is_practitioner" boolean, "p_profession" "public"."practitioner_profession") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_get_clinic_detail"("p_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_get_clinic_detail"("p_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_get_clinic_detail"("p_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_list_clinics"() TO "anon";
GRANT ALL ON FUNCTION "public"."admin_list_clinics"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_list_clinics"() TO "service_role";



GRANT ALL ON FUNCTION "public"."approve_clinic_extension_request"("p_request_id" "uuid", "p_added_days" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."approve_clinic_extension_request"("p_request_id" "uuid", "p_added_days" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."approve_clinic_extension_request"("p_request_id" "uuid", "p_added_days" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid", "permit_number" "text", "owner_ktp_number" "text", "phone_number" "text", "address_line" "text", "rt_rw" "text", "province_name" "text", "city_name" "text", "district_name" "text", "subdistrict_name" "text", "postal_code" "text", "expired_date" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid", "permit_number" "text", "owner_ktp_number" "text", "phone_number" "text", "address_line" "text", "rt_rw" "text", "province_name" "text", "city_name" "text", "district_name" "text", "subdistrict_name" "text", "postal_code" "text", "expired_date" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid", "permit_number" "text", "owner_ktp_number" "text", "phone_number" "text", "address_line" "text", "rt_rw" "text", "province_name" "text", "city_name" "text", "district_name" "text", "subdistrict_name" "text", "postal_code" "text", "expired_date" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid", "permit_number" "text", "owner_ktp_number" "text", "phone_number" "text", "address_line" "text", "rt_rw" "text", "province_name" "text", "city_name" "text", "district_name" "text", "subdistrict_name" "text", "postal_code" "text", "full_address" "text", "expired_date" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid", "permit_number" "text", "owner_ktp_number" "text", "phone_number" "text", "address_line" "text", "rt_rw" "text", "province_name" "text", "city_name" "text", "district_name" "text", "subdistrict_name" "text", "postal_code" "text", "full_address" "text", "expired_date" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text", "owner_user_id" "uuid", "permit_number" "text", "owner_ktp_number" "text", "phone_number" "text", "address_line" "text", "rt_rw" "text", "province_name" "text", "city_name" "text", "district_name" "text", "subdistrict_name" "text", "postal_code" "text", "full_address" "text", "expired_date" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_patient_from_auth_user"("auth_email" "text", "auth_user_id" "uuid", "invite_token" "text", "auth_phone" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_patient_from_auth_user"("auth_email" "text", "auth_user_id" "uuid", "invite_token" "text", "auth_phone" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_patient_from_auth_user"("auth_email" "text", "auth_user_id" "uuid", "invite_token" "text", "auth_phone" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_patient_invitation_with_schedule"("target_clinic_id" "uuid", "invited_by_membership_id" "uuid", "patient_email" "text", "patient_phone" "text", "contact_type" "text", "session_date" "date", "session_time" time without time zone, "duration_minutes" integer, "session_timezone" "text", "invitation_ttl_hours" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."create_patient_invitation_with_schedule"("target_clinic_id" "uuid", "invited_by_membership_id" "uuid", "patient_email" "text", "patient_phone" "text", "contact_type" "text", "session_date" "date", "session_time" time without time zone, "duration_minutes" integer, "session_timezone" "text", "invitation_ttl_hours" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_patient_invitation_with_schedule"("target_clinic_id" "uuid", "invited_by_membership_id" "uuid", "patient_email" "text", "patient_phone" "text", "contact_type" "text", "session_date" "date", "session_time" time without time zone, "duration_minutes" integer, "session_timezone" "text", "invitation_ttl_hours" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."edge_check_rate_limit"("p_function_name" "text", "p_identifier" "text", "p_window_seconds" integer, "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."edge_check_rate_limit"("p_function_name" "text", "p_identifier" "text", "p_window_seconds" integer, "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."edge_check_rate_limit"("p_function_name" "text", "p_identifier" "text", "p_window_seconds" integer, "p_limit" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_b2b_update_reminder"("p_clinic_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_b2b_update_reminder"("p_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_b2b_update_reminder"("p_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_b2b_update_reminder"("p_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_clinics_with_pending_extension"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_clinics_with_pending_extension"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_clinics_with_pending_extension"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_invitation_by_token"("invite_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_invitation_by_token"("invite_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_invitation_by_token"("invite_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_reference_data"("table_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_reference_data"("table_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_reference_data"("table_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_reference_data"("table_name" "text") TO "service_role";



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



GRANT ALL ON FUNCTION "public"."is_admin_at_least"("p_min_role" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin_at_least"("p_min_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin_at_least"("p_min_role" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_portal_staff"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_portal_staff"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_portal_staff"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_registered_profile_email"("p_email" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."is_registered_profile_email"("p_email" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_registered_profile_email"("p_email" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."reject_clinic_extension_request"("p_request_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."reject_clinic_extension_request"("p_request_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."reject_clinic_extension_request"("p_request_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_b2b_template_delete"("p_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_b2b_template_delete"("p_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_b2b_template_delete"("p_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_b2b_template_upsert"("p_id" "uuid", "p_title" "text", "p_content" "text", "p_is_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_b2b_template_upsert"("p_id" "uuid", "p_title" "text", "p_content" "text", "p_is_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_b2b_template_upsert"("p_id" "uuid", "p_title" "text", "p_content" "text", "p_is_active" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_clinic_followups"("p_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_clinic_followups"("p_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_clinic_followups"("p_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_consent_template_delete"("p_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_consent_template_delete"("p_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_consent_template_delete"("p_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_consent_template_upsert"("p_id" "uuid", "p_title" "text", "p_body" "text", "p_is_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_consent_template_upsert"("p_id" "uuid", "p_title" "text", "p_body" "text", "p_is_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_consent_template_upsert"("p_id" "uuid", "p_title" "text", "p_body" "text", "p_is_active" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_dashboard"() TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_dashboard"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_dashboard"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_get_clinic_edit"("p_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_get_clinic_edit"("p_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_get_clinic_edit"("p_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_list_consent_templates"() TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_list_consent_templates"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_list_consent_templates"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_list_demo_requests"("p_status" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_list_demo_requests"("p_status" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_list_demo_requests"("p_status" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_list_profiles"() TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_list_profiles"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_list_profiles"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_mark_demo_registered"("p_demo_request_id" "uuid", "p_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_mark_demo_registered"("p_demo_request_id" "uuid", "p_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_mark_demo_registered"("p_demo_request_id" "uuid", "p_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_set_profile_active"("p_id" "uuid", "p_is_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_set_profile_active"("p_id" "uuid", "p_is_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_set_profile_active"("p_id" "uuid", "p_is_active" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_admin_upsert_profile"("p_id" "uuid", "p_full_name" "text", "p_email" "text", "p_phone" "text", "p_admin_level" "public"."admin_level_enum", "p_is_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_admin_upsert_profile"("p_id" "uuid", "p_full_name" "text", "p_email" "text", "p_phone" "text", "p_admin_level" "public"."admin_level_enum", "p_is_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_admin_upsert_profile"("p_id" "uuid", "p_full_name" "text", "p_email" "text", "p_phone" "text", "p_admin_level" "public"."admin_level_enum", "p_is_active" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_create_patient_consent"("p_visit_id" "uuid", "p_patient_id" "uuid", "p_consent_type" "text", "p_signed_by_name" "text", "p_notes" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_create_patient_consent"("p_visit_id" "uuid", "p_patient_id" "uuid", "p_consent_type" "text", "p_signed_by_name" "text", "p_notes" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_create_patient_consent"("p_visit_id" "uuid", "p_patient_id" "uuid", "p_consent_type" "text", "p_signed_by_name" "text", "p_notes" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_get_active_consent_template"() TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_get_active_consent_template"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_get_active_consent_template"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."rpc_get_admin_profile"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."rpc_get_admin_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_get_admin_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_get_admin_profile"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."rpc_get_portal_session"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."rpc_get_portal_session"() TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_get_portal_session"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_get_portal_session"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_mutate_reference_data"("table_name" "text", "row_id" "uuid", "row_name" "text", "row_order_index" integer, "op" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_mutate_reference_data"("table_name" "text", "row_id" "uuid", "row_name" "text", "row_order_index" integer, "op" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_mutate_reference_data"("table_name" "text", "row_id" "uuid", "row_name" "text", "row_order_index" integer, "op" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_patient_consents"("p_visit_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_patient_consents"("p_visit_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_patient_consents"("p_visit_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_portal_clinic_agreement"("p_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_portal_clinic_agreement"("p_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_portal_clinic_agreement"("p_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_portal_clinic_memberships"("p_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_portal_clinic_memberships"("p_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_portal_clinic_memberships"("p_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_portal_dashboard"("p_clinic_id" "uuid", "p_start" timestamp with time zone, "p_end" timestamp with time zone, "p_mode" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_portal_dashboard"("p_clinic_id" "uuid", "p_start" timestamp with time zone, "p_end" timestamp with time zone, "p_mode" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_portal_dashboard"("p_clinic_id" "uuid", "p_start" timestamp with time zone, "p_end" timestamp with time zone, "p_mode" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."rpc_portal_get_clinic_profile"("p_clinic_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."rpc_portal_get_clinic_profile"("p_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_portal_get_clinic_profile"("p_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_portal_get_clinic_profile"("p_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_portal_patient_workspace"("p_clinic_id" "uuid", "p_patient_id" "uuid", "p_appointment_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_portal_patient_workspace"("p_clinic_id" "uuid", "p_patient_id" "uuid", "p_appointment_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_portal_patient_workspace"("p_clinic_id" "uuid", "p_patient_id" "uuid", "p_appointment_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_portal_patients"("p_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_portal_patients"("p_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_portal_patients"("p_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_portal_submit_clinic_agreement"("p_clinic_id" "uuid", "p_template_id" "uuid", "p_signed_by_name" "text", "p_signature_image_path" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_portal_submit_clinic_agreement"("p_clinic_id" "uuid", "p_template_id" "uuid", "p_signed_by_name" "text", "p_signature_image_path" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_portal_submit_clinic_agreement"("p_clinic_id" "uuid", "p_template_id" "uuid", "p_signed_by_name" "text", "p_signature_image_path" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."rpc_portal_update_clinic_asset_paths"("p_clinic_id" "uuid", "p_profile_picture_path" "text", "p_stamp_path" "text", "p_signature_path" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."rpc_portal_update_clinic_asset_paths"("p_clinic_id" "uuid", "p_profile_picture_path" "text", "p_stamp_path" "text", "p_signature_path" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_portal_update_clinic_asset_paths"("p_clinic_id" "uuid", "p_profile_picture_path" "text", "p_stamp_path" "text", "p_signature_path" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_portal_update_clinic_asset_paths"("p_clinic_id" "uuid", "p_profile_picture_path" "text", "p_stamp_path" "text", "p_signature_path" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rpc_update_patient_consent_signature"("p_id" "uuid", "p_signature_path" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."rpc_update_patient_consent_signature"("p_id" "uuid", "p_signature_path" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."rpc_update_patient_consent_signature"("p_id" "uuid", "p_signature_path" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."save_therapy_session_entry"("target_clinic_id" "uuid", "target_patient_id" "uuid", "target_visit_id" "uuid", "input_session_date" "date", "input_session_time" time without time zone, "input_activity_type" "text", "input_subject" "text", "input_clinical_notes" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."save_therapy_session_entry"("target_clinic_id" "uuid", "target_patient_id" "uuid", "target_visit_id" "uuid", "input_session_date" "date", "input_session_time" time without time zone, "input_activity_type" "text", "input_subject" "text", "input_clinical_notes" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."save_therapy_session_entry"("target_clinic_id" "uuid", "target_patient_id" "uuid", "target_visit_id" "uuid", "input_session_date" "date", "input_session_time" time without time zone, "input_activity_type" "text", "input_subject" "text", "input_clinical_notes" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_admin_profiles_audit_fields"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_admin_profiles_audit_fields"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_admin_profiles_audit_fields"() TO "service_role";



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


















GRANT ALL ON TABLE "public"."address_city" TO "anon";
GRANT ALL ON TABLE "public"."address_city" TO "authenticated";
GRANT ALL ON TABLE "public"."address_city" TO "service_role";



GRANT ALL ON TABLE "public"."address_district" TO "anon";
GRANT ALL ON TABLE "public"."address_district" TO "authenticated";
GRANT ALL ON TABLE "public"."address_district" TO "service_role";



GRANT ALL ON TABLE "public"."address_postal_code" TO "anon";
GRANT ALL ON TABLE "public"."address_postal_code" TO "authenticated";
GRANT ALL ON TABLE "public"."address_postal_code" TO "service_role";



GRANT ALL ON TABLE "public"."address_province" TO "anon";
GRANT ALL ON TABLE "public"."address_province" TO "authenticated";
GRANT ALL ON TABLE "public"."address_province" TO "service_role";



GRANT ALL ON TABLE "public"."address_subdistrict" TO "anon";
GRANT ALL ON TABLE "public"."address_subdistrict" TO "authenticated";
GRANT ALL ON TABLE "public"."address_subdistrict" TO "service_role";



GRANT ALL ON TABLE "public"."admin_profiles" TO "anon";
GRANT ALL ON TABLE "public"."admin_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."appointments" TO "anon";
GRANT ALL ON TABLE "public"."appointments" TO "authenticated";
GRANT ALL ON TABLE "public"."appointments" TO "service_role";



GRANT ALL ON TABLE "public"."b2b_agreement_templates" TO "anon";
GRANT ALL ON TABLE "public"."b2b_agreement_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."b2b_agreement_templates" TO "service_role";



GRANT ALL ON TABLE "public"."b2b_agreements" TO "anon";
GRANT ALL ON TABLE "public"."b2b_agreements" TO "authenticated";
GRANT ALL ON TABLE "public"."b2b_agreements" TO "service_role";



GRANT ALL ON TABLE "public"."b2b_invitations" TO "anon";
GRANT ALL ON TABLE "public"."b2b_invitations" TO "authenticated";
GRANT ALL ON TABLE "public"."b2b_invitations" TO "service_role";



GRANT ALL ON TABLE "public"."clinic_extension_requests" TO "anon";
GRANT ALL ON TABLE "public"."clinic_extension_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."clinic_extension_requests" TO "service_role";



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



GRANT ALL ON TABLE "public"."consent_templates" TO "anon";
GRANT ALL ON TABLE "public"."consent_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."consent_templates" TO "service_role";



GRANT ALL ON TABLE "public"."demo_requests" TO "anon";
GRANT ALL ON TABLE "public"."demo_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."demo_requests" TO "service_role";



GRANT ALL ON TABLE "public"."developmental_history" TO "anon";
GRANT ALL ON TABLE "public"."developmental_history" TO "authenticated";
GRANT ALL ON TABLE "public"."developmental_history" TO "service_role";



GRANT ALL ON TABLE "public"."edge_rate_limit_events" TO "anon";
GRANT ALL ON TABLE "public"."edge_rate_limit_events" TO "authenticated";
GRANT ALL ON TABLE "public"."edge_rate_limit_events" TO "service_role";



GRANT ALL ON TABLE "public"."education" TO "anon";
GRANT ALL ON TABLE "public"."education" TO "authenticated";
GRANT ALL ON TABLE "public"."education" TO "service_role";



GRANT ALL ON TABLE "public"."marital_status" TO "anon";
GRANT ALL ON TABLE "public"."marital_status" TO "authenticated";
GRANT ALL ON TABLE "public"."marital_status" TO "service_role";



GRANT ALL ON TABLE "public"."occupation" TO "anon";
GRANT ALL ON TABLE "public"."occupation" TO "authenticated";
GRANT ALL ON TABLE "public"."occupation" TO "service_role";



GRANT ALL ON TABLE "public"."otp_verifications" TO "anon";
GRANT ALL ON TABLE "public"."otp_verifications" TO "authenticated";
GRANT ALL ON TABLE "public"."otp_verifications" TO "service_role";



GRANT ALL ON TABLE "public"."patient_clinic_consents" TO "anon";
GRANT ALL ON TABLE "public"."patient_clinic_consents" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_clinic_consents" TO "service_role";



GRANT ALL ON TABLE "public"."patient_consents" TO "anon";
GRANT ALL ON TABLE "public"."patient_consents" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_consents" TO "service_role";



GRANT ALL ON TABLE "public"."patient_family_data" TO "anon";
GRANT ALL ON TABLE "public"."patient_family_data" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_family_data" TO "service_role";



GRANT ALL ON TABLE "public"."patient_invitations" TO "anon";
GRANT ALL ON TABLE "public"."patient_invitations" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_invitations" TO "service_role";



GRANT ALL ON TABLE "public"."patient_personal_data" TO "anon";
GRANT ALL ON TABLE "public"."patient_personal_data" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_personal_data" TO "service_role";



GRANT ALL ON TABLE "public"."patient_signatures" TO "anon";
GRANT ALL ON TABLE "public"."patient_signatures" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_signatures" TO "service_role";



GRANT ALL ON TABLE "public"."patient_visits" TO "anon";
GRANT ALL ON TABLE "public"."patient_visits" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_visits" TO "service_role";



GRANT ALL ON TABLE "public"."patients" TO "anon";
GRANT ALL ON TABLE "public"."patients" TO "authenticated";
GRANT ALL ON TABLE "public"."patients" TO "service_role";



GRANT ALL ON TABLE "public"."referrals_and_feedback" TO "anon";
GRANT ALL ON TABLE "public"."referrals_and_feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."referrals_and_feedback" TO "service_role";



GRANT ALL ON TABLE "public"."religion" TO "anon";
GRANT ALL ON TABLE "public"."religion" TO "authenticated";
GRANT ALL ON TABLE "public"."religion" TO "service_role";



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
































--
-- Dumped schema changes for auth and storage
--

CREATE POLICY "clinic_asset_insert" ON "storage"."objects" FOR INSERT TO "authenticated" WITH CHECK ((("bucket_id" = 'clinic_profile_picture'::"text") AND "public"."has_active_membership"((("storage"."foldername"("name"))[1])::"uuid")));



CREATE POLICY "clinic_asset_select" ON "storage"."objects" FOR SELECT TO "authenticated" USING ((("bucket_id" = 'clinic_profile_picture'::"text") AND "public"."has_active_membership"((("storage"."foldername"("name"))[1])::"uuid")));



CREATE POLICY "clinic_asset_update" ON "storage"."objects" FOR UPDATE TO "authenticated" USING ((("bucket_id" = 'clinic_profile_picture'::"text") AND "public"."has_active_membership"((("storage"."foldername"("name"))[1])::"uuid")));



