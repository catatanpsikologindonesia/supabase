CREATE TYPE public.clinic_extension_request_status_enum AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

CREATE TABLE public.b2b_agreements (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    template_id uuid NOT NULL REFERENCES public.b2b_agreement_templates(id) ON DELETE RESTRICT,
    signed_by_name text NOT NULL,
    signed_at timestamptz DEFAULT timezone('utc', now()) NOT NULL,
    signature_image_path text NOT NULL,
    CONSTRAINT b2b_agreements_signature_image_path_check CHECK (btrim(signature_image_path) <> ''),
    CONSTRAINT b2b_agreements_signed_by_name_check CHECK (btrim(signed_by_name) <> '')
);

CREATE TABLE public.clinic_extension_requests (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    clinic_id uuid NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
    b2b_agreement_id uuid NOT NULL REFERENCES public.b2b_agreements(id) ON DELETE RESTRICT,
    status public.clinic_extension_request_status_enum DEFAULT 'PENDING' NOT NULL,
    requested_at timestamptz DEFAULT timezone('utc', now()) NOT NULL,
    approved_at timestamptz,
    approved_by uuid REFERENCES public.admin_profiles(id) ON DELETE SET NULL,
    added_days integer,
    CONSTRAINT clinic_extension_requests_added_days_check CHECK ((added_days IS NULL) OR (added_days > 0)),
    CONSTRAINT clinic_extension_requests_approval_fields_check CHECK (
        ((status = 'PENDING') AND (approved_at IS NULL) AND (approved_by IS NULL) AND (added_days IS NULL)) OR
        ((status = 'REJECTED') AND (approved_at IS NULL) AND (approved_by IS NULL) AND (added_days IS NULL)) OR
        ((status = 'APPROVED') AND (approved_at IS NOT NULL) AND (approved_by IS NOT NULL) AND (added_days IS NOT NULL))
    )
);

CREATE UNIQUE INDEX clinic_extension_requests_b2b_agreement_id_key
    ON public.clinic_extension_requests(b2b_agreement_id);

CREATE INDEX clinic_extension_requests_clinic_id_requested_at_idx
    ON public.clinic_extension_requests(clinic_id, requested_at DESC);

CREATE UNIQUE INDEX clinic_extension_requests_pending_unique_idx
    ON public.clinic_extension_requests(clinic_id)
    WHERE status = 'PENDING';

ALTER TABLE public.b2b_agreements ENABLE ROW LEVEL SECURITY;

CREATE POLICY b2b_agreements_select
    ON public.b2b_agreements
    FOR SELECT
    TO authenticated
    USING (public.is_admin_at_least('STAFF') OR public.has_active_membership(clinic_id));

CREATE POLICY b2b_agreements_owner_insert
    ON public.b2b_agreements
    FOR INSERT
    TO authenticated
    WITH CHECK (public.has_owner_access(clinic_id));

ALTER TABLE public.clinic_extension_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY clinic_extension_requests_insert
    ON public.clinic_extension_requests
    FOR INSERT
    TO authenticated
    WITH CHECK (public.is_admin_at_least('STAFF') OR public.has_owner_access(clinic_id));

CREATE POLICY clinic_extension_requests_select
    ON public.clinic_extension_requests
    FOR SELECT
    TO authenticated
    USING (public.is_admin_at_least('STAFF') OR public.has_active_membership(clinic_id));

CREATE POLICY clinic_extension_requests_update
    ON public.clinic_extension_requests
    FOR UPDATE
    TO authenticated
    USING (public.is_admin_at_least('STAFF'))
    WITH CHECK (public.is_admin_at_least('STAFF'));

