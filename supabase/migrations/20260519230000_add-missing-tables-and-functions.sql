-- Migration: Add 12 missing tables and 10 RPC functions
-- Extracted from 20260518234046_rebuild-from-schema.sql

-- ============================================================
-- MISSING CLINICS COLUMNS (remote table is behind)
-- ============================================================
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "expired_date" timestamp with time zone;
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "is_agreement_signed" boolean DEFAULT false;
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "permit_number" "text";
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "owner_ktp_number" "text";
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "phone_number" "text";
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "address_line" "text";
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "rt_rw" "text";
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "province_name" "text";
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "city_name" "text";
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "district_name" "text";
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "subdistrict_name" "text";
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "postal_code" "text";
ALTER TABLE IF EXISTS "public"."clinics" ADD COLUMN IF NOT EXISTS "full_address" "text";

-- ============================================================
-- ENUM TYPES
-- ============================================================
DO $$ BEGIN
    CREATE TYPE "public"."clinic_extension_request_status_enum" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 1. b2b_agreement_templates
-- ============================================================
CREATE TABLE IF NOT EXISTS "public"."b2b_agreement_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "is_active" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);
ALTER TABLE IF EXISTS "public"."b2b_agreement_templates" OWNER TO "postgres";
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'b2b_agreement_templates_pkey') THEN ALTER TABLE ONLY "public"."b2b_agreement_templates" ADD CONSTRAINT "b2b_agreement_templates_pkey" PRIMARY KEY ("id"); END IF; END $$;
ALTER TABLE "public"."b2b_agreement_templates" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN CREATE POLICY "admin_all_b2b_templates" ON "public"."b2b_agreement_templates" TO "authenticated" USING ((EXISTS (SELECT 1 FROM "public"."admin_profiles" WHERE (("admin_profiles"."id" = "auth"."uid"()) AND ("admin_profiles"."is_active" = true))))); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "public_read_active_b2b_template" ON "public"."b2b_agreement_templates" FOR SELECT TO "anon" USING (("is_active" = true)); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT ALL ON TABLE "public"."b2b_agreement_templates" TO "anon";
GRANT ALL ON TABLE "public"."b2b_agreement_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."b2b_agreement_templates" TO "service_role";

-- ============================================================
-- 2. b2b_agreements
-- ============================================================
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
ALTER TABLE IF EXISTS "public"."b2b_agreements" OWNER TO "postgres";
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'b2b_agreements_pkey') THEN ALTER TABLE ONLY "public"."b2b_agreements" ADD CONSTRAINT "b2b_agreements_pkey" PRIMARY KEY ("id"); END IF; END $$;
ALTER TABLE "public"."b2b_agreements" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN ALTER TABLE ONLY "public"."b2b_agreements" ADD CONSTRAINT "b2b_agreements_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ONLY "public"."b2b_agreements" ADD CONSTRAINT "b2b_agreements_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "public"."b2b_agreement_templates"("id") ON DELETE RESTRICT;    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "b2b_agreements_owner_insert" ON "public"."b2b_agreements" FOR INSERT TO "authenticated" WITH CHECK ("public"."has_owner_access"("clinic_id")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "b2b_agreements_select" ON "public"."b2b_agreements" FOR SELECT TO "authenticated" USING (("public"."is_admin_at_least"('STAFF'::"text") OR "public"."has_active_membership"("clinic_id"))); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT ALL ON TABLE "public"."b2b_agreements" TO "anon";
GRANT ALL ON TABLE "public"."b2b_agreements" TO "authenticated";
GRANT ALL ON TABLE "public"."b2b_agreements" TO "service_role";

-- ============================================================
-- 3. b2b_invitations
-- ============================================================
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
ALTER TABLE IF EXISTS "public"."b2b_invitations" OWNER TO "postgres";
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'b2b_invitations_pkey') THEN ALTER TABLE ONLY "public"."b2b_invitations" ADD CONSTRAINT "b2b_invitations_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'b2b_invitations_token_hash_key') THEN ALTER TABLE ONLY "public"."b2b_invitations" ADD CONSTRAINT "b2b_invitations_token_hash_key" UNIQUE ("token_hash"); END IF; END $$;
ALTER TABLE "public"."b2b_invitations" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN ALTER TABLE ONLY "public"."b2b_invitations" ADD CONSTRAINT "b2b_invitations_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ONLY "public"."b2b_invitations" ADD CONSTRAINT "b2b_invitations_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ONLY "public"."b2b_invitations" ADD CONSTRAINT "b2b_invitations_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "public"."b2b_agreement_templates"("id");    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "admin_all_b2b_invitations" ON "public"."b2b_invitations" TO "authenticated" USING ((EXISTS (SELECT 1 FROM "public"."admin_profiles" WHERE (("admin_profiles"."id" = "auth"."uid"()) AND ("admin_profiles"."is_active" = true))))); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "clinic_owner_read_b2b_invitations" ON "public"."b2b_invitations" FOR SELECT TO "authenticated" USING ((EXISTS (SELECT 1 FROM "public"."clinic_memberships" WHERE (("clinic_memberships"."clinic_id" = "b2b_invitations"."clinic_id") AND ("clinic_memberships"."user_id" = "auth"."uid"()) AND ("clinic_memberships"."is_owner" = true) AND ("clinic_memberships"."is_active" = true))))); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "public_read_pending_b2b_invitation" ON "public"."b2b_invitations" FOR SELECT TO "anon" USING (("status" = 'pending'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "public_update_b2b_invitation" ON "public"."b2b_invitations" FOR UPDATE TO "anon" USING (("status" = 'pending'::"text")) WITH CHECK (("status" = 'signed'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT ALL ON TABLE "public"."b2b_invitations" TO "anon";
GRANT ALL ON TABLE "public"."b2b_invitations" TO "authenticated";
GRANT ALL ON TABLE "public"."b2b_invitations" TO "service_role";

