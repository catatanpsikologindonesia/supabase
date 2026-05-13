ALTER TABLE public.demo_requests
ADD COLUMN IF NOT EXISTS registered_clinic_id uuid REFERENCES public.clinics(id) ON DELETE SET NULL;

CREATE OR REPLACE FUNCTION public.create_clinic_with_owner(
  clinic_name text,
  clinic_slug text DEFAULT NULL::text,
  owner_user_id uuid DEFAULT auth.uid(),
  permit_number text DEFAULT NULL::text,
  owner_ktp_number text DEFAULT NULL::text,
  phone_number text DEFAULT NULL::text,
  address_line text DEFAULT NULL::text,
  rt_rw text DEFAULT NULL::text,
  province_name text DEFAULT NULL::text,
  city_name text DEFAULT NULL::text,
  district_name text DEFAULT NULL::text,
  subdistrict_name text DEFAULT NULL::text,
  postal_code text DEFAULT NULL::text,
  expired_date timestamptz DEFAULT NULL::timestamptz
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
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
    update public.clinics c
    set permit_number = coalesce(nullif(btrim(create_clinic_with_owner.permit_number), ''), c.permit_number),
        owner_ktp_number = coalesce(nullif(btrim(create_clinic_with_owner.owner_ktp_number), ''), c.owner_ktp_number),
        phone_number = coalesce(nullif(btrim(create_clinic_with_owner.phone_number), ''), c.phone_number),
        address_line = coalesce(nullif(btrim(create_clinic_with_owner.address_line), ''), c.address_line),
        rt_rw = coalesce(nullif(btrim(create_clinic_with_owner.rt_rw), ''), c.rt_rw),
        province_name = coalesce(nullif(btrim(create_clinic_with_owner.province_name), ''), c.province_name),
        city_name = coalesce(nullif(btrim(create_clinic_with_owner.city_name), ''), c.city_name),
        district_name = coalesce(nullif(btrim(create_clinic_with_owner.district_name), ''), c.district_name),
        subdistrict_name = coalesce(nullif(btrim(create_clinic_with_owner.subdistrict_name), ''), c.subdistrict_name),
        postal_code = coalesce(nullif(btrim(create_clinic_with_owner.postal_code), ''), c.postal_code),
        expired_date = coalesce(create_clinic_with_owner.expired_date, c.expired_date),
        updated_at = now()
    where c.id = existing_clinic_id;

    return jsonb_build_object(
      'status', 'success',
      'message', 'Owner sudah memiliki klinik aktif.',
      'clinicId', existing_clinic_id,
      'membershipId', owner_membership_id
    );
  end if;

  insert into public.clinics (
    name,
    slug,
    owner_user_id,
    expired_date,
    permit_number,
    owner_ktp_number,
    phone_number,
    address_line,
    rt_rw,
    province_name,
    city_name,
    district_name,
    subdistrict_name,
    postal_code
  )
  values (
    normalized_name,
    final_slug,
    owner_user_id,
    create_clinic_with_owner.expired_date,
    nullif(btrim(create_clinic_with_owner.permit_number), ''),
    nullif(btrim(create_clinic_with_owner.owner_ktp_number), ''),
    nullif(btrim(create_clinic_with_owner.phone_number), ''),
    nullif(btrim(create_clinic_with_owner.address_line), ''),
    nullif(btrim(create_clinic_with_owner.rt_rw), ''),
    nullif(btrim(create_clinic_with_owner.province_name), ''),
    nullif(btrim(create_clinic_with_owner.city_name), ''),
    nullif(btrim(create_clinic_with_owner.district_name), ''),
    nullif(btrim(create_clinic_with_owner.subdistrict_name), ''),
    nullif(btrim(create_clinic_with_owner.postal_code), '')
  )
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

ALTER FUNCTION public.create_clinic_with_owner(
  text,
  text,
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  timestamptz
) OWNER TO postgres;

GRANT ALL ON FUNCTION public.create_clinic_with_owner(
  text,
  text,
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  timestamptz
) TO anon, authenticated, service_role;