CREATE OR REPLACE FUNCTION public.approve_clinic_extension_request(
    p_request_id uuid,
    p_added_days integer
) RETURNS TABLE(
    request_id uuid,
    clinic_id uuid,
    approved_at timestamptz,
    new_expired_date timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_request public.clinic_extension_requests%ROWTYPE;
  v_current_expired_date timestamptz;
  v_approved_at timestamptz := timezone('utc', now());
  v_new_expired_date timestamptz;
BEGIN
  IF NOT public.is_admin_at_least('ADMIN') THEN
    RAISE EXCEPTION 'Hanya admin yang dapat menyetujui pengajuan perpanjangan.';
  END IF;

  IF coalesce(p_added_days, 0) <= 0 THEN
    RAISE EXCEPTION 'Durasi perpanjangan harus lebih dari 0 hari.';
  END IF;

  SELECT * INTO v_request
  FROM public.clinic_extension_requests cer
  WHERE cer.id = p_request_id
  FOR UPDATE;

  IF v_request.id IS NULL THEN
    RAISE EXCEPTION 'Pengajuan perpanjangan tidak ditemukan.';
  END IF;

  IF v_request.status <> 'PENDING' THEN
    RAISE EXCEPTION 'Hanya pengajuan berstatus PENDING yang dapat disetujui.';
  END IF;

  SELECT c.expired_date INTO v_current_expired_date
  FROM public.clinics c
  WHERE c.id = v_request.clinic_id
  FOR UPDATE;

  v_new_expired_date := (
    CASE
      WHEN v_current_expired_date IS NULL OR v_current_expired_date < v_approved_at THEN v_approved_at
      ELSE v_current_expired_date
    END
  ) + make_interval(days => p_added_days);

  UPDATE public.clinic_extension_requests
  SET status = 'APPROVED',
      approved_at = v_approved_at,
      approved_by = auth.uid(),
      added_days = p_added_days
  WHERE id = v_request.id;

  UPDATE public.clinics
  SET expired_date = v_new_expired_date,
      updated_at = timezone('utc', now())
  WHERE id = v_request.clinic_id;

  RETURN QUERY
  SELECT v_request.id, v_request.clinic_id, v_approved_at, v_new_expired_date;
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_clinic_extension_request(
    p_request_id uuid
) RETURNS TABLE(
    request_id uuid,
    clinic_id uuid,
    rejected_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
DECLARE
  v_request public.clinic_extension_requests%ROWTYPE;
  v_rejected_at timestamptz := timezone('utc', now());
BEGIN
  IF NOT public.is_admin_at_least('ADMIN') THEN
    RAISE EXCEPTION 'Hanya admin yang dapat menolak pengajuan perpanjangan.';
  END IF;

  SELECT * INTO v_request
  FROM public.clinic_extension_requests cer
  WHERE cer.id = p_request_id
  FOR UPDATE;

  IF v_request.id IS NULL THEN
    RAISE EXCEPTION 'Pengajuan perpanjangan tidak ditemukan.';
  END IF;

  IF v_request.status <> 'PENDING' THEN
    RAISE EXCEPTION 'Hanya pengajuan berstatus PENDING yang dapat ditolak.';
  END IF;

  UPDATE public.clinic_extension_requests
  SET status = 'REJECTED',
      approved_at = NULL,
      approved_by = NULL,
      added_days = NULL
  WHERE id = v_request.id;

  RETURN QUERY
  SELECT v_request.id, v_request.clinic_id, v_rejected_at;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_clinics_with_pending_extension()
RETURNS TABLE(
    id uuid,
    name text,
    slug varchar,
    is_active boolean,
    owner_user_id uuid,
    created_at timestamptz,
    updated_at timestamptz,
    expired_date timestamptz,
    is_agreement_signed boolean,
    permit_number text,
    owner_ktp_number text,
    phone_number text,
    address_line text,
    rt_rw text,
    province_name text,
    city_name text,
    district_name text,
    subdistrict_name text,
    postal_code text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_catalog'
AS $$
  SELECT DISTINCT
    c.id,
    c.name,
    c.slug,
    c.is_active,
    c.owner_user_id,
    c.created_at,
    c.updated_at,
    c.expired_date,
    c.is_agreement_signed,
    c.permit_number,
    c.owner_ktp_number,
    c.phone_number,
    c.address_line,
    c.rt_rw,
    c.province_name,
    c.city_name,
    c.district_name,
    c.subdistrict_name,
    c.postal_code
  FROM public.clinics c
  INNER JOIN public.clinic_extension_requests cer
    ON cer.clinic_id = c.id
   AND cer.status = 'PENDING'
  ORDER BY c.created_at DESC;
$$;