-- ============================================================
-- 4. clinic_extension_requests
-- ============================================================
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
ALTER TABLE IF EXISTS "public"."clinic_extension_requests" OWNER TO "postgres";
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'clinic_extension_requests_pkey') THEN ALTER TABLE ONLY "public"."clinic_extension_requests" ADD CONSTRAINT "clinic_extension_requests_pkey" PRIMARY KEY ("id"); END IF; END $$;
CREATE UNIQUE INDEX IF NOT EXISTS "clinic_extension_requests_b2b_agreement_id_key" ON "public"."clinic_extension_requests" USING "btree" ("b2b_agreement_id");
CREATE INDEX IF NOT EXISTS "clinic_extension_requests_clinic_id_requested_at_idx" ON "public"."clinic_extension_requests" USING "btree" ("clinic_id", "requested_at" DESC);
CREATE UNIQUE INDEX IF NOT EXISTS "clinic_extension_requests_pending_unique_idx" ON "public"."clinic_extension_requests" USING "btree" ("clinic_id") WHERE ("status" = 'PENDING'::"public"."clinic_extension_request_status_enum");
ALTER TABLE "public"."clinic_extension_requests" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN ALTER TABLE ONLY "public"."clinic_extension_requests" ADD CONSTRAINT "clinic_extension_requests_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "public"."admin_profiles"("id") ON DELETE SET NULL;    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ONLY "public"."clinic_extension_requests" ADD CONSTRAINT "clinic_extension_requests_b2b_agreement_id_fkey" FOREIGN KEY ("b2b_agreement_id") REFERENCES "public"."b2b_agreements"("id") ON DELETE RESTRICT;    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ONLY "public"."clinic_extension_requests" ADD CONSTRAINT "clinic_extension_requests_clinic_id_fkey" FOREIGN KEY ("clinic_id") REFERENCES "public"."clinics"("id") ON DELETE CASCADE;    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "clinic_extension_requests_insert" ON "public"."clinic_extension_requests" FOR INSERT TO "authenticated" WITH CHECK (("public"."is_admin_at_least"('STAFF'::"text") OR "public"."has_owner_access"("clinic_id"))); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "clinic_extension_requests_select" ON "public"."clinic_extension_requests" FOR SELECT TO "authenticated" USING (("public"."is_admin_at_least"('STAFF'::"text") OR "public"."has_active_membership"("clinic_id"))); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "clinic_extension_requests_update" ON "public"."clinic_extension_requests" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")) WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT ALL ON TABLE "public"."clinic_extension_requests" TO "anon";
GRANT ALL ON TABLE "public"."clinic_extension_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."clinic_extension_requests" TO "service_role";

-- ============================================================
-- 5. consent_templates
-- ============================================================
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
ALTER TABLE IF EXISTS "public"."consent_templates" OWNER TO "postgres";
CREATE UNIQUE INDEX IF NOT EXISTS "consent_templates_single_active_idx" ON "public"."consent_templates" USING "btree" ("is_active") WHERE ("is_active" = true);
ALTER TABLE "public"."consent_templates" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN CREATE POLICY "consent_templates_delete" ON "public"."consent_templates" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('ADMIN'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "consent_templates_insert" ON "public"."consent_templates" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('ADMIN'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "consent_templates_select" ON "public"."consent_templates" FOR SELECT TO "authenticated" USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "consent_templates_update" ON "public"."consent_templates" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('ADMIN'::"text")) WITH CHECK ("public"."is_admin_at_least"('ADMIN'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT ALL ON TABLE "public"."consent_templates" TO "anon";
GRANT ALL ON TABLE "public"."consent_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."consent_templates" TO "service_role";

-- ============================================================
-- 6. education
-- ============================================================
CREATE TABLE IF NOT EXISTS "public"."education" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "order_index" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid"
);
ALTER TABLE IF EXISTS "public"."education" OWNER TO "postgres";
CREATE UNIQUE INDEX IF NOT EXISTS "education_name_unique_idx" ON "public"."education" USING "btree" ("lower"("name"));
ALTER TABLE "public"."education" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN ALTER TABLE ONLY "public"."education" ADD CONSTRAINT "education_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ONLY "public"."education" ADD CONSTRAINT "education_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "education_admin_delete" ON "public"."education" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "education_admin_insert" ON "public"."education" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "education_admin_update" ON "public"."education" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")) WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "education_select_all" ON "public"."education" FOR SELECT TO "authenticated", "anon" USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT ALL ON TABLE "public"."education" TO "anon";
GRANT ALL ON TABLE "public"."education" TO "authenticated";
GRANT ALL ON TABLE "public"."education" TO "service_role";

-- ============================================================
-- 7. marital_status
-- ============================================================
CREATE TABLE IF NOT EXISTS "public"."marital_status" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "order_index" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid"
);
ALTER TABLE IF EXISTS "public"."marital_status" OWNER TO "postgres";
CREATE UNIQUE INDEX IF NOT EXISTS "marital_status_name_unique_idx" ON "public"."marital_status" USING "btree" ("lower"("name"));
ALTER TABLE "public"."marital_status" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN ALTER TABLE ONLY "public"."marital_status" ADD CONSTRAINT "marital_status_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ONLY "public"."marital_status" ADD CONSTRAINT "marital_status_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "marital_status_admin_delete" ON "public"."marital_status" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "marital_status_admin_insert" ON "public"."marital_status" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "marital_status_admin_update" ON "public"."marital_status" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")) WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "marital_status_select_all" ON "public"."marital_status" FOR SELECT TO "authenticated", "anon" USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT ALL ON TABLE "public"."marital_status" TO "anon";
GRANT ALL ON TABLE "public"."marital_status" TO "authenticated";
GRANT ALL ON TABLE "public"."marital_status" TO "service_role";

-- ============================================================
-- 8. occupation
-- ============================================================
CREATE TABLE IF NOT EXISTS "public"."occupation" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "order_index" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid"
);
ALTER TABLE IF EXISTS "public"."occupation" OWNER TO "postgres";
CREATE UNIQUE INDEX IF NOT EXISTS "occupation_name_unique_idx" ON "public"."occupation" USING "btree" ("lower"("name"));
ALTER TABLE "public"."occupation" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN ALTER TABLE ONLY "public"."occupation" ADD CONSTRAINT "occupation_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ONLY "public"."occupation" ADD CONSTRAINT "occupation_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "occupation_admin_delete" ON "public"."occupation" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "occupation_admin_insert" ON "public"."occupation" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "occupation_admin_update" ON "public"."occupation" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")) WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "occupation_select_all" ON "public"."occupation" FOR SELECT TO "authenticated", "anon" USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT ALL ON TABLE "public"."occupation" TO "anon";
GRANT ALL ON TABLE "public"."occupation" TO "authenticated";
GRANT ALL ON TABLE "public"."occupation" TO "service_role";

