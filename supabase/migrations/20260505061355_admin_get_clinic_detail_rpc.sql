


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






CREATE TYPE "public"."admin_level_enum" AS ENUM (
    'STAFF',
    'ADMIN',
    'SUPER_ADMIN'
);


ALTER TYPE "public"."admin_level_enum" OWNER TO "postgres";


CREATE TYPE "public"."demo_request_status_enum" AS ENUM (
    'pending',
    'contacted',
    'completed',
    'cancelled'
);


ALTER TYPE "public"."demo_request_status_enum" OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "public"."admin_add_clinic_member"("p_clinic_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_is_staff" boolean DEFAULT false, "p_is_practitioner" boolean DEFAULT false, "p_profession" "public"."practitioner_profession" DEFAULT NULL::"public"."practitioner_profession") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_membership_id uuid;
  v_profession public.practitioner_profession;
BEGIN
  IF NOT public.is_admin_at_least('STAFF') THEN
    RETURN jsonb_build_object('status', 'error', 'code', 'FORBIDDEN', 'message', 'Caller is not an LBSD admin.');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.clinics WHERE id = p_clinic_id) THEN
    RETURN jsonb_build_object('status', 'error', 'code', 'CLINIC_NOT_FOUND', 'message', 'Clinic does not exist.');
  END IF;

  v_profession := CASE
    WHEN p_is_practitioner THEN COALESCE(p_profession, 'psychologist'::public.practitioner_profession)
    ELSE NULL
  END;

  INSERT INTO public.users (id, role)
  VALUES (p_user_id, 'clinic_staff'::public.user_role)
  ON CONFLICT (id) DO UPDATE
    SET role = 'clinic_staff'::public.user_role,
        updated_at = now();

  INSERT INTO public.clinic_memberships (
    clinic_id,
    user_id,
    is_owner,
    is_staff,
    is_practitioner,
    profession,
    full_name,
    email,
    is_active
  )
  VALUES (
    p_clinic_id,
    p_user_id,
    false,
    p_is_staff,
    p_is_practitioner,
    v_profession,
    p_full_name,
    p_email,
    true
  )
  ON CONFLICT (clinic_id, user_id) DO UPDATE
    SET is_staff = EXCLUDED.is_staff,
        is_practitioner = EXCLUDED.is_practitioner,
        profession = EXCLUDED.profession,
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        is_active = true,
        updated_at = now()
  RETURNING id INTO v_membership_id;

  RETURN jsonb_build_object(
    'status', 'success',
    'message', 'Member added successfully.',
    'membershipId', v_membership_id,
    'userId', p_user_id
  );
EXCEPTION WHEN others THEN
  RETURN jsonb_build_object(
    'status', 'error',
    'code', 'SERVER_ERROR',
    'message', 'Failed to add member: ' || SQLERRM
  );
END;
$$;


ALTER FUNCTION "public"."admin_add_clinic_member"("p_clinic_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_is_staff" boolean, "p_is_practitioner" boolean, "p_profession" "public"."practitioner_profession") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_get_clinic_detail"("p_clinic_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ DECLARE v_result jsonb; BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RETURN jsonb_build_object('status','error','code','FORBIDDEN','message','Caller is not an LBSD admin.'); END IF; SELECT jsonb_build_object( 'clinic_id', c.id, 'clinic_name', c.name, 'clinic_slug', c.slug, 'is_active', c.is_active, 'owner_user_id', c.owner_user_id, 'created_at', c.created_at, 'memberships', COALESCE(( SELECT jsonb_agg( jsonb_build_object( 'membership_id', cm.id, 'user_id', cm.user_id, 'full_name', COALESCE(cm.full_name, SPLIT_PART(au.email, '@', 1)), 'email', COALESCE(cm.email, LOWER(au.email)), 'phone', cm.phone, 'is_owner', cm.is_owner, 'is_staff', cm.is_staff, 'is_practitioner', cm.is_practitioner, 'profession', cm.profession, 'is_active', cm.is_active, 'created_at', cm.created_at ) ORDER BY cm.is_owner DESC, cm.created_at ASC ) FROM public.clinic_memberships cm LEFT JOIN auth.users au ON au.id = cm.user_id WHERE cm.clinic_id = c.id ), '[]'::jsonb) ) INTO v_result FROM public.clinics c WHERE c.id = p_clinic_id; IF v_result IS NULL THEN RETURN jsonb_build_object('status','error','code','NOT_FOUND','message','Clinic not found.'); END IF; RETURN v_result; END; $$;


