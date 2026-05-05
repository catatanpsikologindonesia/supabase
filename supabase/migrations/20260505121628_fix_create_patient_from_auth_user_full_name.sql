CREATE OR REPLACE FUNCTION public.create_patient_from_auth_user(auth_email text, auth_user_id uuid, invite_token text, auth_phone text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$;
