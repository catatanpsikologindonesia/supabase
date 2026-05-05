CREATE OR REPLACE FUNCTION public.update_patient_registration_by_user_id(invite_token text, registration_payload jsonb, target_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    referral_source,
    religion_id,
    other_religion,
    education_id,
    other_education,
    occupation_id,
    other_occupation,
    province_domain_id,
    city_domain_id,
    district_domain_id,
    subdistrict_domain_id,
    postal_code_domain_id,
    address_line,
    rt_rw
  )
  values (
    invitation_row.clinic_id,
    patient_id_value,
    registration_payload ->> 'fullName',
    nullif(registration_payload ->> 'sex', ''),
    nullif(registration_payload ->> 'birthDate', '')::date,
    coalesce(
      nullif(registration_payload ->> 'address', ''),
      nullif(registration_payload ->> 'addressLine', '')
    ),
    coalesce(
      (select r.name from public.religion r where r.id = nullif(registration_payload ->> 'religionId', '')::uuid),
      nullif(registration_payload ->> 'otherReligion', ''),
      nullif(registration_payload ->> 'religion', '')
    ),
    coalesce(
      (select e.name from public.education e where e.id = nullif(registration_payload ->> 'educationId', '')::uuid),
      nullif(registration_payload ->> 'otherEducation', ''),
      nullif(registration_payload ->> 'education', '')
    ),
    coalesce(
      (select o.name from public.occupation o where o.id = nullif(registration_payload ->> 'occupationId', '')::uuid),
      nullif(registration_payload ->> 'otherOccupation', ''),
      nullif(registration_payload ->> 'occupation', '')
    ),
    nullif(registration_payload ->> 'hobby', ''),
    'Self registration invitation',
    nullif(registration_payload ->> 'religionId', '')::uuid,
    nullif(registration_payload ->> 'otherReligion', ''),
    nullif(registration_payload ->> 'educationId', '')::uuid,
    nullif(registration_payload ->> 'otherEducation', ''),
    nullif(registration_payload ->> 'occupationId', '')::uuid,
    nullif(registration_payload ->> 'otherOccupation', ''),
    nullif(registration_payload ->> 'provinceDomainId', '')::bigint,
    nullif(registration_payload ->> 'cityDomainId', '')::bigint,
    nullif(registration_payload ->> 'districtDomainId', '')::bigint,
    nullif(registration_payload ->> 'subdistrictDomainId', '')::bigint,
    nullif(registration_payload ->> 'postalCodeDomainId', '')::bigint,
    nullif(registration_payload ->> 'addressLine', ''),
    nullif(registration_payload ->> 'rtRw', '')
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
      religion_id = excluded.religion_id,
      other_religion = excluded.other_religion,
      education_id = excluded.education_id,
      other_education = excluded.other_education,
      occupation_id = excluded.occupation_id,
      other_occupation = excluded.other_occupation,
      province_domain_id = excluded.province_domain_id,
      city_domain_id = excluded.city_domain_id,
      district_domain_id = excluded.district_domain_id,
      subdistrict_domain_id = excluded.subdistrict_domain_id,
      postal_code_domain_id = excluded.postal_code_domain_id,
      address_line = excluded.address_line,
      rt_rw = excluded.rt_rw,
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
    family_notes,
    guardian_province_domain_id,
    guardian_city_domain_id,
    guardian_district_domain_id,
    guardian_subdistrict_domain_id,
    guardian_postal_code_domain_id,
    guardian_address_line,
    guardian_rt_rw
  )
  values (
    invitation_row.clinic_id,
    patient_id_value,
    nullif(registration_payload ->> 'guardianName', ''),
    nullif(registration_payload ->> 'guardianRelation', ''),
    nullif(registration_payload ->> 'guardianPhone', ''),
    coalesce(
      nullif(registration_payload ->> 'guardianAddress', ''),
      nullif(registration_payload ->> 'guardianAddressLine', '')
    ),
    nullif(registration_payload ->> 'fatherName', ''),
    nullif(registration_payload ->> 'fatherAge', '')::bigint,
    nullif(registration_payload ->> 'fatherEducation', ''),
    nullif(registration_payload ->> 'fatherOccupation', ''),
    nullif(registration_payload ->> 'motherName', ''),
    nullif(registration_payload ->> 'motherAge', '')::bigint,
    nullif(registration_payload ->> 'motherEducation', ''),
    nullif(registration_payload ->> 'motherOccupation', ''),
    nullif(registration_payload ->> 'maritalStatus', ''),
    nullif(registration_payload ->> 'numberOfChildren', '')::bigint,
    nullif(registration_payload ->> 'monthlyIncome', '')::numeric(12,2),
    nullif(registration_payload ->> 'familyNotes', ''),
    nullif(registration_payload ->> 'guardianProvinceDomainId', '')::bigint,
    nullif(registration_payload ->> 'guardianCityDomainId', '')::bigint,
    nullif(registration_payload ->> 'guardianDistrictDomainId', '')::bigint,
    nullif(registration_payload ->> 'guardianSubdistrictDomainId', '')::bigint,
    nullif(registration_payload ->> 'guardianPostalCodeDomainId', '')::bigint,
    nullif(registration_payload ->> 'guardianAddressLine', ''),
    nullif(registration_payload ->> 'guardianRtRw', '')
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
      guardian_province_domain_id = excluded.guardian_province_domain_id,
      guardian_city_domain_id = excluded.guardian_city_domain_id,
      guardian_district_domain_id = excluded.guardian_district_domain_id,
      guardian_subdistrict_domain_id = excluded.guardian_subdistrict_domain_id,
      guardian_postal_code_domain_id = excluded.guardian_postal_code_domain_id,
      guardian_address_line = excluded.guardian_address_line,
      guardian_rt_rw = excluded.guardian_rt_rw,
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
    nullif(registration_payload ->> 'gestationalAgeWeeks', '')::bigint,
    nullif(registration_payload ->> 'birthWeightKg', '')::numeric(5,2),
    nullif(registration_payload ->> 'birthLengthCm', '')::numeric(5,2),
    nullif(registration_payload ->> 'walkingAgeMonths', '')::bigint,
    nullif(registration_payload ->> 'speakingAgeMonths', '')::bigint,
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
$function$;