-- ============================================================
-- 9. otp_verifications
-- ============================================================
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
ALTER TABLE IF EXISTS "public"."otp_verifications" OWNER TO "postgres";
CREATE INDEX IF NOT EXISTS "idx_otp_verifications_email_created_at" ON "public"."otp_verifications" USING "btree" ("email", "created_at" DESC);
ALTER TABLE "public"."otp_verifications" ENABLE ROW LEVEL SECURITY;
GRANT ALL ON TABLE "public"."otp_verifications" TO "anon";
GRANT ALL ON TABLE "public"."otp_verifications" TO "authenticated";
GRANT ALL ON TABLE "public"."otp_verifications" TO "service_role";

-- ============================================================
-- 10. patient_consents
-- ============================================================
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
ALTER TABLE IF EXISTS "public"."patient_consents" OWNER TO "postgres";
CREATE INDEX IF NOT EXISTS "idx_patient_consents_patient_id" ON "public"."patient_consents" USING "btree" ("patient_id");
CREATE INDEX IF NOT EXISTS "idx_patient_consents_visit_id" ON "public"."patient_consents" USING "btree" ("visit_id");
ALTER TABLE "public"."patient_consents" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN ALTER TABLE ONLY "public"."patient_consents" ADD CONSTRAINT "patient_consents_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ONLY "public"."patient_consents" ADD CONSTRAINT "patient_consents_visit_id_fkey" FOREIGN KEY ("visit_id") REFERENCES "public"."patient_visits"("id") ON DELETE CASCADE;    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "patient_consents_insert" ON "public"."patient_consents" FOR INSERT TO "authenticated" WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "patient_consents_select" ON "public"."patient_consents" FOR SELECT TO "authenticated" USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "patient_consents_update" ON "public"."patient_consents" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT ALL ON TABLE "public"."patient_consents" TO "anon";
GRANT ALL ON TABLE "public"."patient_consents" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_consents" TO "service_role";

-- ============================================================
-- 11. patient_signatures
-- ============================================================
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
ALTER TABLE IF EXISTS "public"."patient_signatures" OWNER TO "postgres";
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'patient_signatures_patient_id_key') THEN ALTER TABLE ONLY "public"."patient_signatures" ADD CONSTRAINT "patient_signatures_patient_id_key" UNIQUE ("patient_id"); END IF; END $$;
ALTER TABLE "public"."patient_signatures" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN ALTER TABLE ONLY "public"."patient_signatures" ADD CONSTRAINT "patient_signatures_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("id") ON DELETE CASCADE;    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "patient_signatures_clinic_ops_select" ON "public"."patient_signatures" FOR SELECT TO "authenticated" USING ((EXISTS (SELECT 1 FROM "public"."clinic_patients" "cp" WHERE (("cp"."patient_id" = "patient_signatures"."patient_id") AND "public"."has_ops_access"("cp"."clinic_id"))))); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT ALL ON TABLE "public"."patient_signatures" TO "anon";
GRANT ALL ON TABLE "public"."patient_signatures" TO "authenticated";
GRANT ALL ON TABLE "public"."patient_signatures" TO "service_role";

