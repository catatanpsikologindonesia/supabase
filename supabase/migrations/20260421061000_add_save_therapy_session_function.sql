create or replace function public.save_therapy_session_entry(
  target_clinic_id uuid,
  target_patient_id uuid,
  target_visit_id uuid,
  input_session_date date,
  input_session_time time,
  input_activity_type text,
  input_subject text default null,
  input_clinical_notes text default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
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
