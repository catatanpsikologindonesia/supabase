-- Additive security-hardening RPC migration.
-- Direct table grants are intentionally left unchanged until FE migration is complete.

CREATE OR REPLACE FUNCTION public.get_reference_data(table_name text)
RETURNS TABLE(id uuid, name text, order_index integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
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

ALTER FUNCTION public.get_reference_data(text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_reference_data(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_reference_data(text) TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.rpc_get_portal_session()
RETURNS TABLE(
  profile_role public.user_role,
  membership_id uuid,
  clinic_id uuid,
  is_owner boolean,
  is_staff boolean,
  is_practitioner boolean,
  profession public.practitioner_profession,
  is_active boolean,
  clinic jsonb
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
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

ALTER FUNCTION public.rpc_get_portal_session() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.rpc_get_portal_session() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rpc_get_portal_session() TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.rpc_get_admin_profile()
RETURNS TABLE(
  id uuid,
  full_name text,
  email text,
  phone text,
  admin_level public.admin_level_enum,
  is_active boolean
)
LANGUAGE sql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
  SELECT ap.id, ap.full_name, ap.email, ap.phone, ap.admin_level, ap.is_active
  FROM public.admin_profiles ap
  WHERE ap.id = auth.uid()
    AND ap.is_active = true
  LIMIT 1;
$$;

ALTER FUNCTION public.rpc_get_admin_profile() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.rpc_get_admin_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.rpc_get_admin_profile() TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.rpc_admin_dashboard()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
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

CREATE OR REPLACE FUNCTION public.rpc_admin_list_profiles()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF;
  RETURN COALESCE((SELECT jsonb_agg(to_jsonb(ap) - 'created_by' - 'updated_by' ORDER BY ap.created_at DESC) FROM public.admin_profiles ap), '[]'::jsonb);
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_admin_upsert_profile(p_id uuid, p_full_name text, p_email text, p_phone text, p_admin_level public.admin_level_enum, p_is_active boolean)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  IF NOT public.is_admin_at_least('SUPER_ADMIN') THEN RAISE EXCEPTION 'Super admin access required' USING ERRCODE = '42501'; END IF;
  INSERT INTO public.admin_profiles(id, full_name, email, phone, admin_level, is_active, created_by, updated_by)
  VALUES (p_id, p_full_name, p_email, p_phone, p_admin_level, p_is_active, auth.uid(), auth.uid())
  ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, email = EXCLUDED.email, phone = EXCLUDED.phone, admin_level = EXCLUDED.admin_level, is_active = EXCLUDED.is_active, updated_at = now(), updated_by = auth.uid();
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_admin_set_profile_active(p_id uuid, p_is_active boolean)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog'
AS $$
BEGIN
  IF NOT public.is_admin_at_least('SUPER_ADMIN') THEN RAISE EXCEPTION 'Super admin access required' USING ERRCODE = '42501'; END IF;
  UPDATE public.admin_profiles SET is_active = p_is_active, updated_at = now(), updated_by = auth.uid() WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_mutate_reference_data(table_name text, row_id uuid, row_name text, row_order_index integer, op text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE sql text; target regclass;
BEGIN
  IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF;
  target := CASE table_name WHEN 'religion' THEN 'public.religion'::regclass WHEN 'education' THEN 'public.education'::regclass WHEN 'occupation' THEN 'public.occupation'::regclass WHEN 'marital_status' THEN 'public.marital_status'::regclass ELSE NULL END;
  IF target IS NULL THEN RAISE EXCEPTION 'Unsupported reference table: %', table_name USING ERRCODE = '22023'; END IF;
  IF op = 'delete' THEN EXECUTE format('DELETE FROM %s WHERE id = $1', target) USING row_id; RETURN; END IF;
  IF row_id IS NULL THEN EXECUTE format('INSERT INTO %s(name, order_index, created_by, updated_by) VALUES ($1, $2, $3, $3)', target) USING row_name, row_order_index, auth.uid();
  ELSE EXECUTE format('UPDATE %s SET name = $1, order_index = $2, updated_at = now(), updated_by = $3 WHERE id = $4', target) USING row_name, row_order_index, auth.uid(), row_id; END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.rpc_admin_b2b_template_upsert(p_id uuid, p_title text, p_content text, p_is_active boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN
  IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF;
  IF p_is_active THEN UPDATE public.b2b_agreement_templates SET is_active = false WHERE is_active = true AND (p_id IS NULL OR id <> p_id); END IF;
  IF p_id IS NULL THEN INSERT INTO public.b2b_agreement_templates(title, content, is_active) VALUES (p_title, p_content, p_is_active);
  ELSE UPDATE public.b2b_agreement_templates SET title = p_title, content = p_content, is_active = p_is_active, updated_at = now() WHERE id = p_id; END IF;
END; $$;

CREATE OR REPLACE FUNCTION public.rpc_admin_b2b_template_delete(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; DELETE FROM public.b2b_agreement_templates WHERE id = p_id; END; $$;

CREATE OR REPLACE FUNCTION public.rpc_admin_list_consent_templates()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; RETURN COALESCE((SELECT jsonb_agg(to_jsonb(ct) ORDER BY ct.created_at DESC) FROM public.consent_templates ct), '[]'::jsonb); END; $$;

CREATE OR REPLACE FUNCTION public.rpc_admin_consent_template_upsert(p_id uuid, p_title text, p_body text, p_is_active boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; IF p_is_active THEN UPDATE public.consent_templates SET is_active = false WHERE is_active = true AND (p_id IS NULL OR id <> p_id); END IF; IF p_id IS NULL THEN INSERT INTO public.consent_templates(title, body, is_active) VALUES (p_title, p_body, p_is_active); ELSE UPDATE public.consent_templates SET title = p_title, body = p_body, is_active = p_is_active, updated_at = now() WHERE id = p_id; END IF; END; $$;

CREATE OR REPLACE FUNCTION public.rpc_admin_consent_template_delete(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; DELETE FROM public.consent_templates WHERE id = p_id; END; $$;

CREATE OR REPLACE FUNCTION public.rpc_portal_dashboard(p_clinic_id uuid, p_start timestamptz DEFAULT NULL, p_end timestamptz DEFAULT NULL, p_mode text DEFAULT 'dashboard')
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
DECLARE rows_json jsonb;
BEGIN
  IF NOT public.has_active_membership(p_clinic_id) THEN RAISE EXCEPTION 'Clinic access required' USING ERRCODE = '42501'; END IF;
  SELECT COALESCE(jsonb_agg(jsonb_build_object('id', a.id, 'patient_id', a.patient_id, 'start_time', a.start_time, 'end_time', a.end_time, 'status', a.status, 'patient', jsonb_build_object('id', p.id, 'full_name', p.full_name, 'phone', p.phone)) ORDER BY a.start_time ASC), '[]'::jsonb)
  INTO rows_json FROM public.appointments a LEFT JOIN public.patients p ON p.id = a.patient_id
  WHERE a.clinic_id = p_clinic_id AND (p_start IS NULL OR a.start_time >= p_start) AND (p_end IS NULL OR a.start_time <= p_end) LIMIT 100;
  RETURN rows_json;
END; $$;

CREATE OR REPLACE FUNCTION public.rpc_portal_patients(p_clinic_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN
  IF NOT public.has_active_membership(p_clinic_id) THEN RAISE EXCEPTION 'Clinic access required' USING ERRCODE = '42501'; END IF;
  RETURN COALESCE((SELECT jsonb_agg(jsonb_build_object('id', cp.id, 'mrn', cp.mrn, 'created_at', cp.created_at, 'patient_id', cp.patient_id, 'patient', jsonb_build_object('id', p.id, 'full_name', p.full_name, 'email', p.email, 'phone', p.phone), 'personal_full_name', ppd.full_name) ORDER BY cp.created_at DESC) FROM public.clinic_patients cp LEFT JOIN public.patients p ON p.id = cp.patient_id LEFT JOIN public.patient_personal_data ppd ON ppd.clinic_id = cp.clinic_id AND ppd.patient_id = cp.patient_id WHERE cp.clinic_id = p_clinic_id LIMIT 100), '[]'::jsonb);
END; $$;

CREATE OR REPLACE FUNCTION public.rpc_portal_clinic_agreement(p_clinic_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN
  IF NOT public.has_active_membership(p_clinic_id) THEN RAISE EXCEPTION 'Clinic access required' USING ERRCODE = '42501'; END IF;
  RETURN jsonb_build_object('clinic', (SELECT to_jsonb(c) FROM (SELECT id, name, expired_date, is_agreement_signed FROM public.clinics WHERE id = p_clinic_id) c), 'activeTemplate', (SELECT to_jsonb(t) FROM (SELECT id, title, content FROM public.b2b_agreement_templates WHERE is_active = true LIMIT 1) t), 'latestAgreement', (SELECT to_jsonb(a) FROM (SELECT id, template_id, signed_by_name, signed_at, signature_image_path FROM public.b2b_agreements WHERE clinic_id = p_clinic_id ORDER BY signed_at DESC LIMIT 1) a), 'latestExtensionRequest', (SELECT to_jsonb(e) FROM (SELECT id, status, requested_at, approved_at, added_days FROM public.clinic_extension_requests WHERE clinic_id = p_clinic_id ORDER BY requested_at DESC LIMIT 1) e));
END; $$;

CREATE OR REPLACE FUNCTION public.rpc_portal_submit_clinic_agreement(p_clinic_id uuid, p_template_id uuid, p_signed_by_name text, p_signature_image_path text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
DECLARE agreement_id uuid; already_signed boolean;
BEGIN
  IF NOT public.has_owner_access(p_clinic_id) THEN RAISE EXCEPTION 'Owner access required' USING ERRCODE = '42501'; END IF;
  SELECT is_agreement_signed INTO already_signed FROM public.clinics WHERE id = p_clinic_id;
  INSERT INTO public.b2b_agreements(clinic_id, template_id, signed_by_name, signature_image_path) VALUES (p_clinic_id, p_template_id, p_signed_by_name, p_signature_image_path) RETURNING id INTO agreement_id;
  IF already_signed THEN INSERT INTO public.clinic_extension_requests(clinic_id, b2b_agreement_id) VALUES (p_clinic_id, agreement_id); ELSE UPDATE public.clinics SET is_agreement_signed = true WHERE id = p_clinic_id; END IF;
  RETURN agreement_id;
END; $$;

CREATE OR REPLACE FUNCTION public.rpc_portal_patient_workspace(p_clinic_id uuid, p_patient_id uuid, p_appointment_id uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
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

CREATE OR REPLACE FUNCTION public.rpc_portal_clinic_memberships(p_clinic_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN IF NOT public.has_active_membership(p_clinic_id) THEN RAISE EXCEPTION 'Clinic access required' USING ERRCODE = '42501'; END IF; RETURN COALESCE((SELECT jsonb_agg(to_jsonb(cm) ORDER BY cm.is_owner DESC, cm.created_at ASC) FROM (SELECT id, user_id, full_name, email, birth_date, ktp_number, gender, address, phone, sip_number, is_owner, is_staff, is_practitioner, profession, is_active, created_at FROM public.clinic_memberships WHERE clinic_id = p_clinic_id) cm), '[]'::jsonb); END; $$;

CREATE OR REPLACE FUNCTION public.rpc_patient_consents(p_visit_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN RETURN COALESCE((SELECT jsonb_agg(to_jsonb(pc) ORDER BY pc.signed_at DESC) FROM public.patient_consents pc WHERE pc.visit_id = p_visit_id AND public.has_patient_access(pc.patient_id)), '[]'::jsonb); END; $$;

CREATE OR REPLACE FUNCTION public.rpc_create_patient_consent(p_visit_id uuid, p_patient_id uuid, p_consent_type text, p_signed_by_name text, p_notes text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
DECLARE new_id uuid;
BEGIN IF NOT public.has_patient_access(p_patient_id) THEN RAISE EXCEPTION 'Patient access required' USING ERRCODE = '42501'; END IF; INSERT INTO public.patient_consents(visit_id, patient_id, consent_type, signed_by_name, notes) VALUES (p_visit_id, p_patient_id, p_consent_type, p_signed_by_name, p_notes) RETURNING id INTO new_id; RETURN new_id; END; $$;

CREATE OR REPLACE FUNCTION public.rpc_update_patient_consent_signature(p_id uuid, p_signature_path text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN UPDATE public.patient_consents pc SET signature_path = p_signature_path WHERE pc.id = p_id AND public.has_patient_access(pc.patient_id); END; $$;

CREATE OR REPLACE FUNCTION public.rpc_get_active_consent_template()
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$ SELECT to_jsonb(t) FROM (SELECT id, title, body FROM public.consent_templates WHERE is_active = true LIMIT 1) t; $$;

CREATE OR REPLACE FUNCTION public.rpc_admin_mark_demo_registered(p_demo_request_id uuid, p_clinic_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; UPDATE public.demo_requests SET registration_status = 'registered', registered_clinic_id = p_clinic_id, registered_at = now() WHERE id = p_demo_request_id; END; $$;

CREATE OR REPLACE FUNCTION public.rpc_admin_clinic_followups(p_clinic_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; RETURN jsonb_build_object('invitations', COALESCE((SELECT jsonb_agg(to_jsonb(i) ORDER BY i.created_at DESC) FROM (SELECT * FROM public.b2b_invitations WHERE clinic_id = p_clinic_id ORDER BY created_at DESC LIMIT 5) i), '[]'::jsonb), 'pendingExtensionRequest', (SELECT to_jsonb(e) FROM (SELECT id, status, requested_at, approved_at, added_days FROM public.clinic_extension_requests WHERE clinic_id = p_clinic_id AND status = 'PENDING' ORDER BY requested_at DESC LIMIT 1) e)); END; $$;

CREATE OR REPLACE FUNCTION public.rpc_admin_list_demo_requests(p_status text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; RETURN COALESCE((SELECT jsonb_agg(to_jsonb(d) ORDER BY d.created_at DESC) FROM public.demo_requests d WHERE d.email_delivery_status = p_status), '[]'::jsonb); END; $$;

CREATE OR REPLACE FUNCTION public.rpc_admin_get_clinic_edit(p_clinic_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_catalog' AS $$
BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RAISE EXCEPTION 'Admin access required' USING ERRCODE = '42501'; END IF; RETURN (SELECT to_jsonb(c) FROM public.clinics c WHERE c.id = p_clinic_id); END; $$;

DO $$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY['rpc_admin_dashboard','rpc_admin_list_profiles','rpc_admin_upsert_profile','rpc_admin_set_profile_active','rpc_mutate_reference_data','rpc_admin_b2b_template_upsert','rpc_admin_b2b_template_delete','rpc_admin_list_consent_templates','rpc_admin_consent_template_upsert','rpc_admin_consent_template_delete','rpc_portal_dashboard','rpc_portal_patients','rpc_portal_clinic_agreement','rpc_portal_submit_clinic_agreement','rpc_portal_patient_workspace'] LOOP
    EXECUTE format('ALTER FUNCTION public.%I OWNER TO postgres', f);
  END LOOP;
END $$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated, service_role;