ALTER FUNCTION "public"."admin_get_clinic_detail"("p_clinic_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_list_clinics"() RETURNS TABLE("clinic_id" "uuid", "clinic_name" "text", "clinic_slug" "text", "is_active" boolean, "owner_name" "text", "owner_email" "text", "total_memberships" bigint, "active_memberships" bigint, "created_at" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ SELECT c.id, c.name, c.slug::text, c.is_active, COALESCE( cm_owner.full_name, au.raw_user_meta_data->>'full_name', au.raw_user_meta_data->>'name', SPLIT_PART(au.email, '@', 1) ) AS owner_name, COALESCE(cm_owner.email, LOWER(au.email)) AS owner_email, COUNT(cm.id) AS total_memberships, COUNT(cm.id) FILTER (WHERE cm.is_active = true) AS active_memberships, c.created_at FROM public.clinics c LEFT JOIN LATERAL ( SELECT cm2.user_id, cm2.full_name, cm2.email FROM public.clinic_memberships cm2 WHERE cm2.clinic_id = c.id AND cm2.is_owner = true AND cm2.is_active = true ORDER BY cm2.created_at ASC LIMIT 1 ) cm_owner ON true LEFT JOIN auth.users au ON au.id = cm_owner.user_id LEFT JOIN public.clinic_memberships cm ON cm.clinic_id = c.id WHERE public.is_admin_at_least('STAFF') GROUP BY c.id, c.name, c.slug, c.is_active, c.created_at, cm_owner.full_name, cm_owner.email, au.raw_user_meta_data, au.email ORDER BY c.created_at DESC; $$;


ALTER FUNCTION "public"."admin_list_clinics"() OWNER TO "postgres";


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
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."demo_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."edge_rate_limit_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "function_name" "text" NOT NULL,
    "identifier" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."edge_rate_limit_events" OWNER TO "postgres";


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



ALTER TABLE ONLY "public"."clinic_memberships"
    ADD CONSTRAINT "clinic_memberships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clinics"
    ADD CONSTRAINT "clinics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."edge_rate_limit_events"
    ADD CONSTRAINT "edge_rate_limit_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "clinic_memberships_clinic_idx" ON "public"."clinic_memberships" USING "btree" ("clinic_id");



CREATE UNIQUE INDEX "clinic_memberships_user_clinic_unique" ON "public"."clinic_memberships" USING "btree" ("clinic_id", "user_id");



CREATE INDEX "clinic_memberships_user_idx" ON "public"."clinic_memberships" USING "btree" ("user_id");



CREATE UNIQUE INDEX "clinics_slug_unique" ON "public"."clinics" USING "btree" ("slug");



CREATE INDEX "edge_rate_limit_events_lookup_idx" ON "public"."edge_rate_limit_events" USING "btree" ("function_name", "identifier", "created_at");



CREATE UNIQUE INDEX "idx_admin_profiles_email_lower" ON "public"."admin_profiles" USING "btree" ("lower"("email")) WHERE ("email" IS NOT NULL);



CREATE OR REPLACE TRIGGER "trg_admin_profiles_audit_fields" BEFORE INSERT OR UPDATE ON "public"."admin_profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_admin_profiles_audit_fields"();



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



ALTER TABLE ONLY "public"."clinic_memberships"
    ADD CONSTRAINT "clinic_memberships_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clinic_memberships"
    ADD CONSTRAINT "clinic_memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."clinics"
    ADD CONSTRAINT "clinics_owner_user_id_fkey" FOREIGN KEY ("owner_user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "public"."address_city"("id");



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_district_id_fkey" FOREIGN KEY ("district_id") REFERENCES "public"."address_district"("id");



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_postal_code_id_fkey" FOREIGN KEY ("postal_code_id") REFERENCES "public"."address_postal_code"("id");



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_province_id_fkey" FOREIGN KEY ("province_id") REFERENCES "public"."address_province"("id");



ALTER TABLE ONLY "public"."demo_requests"
    ADD CONSTRAINT "demo_requests_subdistrict_id_fkey" FOREIGN KEY ("subdistrict_id") REFERENCES "public"."address_subdistrict"("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE "public"."address_city" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."address_district" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."address_postal_code" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."address_province" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."address_subdistrict" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_profiles_admin_insert" ON "public"."admin_profiles" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('ADMIN'::"text"));



CREATE POLICY "admin_profiles_admin_select" ON "public"."admin_profiles" FOR SELECT TO "authenticated" USING ("public"."is_admin_at_least"('ADMIN'::"text"));



CREATE POLICY "admin_profiles_admin_update" ON "public"."admin_profiles" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('ADMIN'::"text")) WITH CHECK ("public"."is_admin_at_least"('ADMIN'::"text"));



CREATE POLICY "admin_profiles_read_own_profile" ON "public"."admin_profiles" FOR SELECT TO "authenticated" USING (("id" = "auth"."uid"()));



CREATE POLICY "admin_profiles_super_admin_delete" ON "public"."admin_profiles" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('SUPER_ADMIN'::"text"));



CREATE POLICY "admin_read_demo_request" ON "public"."demo_requests" FOR SELECT TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text"));



ALTER TABLE "public"."demo_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."edge_rate_limit_events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "insert_demo_request" ON "public"."demo_requests" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "public_read_address_city" ON "public"."address_city" FOR SELECT USING (true);



CREATE POLICY "public_read_address_district" ON "public"."address_district" FOR SELECT USING (true);



CREATE POLICY "public_read_address_postal_code" ON "public"."address_postal_code" FOR SELECT USING (true);



CREATE POLICY "public_read_address_province" ON "public"."address_province" FOR SELECT USING (true);



CREATE POLICY "public_read_address_subdistrict" ON "public"."address_subdistrict" FOR SELECT USING (true);



CREATE POLICY "service_role_manage_edge_rate_limit_events" ON "public"."edge_rate_limit_events" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service_role_read_demo_request" ON "public"."demo_requests" FOR SELECT TO "service_role" USING (true);



CREATE POLICY "service_role_update_demo_request" ON "public"."demo_requests" FOR UPDATE TO "service_role" USING (true) WITH CHECK (true);





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";































































































































































GRANT ALL ON FUNCTION "public"."admin_add_clinic_member"("p_clinic_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_is_staff" boolean, "p_is_practitioner" boolean, "p_profession" "public"."practitioner_profession") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_add_clinic_member"("p_clinic_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_is_staff" boolean, "p_is_practitioner" boolean, "p_profession" "public"."practitioner_profession") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_add_clinic_member"("p_clinic_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_is_staff" boolean, "p_is_practitioner" boolean, "p_profession" "public"."practitioner_profession") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_get_clinic_detail"("p_clinic_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_get_clinic_detail"("p_clinic_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_get_clinic_detail"("p_clinic_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_list_clinics"() TO "anon";
GRANT ALL ON FUNCTION "public"."admin_list_clinics"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_list_clinics"() TO "service_role";



GRANT ALL ON FUNCTION "public"."edge_check_rate_limit"("p_function_name" "text", "p_identifier" "text", "p_window_seconds" integer, "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."edge_check_rate_limit"("p_function_name" "text", "p_identifier" "text", "p_window_seconds" integer, "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."edge_check_rate_limit"("p_function_name" "text", "p_identifier" "text", "p_window_seconds" integer, "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin_at_least"("p_min_role" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin_at_least"("p_min_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin_at_least"("p_min_role" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_admin_profiles_audit_fields"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_admin_profiles_audit_fields"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_admin_profiles_audit_fields"() TO "service_role";


















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



GRANT ALL ON TABLE "public"."clinic_memberships" TO "anon";
GRANT ALL ON TABLE "public"."clinic_memberships" TO "authenticated";
GRANT ALL ON TABLE "public"."clinic_memberships" TO "service_role";



GRANT ALL ON TABLE "public"."clinics" TO "anon";
GRANT ALL ON TABLE "public"."clinics" TO "authenticated";
GRANT ALL ON TABLE "public"."clinics" TO "service_role";



GRANT ALL ON TABLE "public"."demo_requests" TO "anon";
GRANT ALL ON TABLE "public"."demo_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."demo_requests" TO "service_role";



GRANT ALL ON TABLE "public"."edge_rate_limit_events" TO "anon";
GRANT ALL ON TABLE "public"."edge_rate_limit_events" TO "authenticated";
GRANT ALL ON TABLE "public"."edge_rate_limit_events" TO "service_role";



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

