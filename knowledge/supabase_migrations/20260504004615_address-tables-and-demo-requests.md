# Migration: address-tables-and-demo-requests

- **Timestamp**: 20260504004615
- **Applied At**: 2026-05-04 00:46:15

## Description
Auto-generated migration for database structural changes.

## SQL Content
```sql
CREATE TABLE IF NOT EXISTS public.address_province (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    prov_id integer NOT NULL UNIQUE,
    prov_name varchar(100) NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.address_province ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS public_read_address_province ON public.address_province;
CREATE POLICY "public_read_address_province" ON public.address_province FOR SELECT USING (true);
GRANT SELECT ON public.address_province TO anon, authenticated, service_role;

CREATE TABLE IF NOT EXISTS public.address_city (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    city_id integer NOT NULL UNIQUE,
    city_name varchar(100) NOT NULL,
    prov_id integer NOT NULL REFERENCES public.address_province(prov_id),
    created_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.address_city ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS public_read_address_city ON public.address_city;
CREATE POLICY "public_read_address_city" ON public.address_city FOR SELECT USING (true);
GRANT SELECT ON public.address_city TO anon, authenticated, service_role;

CREATE TABLE IF NOT EXISTS public.address_district (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    dis_id integer NOT NULL UNIQUE,
    dis_name varchar(100) NOT NULL,
    city_id integer NOT NULL REFERENCES public.address_city(city_id),
    created_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.address_district ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS public_read_address_district ON public.address_district;
CREATE POLICY "public_read_address_district" ON public.address_district FOR SELECT USING (true);
GRANT SELECT ON public.address_district TO anon, authenticated, service_role;

CREATE TABLE IF NOT EXISTS public.address_subdistrict (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    subdis_id integer NOT NULL UNIQUE,
    subdis_name varchar(100) NOT NULL,
    dis_id integer NOT NULL REFERENCES public.address_district(dis_id),
    created_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.address_subdistrict ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS public_read_address_subdistrict ON public.address_subdistrict;
CREATE POLICY "public_read_address_subdistrict" ON public.address_subdistrict FOR SELECT USING (true);
GRANT SELECT ON public.address_subdistrict TO anon, authenticated, service_role;

CREATE TABLE IF NOT EXISTS public.address_postal_code (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    postal_id integer NOT NULL UNIQUE,
    postal_code varchar(5) NOT NULL,
    subdis_id integer NOT NULL REFERENCES public.address_subdistrict(subdis_id),
    dis_id integer NOT NULL REFERENCES public.address_district(dis_id),
    city_id integer NOT NULL REFERENCES public.address_city(city_id),
    prov_id integer NOT NULL REFERENCES public.address_province(prov_id),
    created_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.address_postal_code ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS public_read_address_postal_code ON public.address_postal_code;
CREATE POLICY "public_read_address_postal_code" ON public.address_postal_code FOR SELECT USING (true);
GRANT SELECT ON public.address_postal_code TO anon, authenticated, service_role;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'demo_request_status_enum'
  ) THEN
    CREATE TYPE public.demo_request_status_enum AS ENUM ('pending', 'contacted', 'completed', 'cancelled');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.demo_requests (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    clinic_name text NOT NULL,
    clinic_type text,
    pic_name text NOT NULL,
    pic_role text,
    email text NOT NULL,
    whatsapp text NOT NULL,
    province_id uuid REFERENCES public.address_province(id),
    city_id uuid REFERENCES public.address_city(id),
    district_id uuid REFERENCES public.address_district(id),
    subdistrict_id uuid REFERENCES public.address_subdistrict(id),
    postal_code_id uuid REFERENCES public.address_postal_code(id),
    province_name text,
    city_name text,
    district_name text,
    subdistrict_name text,
    postal_code text,
    message text,
    referral_source text,
    status public.demo_request_status_enum DEFAULT 'pending' NOT NULL,
    submitted_at timestamptz DEFAULT now() NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.demo_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS insert_demo_request ON public.demo_requests;
CREATE POLICY "insert_demo_request" ON public.demo_requests FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS service_role_read_demo_request ON public.demo_requests;
CREATE POLICY "service_role_read_demo_request" ON public.demo_requests FOR SELECT TO service_role USING (true);
DROP POLICY IF EXISTS service_role_update_demo_request ON public.demo_requests;
CREATE POLICY "service_role_update_demo_request" ON public.demo_requests FOR UPDATE TO service_role USING (true) WITH CHECK (true);
GRANT INSERT ON public.demo_requests TO anon, authenticated, service_role;
GRANT SELECT, UPDATE ON public.demo_requests TO service_role;

CREATE TABLE IF NOT EXISTS public.edge_rate_limit_events (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    function_name text NOT NULL,
    identifier text NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.edge_rate_limit_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS service_role_manage_edge_rate_limit_events ON public.edge_rate_limit_events;
CREATE POLICY "service_role_manage_edge_rate_limit_events" ON public.edge_rate_limit_events FOR ALL TO service_role USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, DELETE ON public.edge_rate_limit_events TO service_role;
CREATE INDEX IF NOT EXISTS edge_rate_limit_events_lookup_idx ON public.edge_rate_limit_events(function_name, identifier, created_at);

CREATE OR REPLACE FUNCTION public.edge_check_rate_limit(
  p_function_name text,
  p_identifier text,
  p_window_seconds integer,
  p_limit integer
)
RETURNS TABLE(allowed boolean, current_count integer, retry_after_seconds integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
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
GRANT EXECUTE ON FUNCTION public.edge_check_rate_limit(text, text, integer, integer) TO service_role;
```