-- ============================================================
-- 12. religion
-- ============================================================
CREATE TABLE IF NOT EXISTS "public"."religion" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "order_index" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid"
);
ALTER TABLE IF EXISTS "public"."religion" OWNER TO "postgres";
CREATE UNIQUE INDEX IF NOT EXISTS "religion_name_unique_idx" ON "public"."religion" USING "btree" ("lower"("name"));
ALTER TABLE "public"."religion" ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN ALTER TABLE ONLY "public"."religion" ADD CONSTRAINT "religion_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE ONLY "public"."religion" ADD CONSTRAINT "religion_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id");    EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "religion_admin_delete" ON "public"."religion" FOR DELETE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "religion_admin_insert" ON "public"."religion" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "religion_admin_update" ON "public"."religion" FOR UPDATE TO "authenticated" USING ("public"."is_admin_at_least"('STAFF'::"text")) WITH CHECK ("public"."is_admin_at_least"('STAFF'::"text")); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "religion_select_all" ON "public"."religion" FOR SELECT TO "authenticated", "anon" USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
GRANT ALL ON TABLE "public"."religion" TO "anon";
GRANT ALL ON TABLE "public"."religion" TO "authenticated";
GRANT ALL ON TABLE "public"."religion" TO "service_role";

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- accept_patient_consent_by_token (3-param overload)
CREATE OR REPLACE FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "consent_ip" "text" DEFAULT NULL::"text", "consent_user_agent" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER SET "search_path" TO 'public'
    AS $$ declare invitation_row public.patient_invitations%rowtype; clinic_patient_id_value uuid; practitioner_membership_id_value uuid; appointment_id_value uuid; visit_id_value uuid; session_start_at_value timestamptz; session_end_at_value timestamptz; consent_text_value text := 'Saya menyetujui berbagi data medis saya dengan klinik tujuan untuk keperluan layanan psikologi.'; begin if invite_token is null or btrim(invite_token) = '' then return jsonb_build_object('status', 'error', 'code', 'INVALID_TOKEN', 'message', 'Token undangan tidak valid.'); end if; select * into invitation_row from public.patient_invitations pi where pi.token = invite_token limit 1 for update; if not found then return jsonb_build_object('status', 'error', 'code', 'INVITATION_NOT_FOUND', 'message', 'Undangan tidak ditemukan.'); end if; if invitation_row.flow <> 'consent_required'::public.patient_invitation_flow then return jsonb_build_object('status', 'error', 'code', 'INVALID_FLOW', 'message', 'Undangan ini tidak menggunakan flow persetujuan data.'); end if; if coalesce(invitation_row.is_used, false) then if invitation_row.used_reason = 'superseded'::public.patient_invitation_used_reason then return jsonb_build_object('status', 'error', 'code', 'INVITATION_SUPERSEDED', 'message', 'Link undangan ini sudah diganti dengan undangan terbaru.'); end if; return jsonb_build_object('status', 'error', 'code', 'INVITATION_USED', 'message', 'Link undangan sudah digunakan.'); end if; if invitation_row.expires_at < now() then return jsonb_build_object('status', 'error', 'code', 'INVITATION_EXPIRED', 'message', 'Link undangan sudah kedaluwarsa.'); end if; if invitation_row.target_patient_id is null then return jsonb_build_object('status', 'error', 'code', 'PATIENT_NOT_FOUND', 'message', 'Data pasien untuk undangan ini belum tersedia.'); end if; if invitation_row.clinic_id is null then return jsonb_build_object('status', 'error', 'code', 'INVITATION_CLINIC_REQUIRED', 'message', 'Undangan belum terhubung ke klinik.'); end if; practitioner_membership_id_value := invitation_row.practitioner_membership_id; if practitioner_membership_id_value is null or not exists (select 1 from public.clinic_memberships cm where cm.id = practitioner_membership_id_value and cm.is_active = true and cm.is_practitioner = true) then select cm.id into practitioner_membership_id_value from public.clinic_memberships cm where cm.clinic_id = invitation_row.clinic_id and cm.is_active = true and cm.is_practitioner = true order by cm.is_owner desc, cm.created_at asc limit 1; end if; if practitioner_membership_id_value is null then return jsonb_build_object('status', 'error', 'code', 'NO_PRACTITIONER', 'message', 'Tidak ada practitioner aktif pada klinik ini.'); end if; if not exists (select 1 from public.patient_clinic_consents pcc where pcc.clinic_id = invitation_row.clinic_id and pcc.patient_id = invitation_row.target_patient_id and pcc.revoked_at is null) then insert into public.patient_clinic_consents (clinic_id, patient_id, invitation_id, consent_version, consent_text, source, accepted_at, accepted_ip, accepted_user_agent, created_at, updated_at) values (invitation_row.clinic_id, invitation_row.target_patient_id, invitation_row.id, 'v1', consent_text_value, 'invite_consent_page'::public.consent_source, now(), nullif(consent_ip, ''), nullif(consent_user_agent, ''), now(), now()); end if; insert into public.clinic_patients (clinic_id, patient_id, mrn, is_active) values (invitation_row.clinic_id, invitation_row.target_patient_id, coalesce((select p.mrn from public.patients p where p.id = invitation_row.target_patient_id), 'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6))), true) on conflict (clinic_id, patient_id) do update set is_active = true, updated_at = now() returning id into clinic_patient_id_value; appointment_id_value := invitation_row.appointment_id; if appointment_id_value is null then session_start_at_value := coalesce(invitation_row.session_start_at, date_trunc('day', now()) + interval '1 day' + interval '9 hours'); session_end_at_value := coalesce(invitation_row.session_end_at, session_start_at_value + interval '45 minutes'); insert into public.appointments (clinic_id, clinic_patient_id, patient_id, practitioner_membership_id, start_time, end_time, status, notes) values (invitation_row.clinic_id, clinic_patient_id_value, invitation_row.target_patient_id, practitioner_membership_id_value, session_start_at_value, session_end_at_value, 'scheduled', 'Auto-created after consent acceptance') returning id into appointment_id_value; end if; select pv.id into visit_id_value from public.patient_visits pv where pv.appointment_id = appointment_id_value limit 1; if visit_id_value is null then insert into public.patient_visits (clinic_id, clinic_patient_id, patient_id, appointment_id, status) values (invitation_row.clinic_id, clinic_patient_id_value, invitation_row.target_patient_id, appointment_id_value, 'scheduled') returning id into visit_id_value; end if; update public.patient_invitations set is_used = true, used_at = now(), used_reason = 'consent_accepted'::public.patient_invitation_used_reason, appointment_id = appointment_id_value, practitioner_membership_id = practitioner_membership_id_value where id = invitation_row.id; return jsonb_build_object('status', 'success', 'message', 'Persetujuan data berhasil. Jadwal sesi sudah dikonfirmasi.', 'patientId', invitation_row.target_patient_id, 'clinicId', invitation_row.clinic_id, 'appointmentId', appointment_id_value, 'visitId', visit_id_value); exception when others then return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal memproses persetujuan: ' || sqlerrm); end; $$;

-- accept_patient_consent_by_token (4-param overload with signature_id)
CREATE OR REPLACE FUNCTION "public"."accept_patient_consent_by_token"("invite_token" "text", "signature_id" "uuid", "consent_ip" "text" DEFAULT NULL::"text", "consent_user_agent" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER SET "search_path" TO 'public'
    AS $$ declare invitation_row public.patient_invitations%rowtype; clinic_patient_id_value uuid; practitioner_membership_id_value uuid; appointment_id_value uuid; visit_id_value uuid; session_start_at_value timestamptz; session_end_at_value timestamptz; consent_text_value text := 'Saya menyetujui berbagi data medis saya dengan klinik tujuan untuk keperluan layanan psikologi.'; begin if invite_token is null or btrim(invite_token) = '' then return jsonb_build_object('status', 'error', 'code', 'INVALID_TOKEN', 'message', 'Token undangan tidak valid.'); end if; if signature_id is null then return jsonb_build_object('status', 'error', 'code', 'SIGNATURE_REQUIRED', 'message', 'Tanda tangan digital wajib diisi.'); end if; select * into invitation_row from public.patient_invitations pi where pi.token = invite_token limit 1 for update; if not found then return jsonb_build_object('status', 'error', 'code', 'INVITATION_NOT_FOUND', 'message', 'Undangan tidak ditemukan.'); end if; if invitation_row.flow <> 'consent_required'::public.patient_invitation_flow then return jsonb_build_object('status', 'error', 'code', 'INVALID_FLOW', 'message', 'Undangan ini tidak menggunakan flow persetujuan data.'); end if; if coalesce(invitation_row.is_used, false) then if invitation_row.used_reason = 'superseded'::public.patient_invitation_used_reason then return jsonb_build_object('status', 'error', 'code', 'INVITATION_SUPERSEDED', 'message', 'Link undangan ini sudah diganti dengan undangan terbaru.'); end if; return jsonb_build_object('status', 'error', 'code', 'INVITATION_USED', 'message', 'Link undangan sudah digunakan.'); end if; if invitation_row.expires_at < now() then return jsonb_build_object('status', 'error', 'code', 'INVITATION_EXPIRED', 'message', 'Link undangan sudah kedaluwarsa.'); end if; if invitation_row.target_patient_id is null then return jsonb_build_object('status', 'error', 'code', 'PATIENT_NOT_FOUND', 'message', 'Data pasien untuk undangan ini belum tersedia.'); end if; if invitation_row.clinic_id is null then return jsonb_build_object('status', 'error', 'code', 'INVITATION_CLINIC_REQUIRED', 'message', 'Undangan belum terhubung ke klinik.'); end if; if not exists (select 1 from public.patient_signatures ps where ps.id = signature_id and ps.patient_id = invitation_row.target_patient_id) then return jsonb_build_object('status', 'error', 'code', 'SIGNATURE_INVALID', 'message', 'Tanda tangan digital tidak valid untuk pasien ini.'); end if; practitioner_membership_id_value := invitation_row.practitioner_membership_id; if practitioner_membership_id_value is null or not exists (select 1 from public.clinic_memberships cm where cm.id = practitioner_membership_id_value and cm.is_active = true and cm.is_practitioner = true) then select cm.id into practitioner_membership_id_value from public.clinic_memberships cm where cm.clinic_id = invitation_row.clinic_id and cm.is_active = true and cm.is_practitioner = true order by cm.is_owner desc, cm.created_at asc limit 1; end if; if practitioner_membership_id_value is null then return jsonb_build_object('status', 'error', 'code', 'NO_PRACTITIONER', 'message', 'Tidak ada practitioner aktif pada klinik ini.'); end if; if not exists (select 1 from public.patient_clinic_consents pcc where pcc.clinic_id = invitation_row.clinic_id and pcc.patient_id = invitation_row.target_patient_id and pcc.revoked_at is null) then insert into public.patient_clinic_consents (clinic_id, patient_id, invitation_id, consent_version, consent_text, source, accepted_at, accepted_ip, accepted_user_agent, signature_id, created_at, updated_at) values (invitation_row.clinic_id, invitation_row.target_patient_id, invitation_row.id, 'v1', consent_text_value, 'invite_consent_page'::public.consent_source, now(), nullif(consent_ip, ''), nullif(consent_user_agent, ''), signature_id, now(), now()); end if; insert into public.clinic_patients (clinic_id, patient_id, mrn, is_active) values (invitation_row.clinic_id, invitation_row.target_patient_id, coalesce((select p.mrn from public.patients p where p.id = invitation_row.target_patient_id), 'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6))), true) on conflict (clinic_id, patient_id) do update set is_active = true, updated_at = now() returning id into clinic_patient_id_value; appointment_id_value := invitation_row.appointment_id; if appointment_id_value is null then session_start_at_value := coalesce(invitation_row.session_start_at, date_trunc('day', now()) + interval '1 day' + interval '9 hours'); session_end_at_value := coalesce(invitation_row.session_end_at, session_start_at_value + interval '45 minutes'); insert into public.appointments (clinic_id, clinic_patient_id, patient_id, practitioner_membership_id, start_time, end_time, status, notes) values (invitation_row.clinic_id, clinic_patient_id_value, invitation_row.target_patient_id, practitioner_membership_id_value, session_start_at_value, session_end_at_value, 'scheduled', 'Auto-created after consent acceptance') returning id into appointment_id_value; end if; select pv.id into visit_id_value from public.patient_visits pv where pv.appointment_id = appointment_id_value limit 1; if visit_id_value is null then insert into public.patient_visits (clinic_id, clinic_patient_id, patient_id, appointment_id, status) values (invitation_row.clinic_id, clinic_patient_id_value, invitation_row.target_patient_id, appointment_id_value, 'scheduled') returning id into visit_id_value; end if; update public.patient_invitations set is_used = true, used_at = now(), used_reason = 'consent_accepted'::public.patient_invitation_used_reason, appointment_id = appointment_id_value, practitioner_membership_id = practitioner_membership_id_value where id = invitation_row.id; return jsonb_build_object('status', 'success', 'message', 'Persetujuan data berhasil. Jadwal sesi sudah dikonfirmasi.', 'patientId', invitation_row.target_patient_id, 'clinicId', invitation_row.clinic_id, 'appointmentId', appointment_id_value, 'visitId', visit_id_value); exception when others then return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal memproses persetujuan: ' || sqlerrm); end; $$;

-- admin_add_clinic_member
CREATE OR REPLACE FUNCTION "public"."admin_add_clinic_member"("p_clinic_id" "uuid", "p_user_id" "uuid", "p_full_name" "text", "p_email" "text", "p_is_staff" boolean DEFAULT false, "p_is_practitioner" boolean DEFAULT false, "p_profession" "public"."practitioner_profession" DEFAULT NULL::"public"."practitioner_profession") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER SET "search_path" TO 'public'
    AS $$ DECLARE v_membership_id uuid; v_profession public.practitioner_profession; BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RETURN jsonb_build_object('status', 'error', 'code', 'FORBIDDEN', 'message', 'Caller is not an LBSD admin.'); END IF; IF NOT EXISTS (SELECT 1 FROM public.clinics WHERE id = p_clinic_id) THEN RETURN jsonb_build_object('status', 'error', 'code', 'CLINIC_NOT_FOUND', 'message', 'Clinic does not exist.'); END IF; v_profession := CASE WHEN p_is_practitioner THEN COALESCE(p_profession, 'psychologist'::public.practitioner_profession) ELSE NULL END; INSERT INTO public.users (id, role) VALUES (p_user_id, 'clinic_staff'::public.user_role) ON CONFLICT (id) DO UPDATE SET role = 'clinic_staff'::public.user_role, updated_at = now(); INSERT INTO public.clinic_memberships (clinic_id, user_id, is_owner, is_staff, is_practitioner, profession, full_name, email, is_active) VALUES (p_clinic_id, p_user_id, false, p_is_staff, p_is_practitioner, v_profession, p_full_name, p_email, true) ON CONFLICT (clinic_id, user_id) DO UPDATE SET is_staff = EXCLUDED.is_staff, is_practitioner = EXCLUDED.is_practitioner, profession = EXCLUDED.profession, full_name = EXCLUDED.full_name, email = EXCLUDED.email, is_active = true, updated_at = now() RETURNING id INTO v_membership_id; RETURN jsonb_build_object('status', 'success', 'message', 'Member added successfully.', 'membershipId', v_membership_id, 'userId', p_user_id); EXCEPTION WHEN others THEN RETURN jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Failed to add member: ' || SQLERRM); END; $$;

-- admin_get_clinic_detail
CREATE OR REPLACE FUNCTION "public"."admin_get_clinic_detail"("p_clinic_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER SET "search_path" TO 'public'
    AS $$ DECLARE v_result jsonb; BEGIN IF NOT public.is_admin_at_least('STAFF') THEN RETURN jsonb_build_object('status','error','code','FORBIDDEN','message','Caller is not an LBSD admin.'); END IF; SELECT jsonb_build_object('clinic_id', c.id, 'clinic_name', c.name, 'clinic_slug', c.slug, 'is_active', c.is_active, 'owner_user_id', c.owner_user_id, 'created_at', c.created_at, 'memberships', COALESCE((SELECT jsonb_agg(jsonb_build_object('membership_id', cm.id, 'user_id', cm.user_id, 'full_name', COALESCE(cm.full_name, SPLIT_PART(au.email, '@', 1)), 'email', COALESCE(cm.email, LOWER(au.email)), 'phone', cm.phone, 'is_owner', cm.is_owner, 'is_staff', cm.is_staff, 'is_practitioner', cm.is_practitioner, 'profession', cm.profession, 'is_active', cm.is_active, 'created_at', cm.created_at) ORDER BY cm.is_owner DESC, cm.created_at ASC) FROM public.clinic_memberships cm LEFT JOIN auth.users au ON au.id = cm.user_id WHERE cm.clinic_id = c.id), '[]'::jsonb)) INTO v_result FROM public.clinics c WHERE c.id = p_clinic_id; IF v_result IS NULL THEN RETURN jsonb_build_object('status','error','code','NOT_FOUND','message','Clinic not found.'); END IF; RETURN v_result; END; $$;

-- admin_list_clinics
CREATE OR REPLACE FUNCTION "public"."admin_list_clinics"() RETURNS TABLE("clinic_id" "uuid", "clinic_name" "text", "clinic_slug" "text", "is_active" boolean, "owner_name" "text", "owner_email" "text", "total_memberships" bigint, "active_memberships" bigint, "created_at" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER SET "search_path" TO 'public'
    AS $$ SELECT c.id, c.name, c.slug::text, c.is_active, COALESCE(cm_owner.full_name, au.raw_user_meta_data->>'full_name', au.raw_user_meta_data->>'name', SPLIT_PART(au.email, '@', 1)) AS owner_name, COALESCE(cm_owner.email, LOWER(au.email)) AS owner_email, COUNT(cm.id) AS total_memberships, COUNT(cm.id) FILTER (WHERE cm.is_active = true) AS active_memberships, c.created_at FROM public.clinics c LEFT JOIN LATERAL (SELECT cm2.user_id, cm2.full_name, cm2.email FROM public.clinic_memberships cm2 WHERE cm2.clinic_id = c.id AND cm2.is_owner = true AND cm2.is_active = true ORDER BY cm2.created_at ASC LIMIT 1) cm_owner ON true LEFT JOIN auth.users au ON au.id = cm_owner.user_id LEFT JOIN public.clinic_memberships cm ON cm.clinic_id = c.id WHERE public.is_admin_at_least('STAFF') GROUP BY c.id, c.name, c.slug, c.is_active, c.created_at, cm_owner.full_name, cm_owner.email, au.raw_user_meta_data, au.email ORDER BY c.created_at DESC; $$;

-- approve_clinic_extension_request
CREATE OR REPLACE FUNCTION "public"."approve_clinic_extension_request"("p_request_id" "uuid", "p_added_days" integer) RETURNS TABLE("request_id" "uuid", "clinic_id" "uuid", "approved_at" timestamp with time zone, "new_expired_date" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER SET "search_path" TO 'public', 'pg_catalog'
    AS $$ DECLARE v_request public.clinic_extension_requests%ROWTYPE; v_current_expired_date timestamptz; v_approved_at timestamptz := timezone('utc', now()); v_new_expired_date timestamptz; BEGIN IF NOT public.is_admin_at_least('ADMIN') THEN RAISE EXCEPTION 'Hanya admin yang dapat menyetujui pengajuan perpanjangan.'; END IF; IF coalesce(p_added_days, 0) <= 0 THEN RAISE EXCEPTION 'Durasi perpanjangan harus lebih dari 0 hari.'; END IF; SELECT * INTO v_request FROM public.clinic_extension_requests cer WHERE cer.id = p_request_id FOR UPDATE; IF v_request.id IS NULL THEN RAISE EXCEPTION 'Pengajuan perpanjangan tidak ditemukan.'; END IF; IF v_request.status <> 'PENDING' THEN RAISE EXCEPTION 'Hanya pengajuan berstatus PENDING yang dapat disetujui.'; END IF; SELECT c.expired_date INTO v_current_expired_date FROM public.clinics c WHERE c.id = v_request.clinic_id FOR UPDATE; v_new_expired_date := (CASE WHEN v_current_expired_date IS NULL OR v_current_expired_date < v_approved_at THEN v_approved_at ELSE v_current_expired_date END) + make_interval(days => p_added_days); UPDATE public.clinic_extension_requests SET status = 'APPROVED', approved_at = v_approved_at, approved_by = auth.uid(), added_days = p_added_days WHERE id = v_request.id; UPDATE public.clinics SET expired_date = v_new_expired_date, updated_at = timezone('utc', now()) WHERE id = v_request.clinic_id; RETURN QUERY SELECT v_request.id, v_request.clinic_id, v_approved_at, v_new_expired_date; END; $$;

-- create_clinic_with_owner (variant 1: no full_address)
CREATE OR REPLACE FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text" DEFAULT NULL::"text", "owner_user_id" "uuid" DEFAULT "auth"."uid"(), "permit_number" "text" DEFAULT NULL::"text", "owner_ktp_number" "text" DEFAULT NULL::"text", "phone_number" "text" DEFAULT NULL::"text", "address_line" "text" DEFAULT NULL::"text", "rt_rw" "text" DEFAULT NULL::"text", "province_name" "text" DEFAULT NULL::"text", "city_name" "text" DEFAULT NULL::"text", "district_name" "text" DEFAULT NULL::"text", "subdistrict_name" "text" DEFAULT NULL::"text", "postal_code" "text" DEFAULT NULL::"text", "expired_date" timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER SET "search_path" TO 'public'
    AS $$ declare normalized_name text; base_slug text; final_slug text; suffix int := 0; created_clinic_id uuid; existing_clinic_id uuid; owner_membership_id uuid; begin if owner_user_id is null then return jsonb_build_object('status', 'error', 'code', 'AUTH_REQUIRED', 'message', 'Akun login tidak ditemukan.'); end if; normalized_name := nullif(btrim(clinic_name), ''); if normalized_name is null then return jsonb_build_object('status', 'error', 'code', 'INVALID_CLINIC_NAME', 'message', 'Nama klinik wajib diisi.'); end if; base_slug := nullif(regexp_replace(lower(coalesce(clinic_slug, normalized_name)), '[^a-z0-9]+', '-', 'g'), ''); base_slug := trim(both '-' from coalesce(base_slug, 'clinic')); if base_slug = '' then base_slug := 'clinic'; end if; final_slug := base_slug; while exists (select 1 from public.clinics c where c.slug = final_slug) loop suffix := suffix + 1; final_slug := base_slug || '-' || suffix::text; end loop; insert into public.users (id, role) values (owner_user_id, 'clinic_staff'::public.user_role) on conflict (id) do update set role = 'clinic_staff'::public.user_role, updated_at = now(); select cm.clinic_id, cm.id into existing_clinic_id, owner_membership_id from public.clinic_memberships cm where cm.user_id = owner_user_id and cm.is_owner = true and cm.is_active = true order by cm.created_at asc limit 1; if existing_clinic_id is not null then update public.clinics c set permit_number = coalesce(nullif(btrim(create_clinic_with_owner.permit_number), ''), c.permit_number), owner_ktp_number = coalesce(nullif(btrim(create_clinic_with_owner.owner_ktp_number), ''), c.owner_ktp_number), phone_number = coalesce(nullif(btrim(create_clinic_with_owner.phone_number), ''), c.phone_number), address_line = coalesce(nullif(btrim(create_clinic_with_owner.address_line), ''), c.address_line), rt_rw = coalesce(nullif(btrim(create_clinic_with_owner.rt_rw), ''), c.rt_rw), province_name = coalesce(nullif(btrim(create_clinic_with_owner.province_name), ''), c.province_name), city_name = coalesce(nullif(btrim(create_clinic_with_owner.city_name), ''), c.city_name), district_name = coalesce(nullif(btrim(create_clinic_with_owner.district_name), ''), c.district_name), subdistrict_name = coalesce(nullif(btrim(create_clinic_with_owner.subdistrict_name), ''), c.subdistrict_name), postal_code = coalesce(nullif(btrim(create_clinic_with_owner.postal_code), ''), c.postal_code), expired_date = coalesce(create_clinic_with_owner.expired_date, c.expired_date), updated_at = now() where c.id = existing_clinic_id; return jsonb_build_object('status', 'success', 'message', 'Owner sudah memiliki klinik aktif.', 'clinicId', existing_clinic_id, 'membershipId', owner_membership_id); end if; insert into public.clinics (name, slug, owner_user_id, expired_date, permit_number, owner_ktp_number, phone_number, address_line, rt_rw, province_name, city_name, district_name, subdistrict_name, postal_code) values (normalized_name, final_slug, owner_user_id, create_clinic_with_owner.expired_date, nullif(btrim(create_clinic_with_owner.permit_number), ''), nullif(btrim(create_clinic_with_owner.owner_ktp_number), ''), nullif(btrim(create_clinic_with_owner.phone_number), ''), nullif(btrim(create_clinic_with_owner.address_line), ''), nullif(btrim(create_clinic_with_owner.rt_rw), ''), nullif(btrim(create_clinic_with_owner.province_name), ''), nullif(btrim(create_clinic_with_owner.city_name), ''), nullif(btrim(create_clinic_with_owner.district_name), ''), nullif(btrim(create_clinic_with_owner.subdistrict_name), ''), nullif(btrim(create_clinic_with_owner.postal_code), '')) returning id into created_clinic_id; insert into public.clinic_memberships (clinic_id, user_id, is_owner, is_staff, is_practitioner, profession, is_active) values (created_clinic_id, owner_user_id, true, true, true, 'psychologist'::public.practitioner_profession, true) returning id into owner_membership_id; return jsonb_build_object('status', 'success', 'message', 'Klinik berhasil dibuat.', 'clinicId', created_clinic_id, 'membershipId', owner_membership_id); exception when others then return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal membuat klinik: ' || sqlerrm); end; $$;

-- create_clinic_with_owner (variant 2: with full_address)
CREATE OR REPLACE FUNCTION "public"."create_clinic_with_owner"("clinic_name" "text", "clinic_slug" "text" DEFAULT NULL::"text", "owner_user_id" "uuid" DEFAULT "auth"."uid"(), "permit_number" "text" DEFAULT NULL::"text", "owner_ktp_number" "text" DEFAULT NULL::"text", "phone_number" "text" DEFAULT NULL::"text", "address_line" "text" DEFAULT NULL::"text", "rt_rw" "text" DEFAULT NULL::"text", "province_name" "text" DEFAULT NULL::"text", "city_name" "text" DEFAULT NULL::"text", "district_name" "text" DEFAULT NULL::"text", "subdistrict_name" "text" DEFAULT NULL::"text", "postal_code" "text" DEFAULT NULL::"text", "full_address" "text" DEFAULT NULL::"text", "expired_date" timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER SET "search_path" TO 'public'
    AS $$ declare normalized_name text; base_slug text; final_slug text; suffix int := 0; created_clinic_id uuid; existing_clinic_id uuid; owner_membership_id uuid; begin if owner_user_id is null then return jsonb_build_object('status', 'error', 'code', 'AUTH_REQUIRED', 'message', 'Akun login tidak ditemukan.'); end if; normalized_name := nullif(btrim(clinic_name), ''); if normalized_name is null then return jsonb_build_object('status', 'error', 'code', 'INVALID_CLINIC_NAME', 'message', 'Nama klinik wajib diisi.'); end if; base_slug := nullif(regexp_replace(lower(coalesce(clinic_slug, normalized_name)), '[^a-z0-9]+', '-', 'g'), ''); base_slug := trim(both '-' from coalesce(base_slug, 'clinic')); if base_slug = '' then base_slug := 'clinic'; end if; final_slug := base_slug; while exists (select 1 from public.clinics c where c.slug = final_slug) loop suffix := suffix + 1; final_slug := base_slug || '-' || suffix::text; end loop; insert into public.users (id, role) values (owner_user_id, 'clinic_staff'::public.user_role) on conflict (id) do update set role = 'clinic_staff'::public.user_role, updated_at = now(); select cm.clinic_id, cm.id into existing_clinic_id, owner_membership_id from public.clinic_memberships cm where cm.user_id = owner_user_id and cm.is_owner = true and cm.is_active = true order by cm.created_at asc limit 1; if existing_clinic_id is not null then update public.clinics c set permit_number = coalesce(nullif(btrim(create_clinic_with_owner.permit_number), ''), c.permit_number), owner_ktp_number = coalesce(nullif(btrim(create_clinic_with_owner.owner_ktp_number), ''), c.owner_ktp_number), phone_number = coalesce(nullif(btrim(create_clinic_with_owner.phone_number), ''), c.phone_number), address_line = coalesce(nullif(btrim(create_clinic_with_owner.address_line), ''), c.address_line), rt_rw = coalesce(nullif(btrim(create_clinic_with_owner.rt_rw), ''), c.rt_rw), province_name = coalesce(nullif(btrim(create_clinic_with_owner.province_name), ''), c.province_name), city_name = coalesce(nullif(btrim(create_clinic_with_owner.city_name), ''), c.city_name), district_name = coalesce(nullif(btrim(create_clinic_with_owner.district_name), ''), c.district_name), subdistrict_name = coalesce(nullif(btrim(create_clinic_with_owner.subdistrict_name), ''), c.subdistrict_name), postal_code = coalesce(nullif(btrim(create_clinic_with_owner.postal_code), ''), c.postal_code), full_address = coalesce(nullif(btrim(create_clinic_with_owner.full_address), ''), c.full_address), expired_date = coalesce(create_clinic_with_owner.expired_date, c.expired_date), updated_at = now() where c.id = existing_clinic_id; return jsonb_build_object('status', 'success', 'message', 'Owner sudah memiliki klinik aktif.', 'clinicId', existing_clinic_id, 'membershipId', owner_membership_id); end if; insert into public.clinics (name, slug, owner_user_id, expired_date, permit_number, owner_ktp_number, phone_number, address_line, rt_rw, province_name, city_name, district_name, subdistrict_name, postal_code, full_address) values (normalized_name, final_slug, owner_user_id, create_clinic_with_owner.expired_date, nullif(btrim(create_clinic_with_owner.permit_number), ''), nullif(btrim(create_clinic_with_owner.owner_ktp_number), ''), nullif(btrim(create_clinic_with_owner.phone_number), ''), nullif(btrim(create_clinic_with_owner.address_line), ''), nullif(btrim(create_clinic_with_owner.rt_rw), ''), nullif(btrim(create_clinic_with_owner.province_name), ''), nullif(btrim(create_clinic_with_owner.city_name), ''), nullif(btrim(create_clinic_with_owner.district_name), ''), nullif(btrim(create_clinic_with_owner.subdistrict_name), ''), nullif(btrim(create_clinic_with_owner.postal_code), ''), nullif(btrim(create_clinic_with_owner.full_address), '')) returning id into created_clinic_id; insert into public.clinic_memberships (clinic_id, user_id, is_owner, is_staff, is_practitioner, profession, is_active) values (created_clinic_id, owner_user_id, true, true, true, 'psychologist'::public.practitioner_profession, true) returning id into owner_membership_id; return jsonb_build_object('status', 'success', 'message', 'Klinik berhasil dibuat.', 'clinicId', created_clinic_id, 'membershipId', owner_membership_id); exception when others then return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal membuat klinik: ' || sqlerrm); end; $$;

-- get_clinics_with_pending_extension
CREATE OR REPLACE FUNCTION "public"."get_clinics_with_pending_extension"() RETURNS TABLE("id" "uuid", "name" "text", "slug" character varying, "is_active" boolean, "owner_user_id" "uuid", "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "expired_date" timestamp with time zone, "is_agreement_signed" boolean, "permit_number" "text", "owner_ktp_number" "text", "phone_number" "text", "address_line" "text", "rt_rw" "text", "province_name" "text", "city_name" "text", "district_name" "text", "subdistrict_name" "text", "postal_code" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER SET "search_path" TO 'public', 'pg_catalog'
    AS $$ SELECT DISTINCT c.id, c.name, c.slug, c.is_active, c.owner_user_id, c.created_at, c.updated_at, c.expired_date, c.is_agreement_signed, c.permit_number, c.owner_ktp_number, c.phone_number, c.address_line, c.rt_rw, c.province_name, c.city_name, c.district_name, c.subdistrict_name, c.postal_code FROM public.clinics c INNER JOIN public.clinic_extension_requests cer ON cer.clinic_id = c.id AND cer.status = 'PENDING' ORDER BY c.created_at DESC; $$;

-- is_registered_profile_email
CREATE OR REPLACE FUNCTION "public"."is_registered_profile_email"("p_email" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SET "search_path" TO 'public'
    AS $$ select exists (select 1 from public.users u left join public.clinic_memberships cm on cm.user_id = u.id where lower(trim(coalesce(cm.email, ''))) = lower(trim(p_email)) and u.role = 'clinic_staff' limit 1); $$;

-- reject_clinic_extension_request
CREATE OR REPLACE FUNCTION "public"."reject_clinic_extension_request"("p_request_id" "uuid") RETURNS TABLE("request_id" "uuid", "clinic_id" "uuid", "rejected_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER SET "search_path" TO 'public', 'pg_catalog'
    AS $$ DECLARE v_request public.clinic_extension_requests%ROWTYPE; v_rejected_at timestamptz := timezone('utc', now()); BEGIN IF NOT public.is_admin_at_least('ADMIN') THEN RAISE EXCEPTION 'Hanya admin yang dapat menolak pengajuan perpanjangan.'; END IF; SELECT * INTO v_request FROM public.clinic_extension_requests cer WHERE cer.id = p_request_id FOR UPDATE; IF v_request.id IS NULL THEN RAISE EXCEPTION 'Pengajuan perpanjangan tidak ditemukan.'; END IF; IF v_request.status <> 'PENDING' THEN RAISE EXCEPTION 'Hanya pengajuan berstatus PENDING yang dapat ditolak.'; END IF; UPDATE public.clinic_extension_requests SET status = 'REJECTED', approved_at = NULL, approved_by = NULL, added_days = NULL WHERE id = v_request.id; RETURN QUERY SELECT v_request.id, v_request.clinic_id, v_rejected_at; END; $$;
