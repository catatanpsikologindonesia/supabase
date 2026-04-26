--
-- PostgreSQL database dump
--

\restrict F5vV2pbCdQnKrARPKQyWc9Y7qlLvmBJozUpDB1IlGRCmmKtPrFcFWJMYybwdQbL

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extensions;


--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql;


--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql_public;


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgbouncer;


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: supabase_migrations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA supabase_migrations;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: adhd_indication; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.adhd_indication AS ENUM (
    'possible_adhd',
    'not_adhd'
);


--
-- Name: appointment_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.appointment_status AS ENUM (
    'scheduled',
    'completed',
    'cancelled'
);


--
-- Name: autism_indication; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.autism_indication AS ENUM (
    'high_risk',
    'low_risk',
    'other_disorder',
    'borderline_normal'
);


--
-- Name: birth_process; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.birth_process AS ENUM (
    'normal',
    'sc',
    'assisted'
);


--
-- Name: consent_source; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.consent_source AS ENUM (
    'registration_wizard',
    'invite_consent_page',
    'backfill'
);


--
-- Name: patient_invitation_flow; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.patient_invitation_flow AS ENUM (
    'registration_required',
    'consent_required',
    'info_only'
);


--
-- Name: patient_invitation_used_reason; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.patient_invitation_used_reason AS ENUM (
    'registration_completed',
    'consent_accepted',
    'info_only_notified',
    'superseded',
    'expired',
    'cancelled'
);


--
-- Name: practitioner_profession; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.practitioner_profession AS ENUM (
    'psychologist',
    'counselor',
    'other'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'psychologist',
    'patient',
    'clinic_staff'
);


--
-- Name: visit_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.visit_status AS ENUM (
    'scheduled',
    'in_progress',
    'completed',
    'cancelled'
);


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: -
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$_$;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
  BEGIN
      RAISE DEBUG 'PgBouncer auth request: %', p_usename;

      RETURN QUERY
      SELECT
          rolname::text,
          CASE WHEN rolvaliduntil < now()
              THEN null
              ELSE rolpassword::text
          END
      FROM pg_authid
      WHERE rolname=$1 and rolcanlogin;
  END;
  $_$;


--
-- Name: accept_patient_consent_by_token(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accept_patient_consent_by_token(invite_token text, consent_ip text DEFAULT NULL::text, consent_user_agent text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  invitation_row public.patient_invitations%rowtype;
  clinic_patient_id_value uuid;
  practitioner_membership_id_value uuid;
  appointment_id_value uuid;
  visit_id_value uuid;
  session_start_at_value timestamptz;
  session_end_at_value timestamptz;
  consent_text_value text := 'Saya menyetujui berbagi data medis saya dengan klinik tujuan untuk keperluan layanan psikologi.';
begin
  if invite_token is null or btrim(invite_token) = '' then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_TOKEN', 'message', 'Token undangan tidak valid.');
  end if;

  select *
  into invitation_row
  from public.patient_invitations pi
  where pi.token = invite_token
  limit 1
  for update;

  if not found then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_NOT_FOUND', 'message', 'Undangan tidak ditemukan.');
  end if;

  if invitation_row.flow <> 'consent_required'::public.patient_invitation_flow then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_FLOW', 'message', 'Undangan ini tidak menggunakan flow persetujuan data.');
  end if;

  if coalesce(invitation_row.is_used, false) then
    if invitation_row.used_reason = 'superseded'::public.patient_invitation_used_reason then
      return jsonb_build_object('status', 'error', 'code', 'INVITATION_SUPERSEDED', 'message', 'Link undangan ini sudah diganti dengan undangan terbaru.');
    end if;

    return jsonb_build_object('status', 'error', 'code', 'INVITATION_USED', 'message', 'Link undangan sudah digunakan.');
  end if;

  if invitation_row.expires_at < now() then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_EXPIRED', 'message', 'Link undangan sudah kedaluwarsa.');
  end if;

  if invitation_row.target_patient_id is null then
    return jsonb_build_object('status', 'error', 'code', 'PATIENT_NOT_FOUND', 'message', 'Data pasien untuk undangan ini belum tersedia.');
  end if;

  if invitation_row.clinic_id is null then
    return jsonb_build_object('status', 'error', 'code', 'INVITATION_CLINIC_REQUIRED', 'message', 'Undangan belum terhubung ke klinik.');
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

  if not exists (
    select 1
    from public.patient_clinic_consents pcc
    where pcc.clinic_id = invitation_row.clinic_id
      and pcc.patient_id = invitation_row.target_patient_id
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
      invitation_row.target_patient_id,
      invitation_row.id,
      'v1',
      consent_text_value,
      'invite_consent_page'::public.consent_source,
      now(),
      nullif(consent_ip, ''),
      nullif(consent_user_agent, ''),
      now(),
      now()
    );
  end if;

  insert into public.clinic_patients (clinic_id, patient_id, mrn, is_active)
  values (
    invitation_row.clinic_id,
    invitation_row.target_patient_id,
    coalesce(
      (select p.mrn from public.patients p where p.id = invitation_row.target_patient_id),
      'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6))
    ),
    true
  )
  on conflict (clinic_id, patient_id) do update
  set is_active = true,
      updated_at = now()
  returning id into clinic_patient_id_value;

  appointment_id_value := invitation_row.appointment_id;

  if appointment_id_value is null then
    session_start_at_value := coalesce(
      invitation_row.session_start_at,
      date_trunc('day', now()) + interval '1 day' + interval '9 hours'
    );
    session_end_at_value := coalesce(
      invitation_row.session_end_at,
      session_start_at_value + interval '45 minutes'
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
      invitation_row.target_patient_id,
      practitioner_membership_id_value,
      session_start_at_value,
      session_end_at_value,
      'scheduled',
      'Auto-created after consent acceptance'
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
      invitation_row.target_patient_id,
      appointment_id_value,
      'scheduled'
    )
    returning id into visit_id_value;
  end if;

  update public.patient_invitations
  set is_used = true,
      used_at = now(),
      used_reason = 'consent_accepted'::public.patient_invitation_used_reason,
      appointment_id = appointment_id_value,
      practitioner_membership_id = practitioner_membership_id_value
  where id = invitation_row.id;

  return jsonb_build_object(
    'status', 'success',
    'message', 'Persetujuan data berhasil. Jadwal sesi sudah dikonfirmasi.',
    'patientId', invitation_row.target_patient_id,
    'clinicId', invitation_row.clinic_id,
    'appointmentId', appointment_id_value,
    'visitId', visit_id_value
  );
exception
  when others then
    return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal memproses persetujuan: ' || sqlerrm);
end;
$$;


--
-- Name: add_clinic_member_by_email(uuid, text, boolean, boolean, public.practitioner_profession, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_clinic_member_by_email(target_clinic_id uuid, member_email text, assign_staff boolean DEFAULT true, assign_practitioner boolean DEFAULT false, member_profession public.practitioner_profession DEFAULT NULL::public.practitioner_profession, actor_user_id uuid DEFAULT auth.uid()) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: create_clinic_with_owner(text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_clinic_with_owner(clinic_name text, clinic_slug text DEFAULT NULL::text, owner_user_id uuid DEFAULT auth.uid()) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
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


--
-- Name: create_patient_from_auth_user(text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_patient_from_auth_user(auth_email text, auth_user_id uuid, invite_token text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  invitation_row public.patient_invitations%rowtype;
  auth_user_email text;
  patient_id_value uuid;
  mrn_value text;
  full_name_value text;
begin
  if invite_token is null or btrim(invite_token) = '' then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_TOKEN', 'message', 'Token registrasi tidak valid.');
  end if;

  if auth_user_id is null then
    return jsonb_build_object('status', 'error', 'code', 'AUTH_USER_REQUIRED', 'message', 'Akun login pasien tidak ditemukan.');
  end if;

  if auth_email is null or btrim(auth_email) = '' then
    return jsonb_build_object('status', 'error', 'code', 'AUTH_EMAIL_REQUIRED', 'message', 'Email akun login pasien tidak ditemukan.');
  end if;

  select *
  into invitation_row
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

  select au.email
  into auth_user_email
  from auth.users au
  where au.id = auth_user_id
  limit 1;

  if auth_user_email is null then
    return jsonb_build_object('status', 'error', 'code', 'AUTH_USER_NOT_FOUND', 'message', 'User auth pasien tidak ditemukan.');
  end if;

  if lower(btrim(auth_email)) <> lower(btrim(auth_user_email))
     or lower(btrim(auth_email)) <> lower(btrim(invitation_row.email)) then
    return jsonb_build_object('status', 'error', 'code', 'EMAIL_MISMATCH', 'message', 'Email akun tidak cocok dengan email undangan.');
  end if;

  insert into public.users (id, role)
  values (auth_user_id, 'patient'::public.user_role)
  on conflict (id) do update
    set role = case
      when public.users.role::text = 'clinic_staff' then public.users.role
      else 'patient'::public.user_role
    end,
    updated_at = now();

  select p.id
  into patient_id_value
  from public.patients p
  where p.user_id = auth_user_id
  limit 1;

  if patient_id_value is null then
    mrn_value := 'MRN-' || to_char(now(), 'YYYYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
    full_name_value := coalesce(
      nullif(initcap(regexp_replace(split_part(invitation_row.email, '@', 1), '[._-]+', ' ', 'g')), ''),
      'Pasien Baru'
    );

    insert into public.patients (user_id, mrn, full_name, email, phone)
    values (auth_user_id, mrn_value, full_name_value, invitation_row.email, null)
    returning id into patient_id_value;
  end if;

  update public.patient_invitations
  set target_patient_id = coalesce(target_patient_id, patient_id_value)
  where id = invitation_row.id;

  return jsonb_build_object(
    'status', 'success',
    'message', 'Data pasien awal berhasil dibuat.',
    'patientId', patient_id_value,
    'clinicId', invitation_row.clinic_id
  );
exception
  when others then
    return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal menyiapkan data pasien: ' || sqlerrm);
end;
$$;


--
-- Name: create_patient_invitation_with_schedule(uuid, uuid, text, date, time without time zone, integer, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_patient_invitation_with_schedule(target_clinic_id uuid, invited_by_membership_id uuid, patient_email text, session_date date, session_time time without time zone, duration_minutes integer DEFAULT 45, session_timezone text DEFAULT 'Asia/Jakarta'::text, invitation_ttl_hours integer DEFAULT 72) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  normalized_email text;
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
  clinic_patient_id_value uuid;
  appointment_id_value uuid;
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
    select 1
    from public.clinic_memberships cm
    where cm.id = invited_by_membership_id
      and cm.clinic_id = target_clinic_id
      and cm.user_id = auth.uid()
      and cm.is_active = true
  ) then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_MEMBERSHIP', 'message', 'Membership pengundang tidak ditemukan pada klinik aktif.');
  end if;

  select c.name
  into clinic_name_value
  from public.clinics c
  where c.id = target_clinic_id
    and c.is_active = true
  limit 1;

  if clinic_name_value is null then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_CLINIC', 'message', 'Klinik tidak aktif atau tidak ditemukan.');
  end if;

  normalized_email := lower(btrim(patient_email));
  if normalized_email is null or normalized_email = '' then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_EMAIL', 'message', 'Email pasien wajib diisi.');
  end if;

  if session_date is null or session_time is null then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_SCHEDULE', 'message', 'Tanggal dan waktu sesi wajib diisi.');
  end if;

  if duration_minutes is null or duration_minutes < 15 or duration_minutes > 180 then
    return jsonb_build_object('status', 'error', 'code', 'INVALID_DURATION', 'message', 'Durasi sesi harus di antara 15 dan 180 menit.');
  end if;

  session_timezone_value := coalesce(nullif(btrim(session_timezone), ''), 'Asia/Jakarta');
  expires_at_value := now() + make_interval(hours => greatest(invitation_ttl_hours, 1));
  token_value := md5(random()::text || clock_timestamp()::text || normalized_email || coalesce(auth.uid()::text, ''))
    || md5(random()::text || clock_timestamp()::text || txid_current()::text);
  session_start_at_value := ((session_date::timestamp + session_time) at time zone session_timezone_value);
  session_end_at_value := session_start_at_value + make_interval(mins => duration_minutes);

  select cm.id
  into practitioner_membership_id_value
  from public.clinic_memberships cm
  where cm.clinic_id = target_clinic_id
    and cm.is_active = true
    and cm.is_practitioner = true
  order by cm.is_owner desc, cm.created_at asc
  limit 1;

  if practitioner_membership_id_value is null then
    return jsonb_build_object('status', 'error', 'code', 'NO_PRACTITIONER', 'message', 'Tidak ada practitioner aktif pada klinik ini.');
  end if;

  select au.id, p.id
  into auth_user_id_value, patient_id_value
  from auth.users au
  left join public.patients p
    on p.user_id = au.id
  where lower(au.email) = normalized_email
  order by p.created_at asc nulls last
  limit 1;

  if auth_user_id_value is null or patient_id_value is null then
    resolved_flow := 'registration_required'::public.patient_invitation_flow;
    patient_id_value := null;
  else
    select exists (
      select 1
      from public.patient_clinic_consents pcc
      where pcc.clinic_id = target_clinic_id
        and pcc.patient_id = patient_id_value
        and pcc.revoked_at is null
    )
    into has_active_consent;

    if has_active_consent then
      resolved_flow := 'info_only'::public.patient_invitation_flow;
    else
      resolved_flow := 'consent_required'::public.patient_invitation_flow;
    end if;
  end if;

  insert into public.patient_invitations (
    clinic_id,
    invited_by_membership_id,
    email,
    token,
    expires_at,
    is_used,
    flow,
    session_start_at,
    session_end_at,
    session_timezone,
    target_patient_id,
    practitioner_membership_id,
    used_reason,
    appointment_id
  )
  values (
    target_clinic_id,
    invited_by_membership_id,
    normalized_email,
    token_value,
    expires_at_value,
    false,
    resolved_flow,
    session_start_at_value,
    session_end_at_value,
    session_timezone_value,
    patient_id_value,
    practitioner_membership_id_value,
    null,
    null
  )
  returning id into invitation_id_value;

  update public.patient_invitations pi
  set is_used = true,
      used_at = now(),
      used_reason = 'superseded'::public.patient_invitation_used_reason,
      replaced_by_invitation_id = invitation_id_value
  where pi.id <> invitation_id_value
    and pi.clinic_id = target_clinic_id
    and lower(pi.email) = normalized_email
    and pi.is_used = false
    and pi.expires_at > now();

  if resolved_flow = 'info_only'::public.patient_invitation_flow then
    if patient_id_value is null then
      return jsonb_build_object('status', 'error', 'code', 'PATIENT_NOT_FOUND', 'message', 'Pasien global tidak ditemukan untuk flow info-only.');
    end if;

    insert into public.clinic_patients (clinic_id, patient_id, mrn, is_active)
    values (
      target_clinic_id,
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
      target_clinic_id,
      clinic_patient_id_value,
      patient_id_value,
      practitioner_membership_id_value,
      session_start_at_value,
      session_end_at_value,
      'scheduled',
      'Auto-created from info-only invitation'
    )
    returning id into appointment_id_value;

    insert into public.patient_visits (
      clinic_id,
      clinic_patient_id,
      patient_id,
      appointment_id,
      status
    )
    values (
      target_clinic_id,
      clinic_patient_id_value,
      patient_id_value,
      appointment_id_value,
      'scheduled'
    )
    on conflict (appointment_id) do nothing;

    update public.patient_invitations
    set is_used = true,
        used_at = now(),
        used_reason = 'info_only_notified'::public.patient_invitation_used_reason,
        appointment_id = appointment_id_value
    where id = invitation_id_value;
  end if;

  return jsonb_build_object(
    'status', 'success',
    'message', 'Undangan pasien berhasil dibuat.',
    'flow', resolved_flow::text,
    'token', token_value,
    'email', normalized_email,
    'clinicName', clinic_name_value,
    'expiresAt', expires_at_value,
    'sessionStartAt', session_start_at_value,
    'sessionEndAt', session_end_at_value,
    'sessionTimezone', session_timezone_value,
    'targetPatientId', patient_id_value,
    'invitationId', invitation_id_value,
    'appointmentId', appointment_id_value
  );
exception
  when unique_violation then
    return jsonb_build_object('status', 'error', 'code', 'TOKEN_COLLISION', 'message', 'Gagal membuat token undangan unik. Silakan coba lagi.');
  when others then
    return jsonb_build_object('status', 'error', 'code', 'SERVER_ERROR', 'message', 'Gagal membuat undangan: ' || sqlerrm);
end;
$$;


--
-- Name: get_invitation_by_token(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_invitation_by_token(invite_token text) RETURNS TABLE(email text, expires_at timestamp with time zone, is_used boolean, clinic_id uuid, clinic_name text, flow public.patient_invitation_flow, used_reason public.patient_invitation_used_reason, session_start_at timestamp with time zone, session_end_at timestamp with time zone, session_timezone text, target_patient_id uuid)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    pi.email,
    pi.expires_at,
    pi.is_used,
    pi.clinic_id,
    c.name as clinic_name,
    pi.flow,
    pi.used_reason,
    pi.session_start_at,
    pi.session_end_at,
    coalesce(pi.session_timezone, 'Asia/Jakarta') as session_timezone,
    pi.target_patient_id
  from public.patient_invitations pi
  left join public.clinics c on c.id = pi.clinic_id
  where pi.token = invite_token
  limit 1;
$$;


--
-- Name: handle_new_auth_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_auth_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: has_active_membership(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_active_membership(target_clinic_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from public.clinic_memberships cm
    where cm.user_id = auth.uid()
      and cm.clinic_id = target_clinic_id
      and cm.is_active = true
  );
$$;


--
-- Name: has_ops_access(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_ops_access(target_clinic_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: has_owner_access(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_owner_access(target_clinic_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: has_patient_access(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_patient_access(target_patient_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: has_practitioner_access(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_practitioner_access(target_clinic_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: is_portal_staff(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_portal_staff() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and u.role::text = 'clinic_staff'
  );
$$;


--
-- Name: rls_auto_enable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rls_auto_enable() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
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


--
-- Name: save_therapy_session_entry(uuid, uuid, uuid, date, time without time zone, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_therapy_session_entry(target_clinic_id uuid, target_patient_id uuid, target_visit_id uuid, input_session_date date, input_session_time time without time zone, input_activity_type text, input_subject text DEFAULT NULL::text, input_clinical_notes text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: submit_patient_registration(text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.submit_patient_registration(invite_token text, registration_payload jsonb) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
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

  select id
  into psychologist_id
  from public.users
  where role in ('admin', 'psychologist')
  order by created_at asc
  limit 1;

  if psychologist_id is null then
    return jsonb_build_object(
      'status', 'error',
      'code', 'NO_PSYCHOLOGIST',
      'message', 'Tidak ada user psikolog/admin aktif untuk membuat jadwal awal.'
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


--
-- Name: sync_clinic_membership_profile_defaults(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_clinic_membership_profile_defaults() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: update_patient_registration_by_user_id(text, jsonb, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_patient_registration_by_user_id(invite_token text, registration_payload jsonb, target_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
    referral_source
  )
  values (
    invitation_row.clinic_id,
    patient_id_value,
    registration_payload ->> 'fullName',
    nullif(registration_payload ->> 'sex', ''),
    nullif(registration_payload ->> 'birthDate', '')::date,
    nullif(registration_payload ->> 'address', ''),
    nullif(registration_payload ->> 'religion', ''),
    nullif(registration_payload ->> 'education', ''),
    nullif(registration_payload ->> 'occupation', ''),
    nullif(registration_payload ->> 'hobby', ''),
    'Self registration invitation'
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
    family_notes
  )
  values (
    invitation_row.clinic_id,
    patient_id_value,
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
$$;


--
-- Name: verify_referral_pin(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verify_referral_pin(referral_id uuid, input_pin text) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
-- Regclass of the table e.g. public.notes
entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

-- I, U, D, T: insert, update ...
action realtime.action = (
    case wal ->> 'action'
        when 'I' then 'INSERT'
        when 'U' then 'UPDATE'
        when 'D' then 'DELETE'
        else 'ERROR'
    end
);

-- Is row level security enabled for the table
is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

subscriptions realtime.subscription[] = array_agg(subs)
    from
        realtime.subscription subs
    where
        subs.entity = entity_
        -- Filter by action early - only get subscriptions interested in this action
        -- action_filter column can be: '*' (all), 'INSERT', 'UPDATE', or 'DELETE'
        and (subs.action_filter = '*' or subs.action_filter = action::text);

-- Subscription vars
roles regrole[] = array_agg(distinct us.claims_role::text)
    from
        unnest(subscriptions) us;

working_role regrole;
claimed_role regrole;
claims jsonb;

subscription_id uuid;
subscription_has_access bool;
visible_to_subscription_ids uuid[] = '{}';

-- structured info for wal's columns
columns realtime.wal_column[];
-- previous identity values for update/delete
old_columns realtime.wal_column[];

error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

-- Primary jsonb output for record
output jsonb;

begin
perform set_config('role', null, true);

columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'columns') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

old_columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'identity') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

for working_role in select * from unnest(roles) loop

    -- Update `is_selectable` for columns and old_columns
    columns =
        array_agg(
            (
                c.name,
                c.type_name,
                c.type_oid,
                c.value,
                c.is_pkey,
                pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
            )::realtime.wal_column
        )
        from
            unnest(columns) c;

    old_columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(old_columns) c;

    if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            -- subscriptions is already filtered by entity
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 400: Bad Request, no primary key']
        )::realtime.wal_rls;

    -- The claims role does not have SELECT permission to the primary key of entity
    elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 401: Unauthorized']
        )::realtime.wal_rls;

    else
        output = jsonb_build_object(
            'schema', wal ->> 'schema',
            'table', wal ->> 'table',
            'type', action,
            'commit_timestamp', to_char(
                ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
            ),
            'columns', (
                select
                    jsonb_agg(
                        jsonb_build_object(
                            'name', pa.attname,
                            'type', pt.typname
                        )
                        order by pa.attnum asc
                    )
                from
                    pg_attribute pa
                    join pg_type pt
                        on pa.atttypid = pt.oid
                where
                    attrelid = entity_
                    and attnum > 0
                    and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
            )
        )
        -- Add "record" key for insert and update
        || case
            when action in ('INSERT', 'UPDATE') then
                jsonb_build_object(
                    'record',
                    (
                        select
                            jsonb_object_agg(
                                -- if unchanged toast, get column name and value from old record
                                coalesce((c).name, (oc).name),
                                case
                                    when (c).name is null then (oc).value
                                    else (c).value
                                end
                            )
                        from
                            unnest(columns) c
                            full outer join unnest(old_columns) oc
                                on (c).name = (oc).name
                        where
                            coalesce((c).is_selectable, (oc).is_selectable)
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                    )
                )
            else '{}'::jsonb
        end
        -- Add "old_record" key for update and delete
        || case
            when action = 'UPDATE' then
                jsonb_build_object(
                        'old_record',
                        (
                            select jsonb_object_agg((c).name, (c).value)
                            from unnest(old_columns) c
                            where
                                (c).is_selectable
                                and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                        )
                    )
            when action = 'DELETE' then
                jsonb_build_object(
                    'old_record',
                    (
                        select jsonb_object_agg((c).name, (c).value)
                        from unnest(old_columns) c
                        where
                            (c).is_selectable
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                    )
                )
            else '{}'::jsonb
        end;

        -- Create the prepared statement
        if is_rls_enabled and action <> 'DELETE' then
            if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                deallocate walrus_rls_stmt;
            end if;
            execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
        end if;

        visible_to_subscription_ids = '{}';

        for subscription_id, claims in (
                select
                    subs.subscription_id,
                    subs.claims
                from
                    unnest(subscriptions) subs
                where
                    subs.entity = entity_
                    and subs.claims_role = working_role
                    and (
                        realtime.is_visible_through_filters(columns, subs.filters)
                        or (
                          action = 'DELETE'
                          and realtime.is_visible_through_filters(old_columns, subs.filters)
                        )
                    )
        ) loop

            if not is_rls_enabled or action = 'DELETE' then
                visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
            else
                -- Check if RLS allows the role to see the record
                perform
                    -- Trim leading and trailing quotes from working_role because set_config
                    -- doesn't recognize the role as valid if they are included
                    set_config('role', trim(both '"' from working_role::text), true),
                    set_config('request.jwt.claims', claims::text, true);

                execute 'execute walrus_rls_stmt' into subscription_has_access;

                if subscription_has_access then
                    visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
                end if;
            end if;
        end loop;

        perform set_config('role', null, true);

        return next (
            output,
            is_rls_enabled,
            visible_to_subscription_ids,
            case
                when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                else '{}'
            end
        )::realtime.wal_rls;

    end if;
end loop;

perform set_config('role', null, true);
end;
$$;


--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  res jsonb;
begin
  if type_::text = 'bytea' then
    return to_jsonb(val);
  end if;
  execute format('select to_jsonb(%L::'|| type_::text || ')', val) into res;
  return res;
end
$$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $$;


--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS TABLE(wal jsonb, is_rls_enabled boolean, subscription_ids uuid[], errors text[], slot_changes_count bigint)
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
  WITH pub AS (
    SELECT
      concat_ws(
        ',',
        CASE WHEN bool_or(pubinsert) THEN 'insert' ELSE NULL END,
        CASE WHEN bool_or(pubupdate) THEN 'update' ELSE NULL END,
        CASE WHEN bool_or(pubdelete) THEN 'delete' ELSE NULL END
      ) AS w2j_actions,
      coalesce(
        string_agg(
          realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
          ','
        ) filter (WHERE ppt.tablename IS NOT NULL AND ppt.tablename NOT LIKE '% %'),
        ''
      ) AS w2j_add_tables
    FROM pg_publication pp
    LEFT JOIN pg_publication_tables ppt ON pp.pubname = ppt.pubname
    WHERE pp.pubname = publication
    GROUP BY pp.pubname
    LIMIT 1
  ),
  -- MATERIALIZED ensures pg_logical_slot_get_changes is called exactly once
  w2j AS MATERIALIZED (
    SELECT x.*, pub.w2j_add_tables
    FROM pub,
         pg_logical_slot_get_changes(
           slot_name, null, max_changes,
           'include-pk', 'true',
           'include-transaction', 'false',
           'include-timestamp', 'true',
           'include-type-oids', 'true',
           'format-version', '2',
           'actions', pub.w2j_actions,
           'add-tables', pub.w2j_add_tables
         ) x
  ),
  -- Count raw slot entries before apply_rls/subscription filter
  slot_count AS (
    SELECT count(*)::bigint AS cnt
    FROM w2j
    WHERE w2j.w2j_add_tables <> ''
  ),
  -- Apply RLS and filter as before
  rls_filtered AS (
    SELECT xyz.wal, xyz.is_rls_enabled, xyz.subscription_ids, xyz.errors
    FROM w2j,
         realtime.apply_rls(
           wal := w2j.data::jsonb,
           max_record_bytes := max_record_bytes
         ) xyz(wal, is_rls_enabled, subscription_ids, errors)
    WHERE w2j.w2j_add_tables <> ''
      AND xyz.subscription_ids[1] IS NOT NULL
  )
  -- Real rows with slot count attached
  SELECT rf.wal, rf.is_rls_enabled, rf.subscription_ids, rf.errors, sc.cnt
  FROM rls_filtered rf, slot_count sc

  UNION ALL

  -- Sentinel row: always returned when no real rows exist so Elixir can
  -- always read slot_changes_count. Identified by wal IS NULL.
  SELECT null, null, null, null, sc.cnt
  FROM slot_count sc
  WHERE NOT EXISTS (SELECT 1 FROM rls_filtered)
$$;


--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
      select
        (
          select string_agg('' || ch,'')
          from unnest(string_to_array(nsp.nspname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
        )
        || '.'
        || (
          select string_agg('' || ch,'')
          from unnest(string_to_array(pc.relname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
          )
      from
        pg_class pc
        join pg_namespace nsp
          on pc.relnamespace = nsp.oid
      where
        pc.oid = entity
    $$;


--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
  final_payload jsonb;
BEGIN
  BEGIN
    -- Generate a new UUID for the id
    generated_id := gen_random_uuid();

    -- Check if payload has an 'id' key, if not, add the generated UUID
    IF payload ? 'id' THEN
      final_payload := payload;
    ELSE
      final_payload := jsonb_set(payload, '{id}', to_jsonb(generated_id));
    END IF;

    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (id, payload, event, topic, private, extension)
    VALUES (generated_id, final_payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    /*
    Validates that the user defined filters for a subscription:
    - refer to valid columns that the claimed role may access
    - values are coercable to the correct column type
    */
    declare
        col_names text[] = coalesce(
                array_agg(c.column_name order by c.ordinal_position),
                '{}'::text[]
            )
            from
                information_schema.columns c
            where
                format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
                and pg_catalog.has_column_privilege(
                    (new.claims ->> 'role'),
                    format('%I.%I', c.table_schema, c.table_name)::regclass,
                    c.column_name,
                    'SELECT'
                );
        filter realtime.user_defined_filter;
        col_type regtype;

        in_val jsonb;
    begin
        for filter in select * from unnest(new.filters) loop
            -- Filtered column is valid
            if not filter.column_name = any(col_names) then
                raise exception 'invalid column for filter %', filter.column_name;
            end if;

            -- Type is sanitized and safe for string interpolation
            col_type = (
                select atttypid::regtype
                from pg_catalog.pg_attribute
                where attrelid = new.entity
                      and attname = filter.column_name
            );
            if col_type is null then
                raise exception 'failed to lookup type for column %', filter.column_name;
            end if;

            -- Set maximum number of entries for in filter
            if filter.op = 'in'::realtime.equality_op then
                in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
                if coalesce(jsonb_array_length(in_val), 0) > 100 then
                    raise exception 'too many values for `in` filter. Maximum 100';
                end if;
            else
                -- raises an exception if value is not coercable to type
                perform realtime.cast(filter.value, col_type);
            end if;

        end loop;

        -- Apply consistent order to filters so the unique constraint on
        -- (subscription_id, entity, filters) can't be tricked by a different filter order
        new.filters = coalesce(
            array_agg(f order by f.column_name, f.op, f.value),
            '{}'
        ) from unnest(new.filters) f;

        return new;
    end;
    $$;


--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


--
-- Name: allow_any_operation(text[]); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.allow_any_operation(expected_operations text[]) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT CASE
      WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
      ELSE raw_operation
    END AS current_operation
    FROM current_operation
  )
  SELECT EXISTS (
    SELECT 1
    FROM normalized n
    CROSS JOIN LATERAL unnest(expected_operations) AS expected_operation
    WHERE expected_operation IS NOT NULL
      AND expected_operation <> ''
      AND n.current_operation = CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END
  );
$$;


--
-- Name: allow_only_operation(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.allow_only_operation(expected_operation text) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT
      CASE
        WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
        ELSE raw_operation
      END AS current_operation,
      CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END AS requested_operation
    FROM current_operation
  )
  SELECT CASE
    WHEN requested_operation IS NULL OR requested_operation = '' THEN FALSE
    ELSE COALESCE(current_operation = requested_operation, FALSE)
  END
  FROM normalized;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
_filename text;
BEGIN
	select string_to_array(name, '/') into _parts;
	select _parts[array_length(_parts,1)] into _filename;
	-- @todo return the last part instead of 2
	return reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[1:array_length(_parts,1)-1];
END
$$;


--
-- Name: get_common_prefix(text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_common_prefix(p_key text, p_prefix text, p_delimiter text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT CASE
    WHEN position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(p_key, length(p_prefix) + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)))
    ELSE NULL
END;
$$;


--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::int) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(_bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix, 1) = delimiter_param THEN
        v_upper_bound := left(v_prefix, -1) || chr(ascii(delimiter_param) + 1);
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'AND o.name COLLATE "C" < $3 ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'AND o.name COLLATE "C" >= $3 ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor: find the last item in range
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Cursor provided: determine if it refers to a folder or leaf
        IF EXISTS (
            SELECT 1 FROM storage.objects o
            WHERE o.bucket_id = _bucket_id
              AND o.name COLLATE "C" LIKE v_start || delimiter_param || '%'
            LIMIT 1
        ) THEN
            -- Cursor refers to a folder
            IF v_is_asc THEN
                v_next_seek := v_start || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_start || delimiter_param;
            END IF;
        ELSE
            -- Cursor refers to a leaf object
            IF v_is_asc THEN
                v_next_seek := v_start || delimiter_param;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := rtrim(v_common_prefix, delimiter_param);
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1) || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := v_current.name;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                RETURN NEXT;
                v_count := v_count + 1;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := v_current.name || delimiter_param;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: protect_delete(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.protect_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;
    v_skipped INT := 0;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach (unchanged)
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT path_tokens[$1] AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $2 || '%%'
                  AND bucket_id = $3
                  AND array_length(objects.path_tokens, 1) <> $1
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata FROM folders)
            UNION ALL
            (SELECT path_tokens[$1] AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata
             FROM storage.objects
             WHERE objects.name ILIKE $2 || '%%'
               AND bucket_id = $3
               AND array_length(objects.path_tokens, 1) = $1
             ORDER BY %I %s)
            LIMIT $4 OFFSET $5
            $sql$, v_sort_order, v_order_by, v_sort_order
        ) USING levels, v_prefix, bucketname, v_limit, offsets;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'AND lower(o.name) COLLATE "C" < $3 ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'AND lower(o.name) COLLATE "C" >= $3 ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC: find the last item in range first (static SQL)
        IF v_upper_bound IS NOT NULL THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower AND lower(o.name) COLLATE "C" < v_upper_bound
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSIF v_prefix_lower <> '' THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSE
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        END IF;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix_lower <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := split_part(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter), v_delimiter, levels);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := lower(v_current.name);
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := split_part(v_current.name, v_delimiter, levels);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := lower(v_current.name) || v_delimiter;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: search_by_timestamp(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_by_timestamp(p_prefix text, p_bucket_id text, p_limit integer, p_level integer, p_start_after text, p_sort_order text, p_sort_column text, p_sort_column_after text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
BEGIN
    v_prefix := coalesce(p_prefix, '');

    IF p_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $1 || '%%'
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                rtrim(common_prefix, '/') AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    date_trunc('milliseconds', %I),
                    name COLLATE "C"
                ) %s ROW(
                    COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz),
                    $5
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s
        LIMIT $4
    $sql$,
        p_sort_column,
        v_cursor_op,
        p_sort_column,
        p_sort_order,
        p_sort_order
    );

    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after;
END;
$_$;


--
-- Name: search_v2(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, sort_column text DEFAULT 'name'::text, sort_column_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            start_after,
            '',
            v_sort_ord
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after
        );
    END IF;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: custom_oauth_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.custom_oauth_providers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_type text NOT NULL,
    identifier text NOT NULL,
    name text NOT NULL,
    client_id text NOT NULL,
    client_secret text NOT NULL,
    acceptable_client_ids text[] DEFAULT '{}'::text[] NOT NULL,
    scopes text[] DEFAULT '{}'::text[] NOT NULL,
    pkce_enabled boolean DEFAULT true NOT NULL,
    attribute_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    authorization_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    email_optional boolean DEFAULT false NOT NULL,
    issuer text,
    discovery_url text,
    skip_nonce_check boolean DEFAULT false NOT NULL,
    cached_discovery jsonb,
    discovery_cached_at timestamp with time zone,
    authorization_url text,
    token_url text,
    userinfo_url text,
    jwks_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT custom_oauth_providers_authorization_url_https CHECK (((authorization_url IS NULL) OR (authorization_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_authorization_url_length CHECK (((authorization_url IS NULL) OR (char_length(authorization_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_client_id_length CHECK (((char_length(client_id) >= 1) AND (char_length(client_id) <= 512))),
    CONSTRAINT custom_oauth_providers_discovery_url_length CHECK (((discovery_url IS NULL) OR (char_length(discovery_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_identifier_format CHECK ((identifier ~ '^[a-z0-9][a-z0-9:-]{0,48}[a-z0-9]$'::text)),
    CONSTRAINT custom_oauth_providers_issuer_length CHECK (((issuer IS NULL) OR ((char_length(issuer) >= 1) AND (char_length(issuer) <= 2048)))),
    CONSTRAINT custom_oauth_providers_jwks_uri_https CHECK (((jwks_uri IS NULL) OR (jwks_uri ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_jwks_uri_length CHECK (((jwks_uri IS NULL) OR (char_length(jwks_uri) <= 2048))),
    CONSTRAINT custom_oauth_providers_name_length CHECK (((char_length(name) >= 1) AND (char_length(name) <= 100))),
    CONSTRAINT custom_oauth_providers_oauth2_requires_endpoints CHECK (((provider_type <> 'oauth2'::text) OR ((authorization_url IS NOT NULL) AND (token_url IS NOT NULL) AND (userinfo_url IS NOT NULL)))),
    CONSTRAINT custom_oauth_providers_oidc_discovery_url_https CHECK (((provider_type <> 'oidc'::text) OR (discovery_url IS NULL) OR (discovery_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_issuer_https CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NULL) OR (issuer ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_requires_issuer CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NOT NULL))),
    CONSTRAINT custom_oauth_providers_provider_type_check CHECK ((provider_type = ANY (ARRAY['oauth2'::text, 'oidc'::text]))),
    CONSTRAINT custom_oauth_providers_token_url_https CHECK (((token_url IS NULL) OR (token_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_token_url_length CHECK (((token_url IS NULL) OR (char_length(token_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_userinfo_url_https CHECK (((userinfo_url IS NULL) OR (userinfo_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_userinfo_url_length CHECK (((userinfo_url IS NULL) OR (char_length(userinfo_url) <= 2048)))
);


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text,
    code_challenge_method auth.code_challenge_method,
    code_challenge text,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone,
    invite_token text,
    referrer text,
    oauth_client_state_id uuid,
    linking_target_id uuid,
    email_optional boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'Stores metadata for all OAuth/SSO login flows';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid,
    last_webauthn_challenge_data jsonb
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: COLUMN mfa_factors.last_webauthn_challenge_data; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.mfa_factors.last_webauthn_challenge_data IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    nonce text,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_nonce_length CHECK ((char_length(nonce) <= 255)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


--
-- Name: oauth_client_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_client_states (
    id uuid NOT NULL,
    provider_type text NOT NULL,
    code_verifier text,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: TABLE oauth_client_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.oauth_client_states IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    token_endpoint_auth_method text NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048)),
    CONSTRAINT oauth_clients_token_endpoint_auth_method_check CHECK ((token_endpoint_auth_method = ANY (ARRAY['client_secret_basic'::text, 'client_secret_post'::text, 'none'::text])))
);


--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid,
    refresh_token_hmac_key text,
    refresh_token_counter bigint,
    scopes text,
    CONSTRAINT sessions_scopes_length CHECK ((char_length(scopes) <= 4096))
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: COLUMN sessions.refresh_token_hmac_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_hmac_key IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';


--
-- Name: COLUMN sessions.refresh_token_counter; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_counter IS 'Holds the ID (counter) of the last issued refresh token.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: webauthn_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.webauthn_challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    challenge_type text NOT NULL,
    session_data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    CONSTRAINT webauthn_challenges_challenge_type_check CHECK ((challenge_type = ANY (ARRAY['signup'::text, 'registration'::text, 'authentication'::text])))
);


--
-- Name: webauthn_credentials; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.webauthn_credentials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    credential_id bytea NOT NULL,
    public_key bytea NOT NULL,
    attestation_type text DEFAULT ''::text NOT NULL,
    aaguid uuid,
    sign_count bigint DEFAULT 0 NOT NULL,
    transports jsonb DEFAULT '[]'::jsonb NOT NULL,
    backup_eligible boolean DEFAULT false NOT NULL,
    backed_up boolean DEFAULT false NOT NULL,
    friendly_name text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone
);


--
-- Name: appointments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appointments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    patient_id uuid NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    status public.appointment_status DEFAULT 'scheduled'::public.appointment_status NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    clinic_id uuid NOT NULL,
    clinic_patient_id uuid NOT NULL,
    practitioner_membership_id uuid NOT NULL
);


--
-- Name: clinic_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clinic_memberships (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    clinic_id uuid NOT NULL,
    user_id uuid NOT NULL,
    is_owner boolean DEFAULT false NOT NULL,
    is_staff boolean DEFAULT false NOT NULL,
    is_practitioner boolean DEFAULT false NOT NULL,
    profession public.practitioner_profession,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    full_name text,
    email text,
    birth_date date,
    ktp_number character varying(32),
    gender character varying(20),
    address text,
    phone character varying(32),
    sip_number character varying(64)
);


--
-- Name: clinic_patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clinic_patients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    clinic_id uuid NOT NULL,
    patient_id uuid NOT NULL,
    mrn character varying(64) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: clinics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clinics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    slug character varying(120) NOT NULL,
    owner_user_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: cognitive_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cognitive_assessments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    visit_id uuid NOT NULL,
    knows_letters boolean,
    knows_colors boolean,
    writes boolean,
    counts boolean,
    reads boolean,
    reading_spelling boolean,
    fluent_reading boolean,
    reversed_letters boolean,
    autism_indication public.autism_indication,
    adhd_indication public.adhd_indication,
    initial_conclusion text,
    intervention_counseling_given boolean,
    intervention_areas text,
    other_medical_action text,
    referral_action text,
    assessment_result text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    clinic_id uuid NOT NULL
);


--
-- Name: developmental_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.developmental_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    visit_id uuid NOT NULL,
    mother_pregnancy_notes text,
    birth_process public.birth_process,
    gestational_age_weeks integer,
    birth_weight_kg numeric(5,2),
    birth_length_cm numeric(5,2),
    walking_age_months integer,
    speaking_age_months integer,
    hearing_function text,
    speech_articulation text,
    vision_function text,
    child_medical_history text,
    special_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    clinic_id uuid NOT NULL
);


--
-- Name: patient_clinic_consents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patient_clinic_consents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    clinic_id uuid NOT NULL,
    patient_id uuid NOT NULL,
    invitation_id uuid,
    consent_version character varying(20) DEFAULT 'v1'::character varying NOT NULL,
    consent_text text NOT NULL,
    source public.consent_source DEFAULT 'registration_wizard'::public.consent_source NOT NULL,
    accepted_at timestamp with time zone DEFAULT now() NOT NULL,
    accepted_ip text,
    accepted_user_agent text,
    revoked_at timestamp with time zone,
    revoked_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: patient_family_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patient_family_data (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    patient_id uuid NOT NULL,
    guardian_name text,
    guardian_relation character varying(50),
    guardian_phone character varying(32),
    guardian_address text,
    father_name text,
    father_age integer,
    father_education character varying(120),
    father_occupation character varying(120),
    mother_name text,
    mother_age integer,
    mother_education character varying(120),
    mother_occupation character varying(120),
    marital_status character varying(40),
    number_of_children integer,
    monthly_income numeric(12,2),
    family_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    clinic_id uuid NOT NULL
);


--
-- Name: patient_invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patient_invitations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email text NOT NULL,
    token character varying(128) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    is_used boolean DEFAULT false NOT NULL,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    clinic_id uuid NOT NULL,
    invited_by_membership_id uuid,
    flow public.patient_invitation_flow DEFAULT 'registration_required'::public.patient_invitation_flow NOT NULL,
    session_start_at timestamp with time zone,
    session_end_at timestamp with time zone,
    session_timezone text DEFAULT 'Asia/Jakarta'::text,
    target_patient_id uuid,
    practitioner_membership_id uuid,
    used_reason public.patient_invitation_used_reason,
    replaced_by_invitation_id uuid,
    appointment_id uuid,
    CONSTRAINT patient_invitations_session_range_chk CHECK (((session_start_at IS NULL) OR (session_end_at IS NULL) OR (session_end_at > session_start_at)))
);


--
-- Name: patient_personal_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patient_personal_data (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    patient_id uuid NOT NULL,
    case_number character varying(64),
    sex character varying(1),
    birth_date date,
    address text,
    religion character varying(80),
    education character varying(120),
    occupation character varying(120),
    hobby character varying(120),
    referral_source text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    full_name text,
    clinic_id uuid NOT NULL
);


--
-- Name: patient_visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patient_visits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    patient_id uuid NOT NULL,
    appointment_id uuid NOT NULL,
    status public.visit_status DEFAULT 'scheduled'::public.visit_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    clinic_id uuid NOT NULL,
    clinic_patient_id uuid NOT NULL
);


--
-- Name: patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    mrn character varying(64) NOT NULL,
    full_name text NOT NULL,
    email text,
    phone character varying(32),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: referrals_and_feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referrals_and_feedback (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    visit_id uuid NOT NULL,
    patient_id uuid NOT NULL,
    destination character varying(120) NOT NULL,
    notes text NOT NULL,
    secure_pin character varying(6) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    clinic_id uuid NOT NULL,
    practitioner_membership_id uuid,
    CONSTRAINT referrals_and_feedback_secure_pin_check CHECK (((secure_pin)::text ~ '^[0-9]{6}$'::text))
);


--
-- Name: therapy_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.therapy_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    visit_id uuid NOT NULL,
    session_date date NOT NULL,
    session_time time without time zone NOT NULL,
    activity_type character varying(120) NOT NULL,
    subject text,
    clinical_notes text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    clinic_id uuid NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    role public.user_role DEFAULT 'clinic_staff'::public.user_role NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_role_supported_chk CHECK (((role)::text = ANY (ARRAY['clinic_staff'::text, 'patient'::text])))
);


--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
)
PARTITION BY RANGE (inserted_at);


--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    action_filter text DEFAULT '*'::text,
    CONSTRAINT subscription_action_filter_check CHECK ((action_filter = ANY (ARRAY['*'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text])))
);


--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: -
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_analytics (
    name text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: buckets_vectors; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_vectors (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'VECTOR'::storage.buckettype NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb,
    metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: vector_indexes; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.vector_indexes (
    id text DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    bucket_id text NOT NULL,
    data_type text NOT NULL,
    dimension integer NOT NULL,
    distance_metric text NOT NULL,
    metadata_configuration jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: supabase_migrations; Owner: -
--

CREATE TABLE supabase_migrations.schema_migrations (
    version text NOT NULL,
    statements text[],
    name text
);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: custom_oauth_providers custom_oauth_providers_identifier_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_identifier_key UNIQUE (identifier);


--
-- Name: custom_oauth_providers custom_oauth_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_client_states oauth_client_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_client_states
    ADD CONSTRAINT oauth_client_states_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: webauthn_challenges webauthn_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_pkey PRIMARY KEY (id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (id);


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: clinic_memberships clinic_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_memberships
    ADD CONSTRAINT clinic_memberships_pkey PRIMARY KEY (id);


--
-- Name: clinic_memberships clinic_memberships_user_clinic_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_memberships
    ADD CONSTRAINT clinic_memberships_user_clinic_unique UNIQUE (clinic_id, user_id);


--
-- Name: clinic_patients clinic_patients_mrn_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_patients
    ADD CONSTRAINT clinic_patients_mrn_unique UNIQUE (clinic_id, mrn);


--
-- Name: clinic_patients clinic_patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_patients
    ADD CONSTRAINT clinic_patients_pkey PRIMARY KEY (id);


--
-- Name: clinic_patients clinic_patients_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_patients
    ADD CONSTRAINT clinic_patients_unique UNIQUE (clinic_id, patient_id);


--
-- Name: clinics clinics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinics
    ADD CONSTRAINT clinics_pkey PRIMARY KEY (id);


--
-- Name: cognitive_assessments cognitive_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cognitive_assessments
    ADD CONSTRAINT cognitive_assessments_pkey PRIMARY KEY (id);


--
-- Name: developmental_history developmental_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developmental_history
    ADD CONSTRAINT developmental_history_pkey PRIMARY KEY (id);


--
-- Name: patient_clinic_consents patient_clinic_consents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_clinic_consents
    ADD CONSTRAINT patient_clinic_consents_pkey PRIMARY KEY (id);


--
-- Name: patient_family_data patient_family_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_family_data
    ADD CONSTRAINT patient_family_data_pkey PRIMARY KEY (id);


--
-- Name: patient_invitations patient_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_invitations
    ADD CONSTRAINT patient_invitations_pkey PRIMARY KEY (id);


--
-- Name: patient_personal_data patient_personal_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_personal_data
    ADD CONSTRAINT patient_personal_data_pkey PRIMARY KEY (id);


--
-- Name: patient_visits patient_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_visits
    ADD CONSTRAINT patient_visits_pkey PRIMARY KEY (id);


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: referrals_and_feedback referrals_and_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals_and_feedback
    ADD CONSTRAINT referrals_and_feedback_pkey PRIMARY KEY (id);


--
-- Name: therapy_sessions therapy_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.therapy_sessions
    ADD CONSTRAINT therapy_sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: buckets_vectors buckets_vectors_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_vectors
    ADD CONSTRAINT buckets_vectors_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: vector_indexes vector_indexes_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: supabase_migrations; Owner: -
--

ALTER TABLE ONLY supabase_migrations.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: custom_oauth_providers_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_created_at_idx ON auth.custom_oauth_providers USING btree (created_at);


--
-- Name: custom_oauth_providers_enabled_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_enabled_idx ON auth.custom_oauth_providers USING btree (enabled);


--
-- Name: custom_oauth_providers_identifier_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_identifier_idx ON auth.custom_oauth_providers USING btree (identifier);


--
-- Name: custom_oauth_providers_provider_type_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_provider_type_idx ON auth.custom_oauth_providers USING btree (provider_type);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_oauth_client_states_created_at; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: webauthn_challenges_expires_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_challenges_expires_at_idx ON auth.webauthn_challenges USING btree (expires_at);


--
-- Name: webauthn_challenges_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_challenges_user_id_idx ON auth.webauthn_challenges USING btree (user_id);


--
-- Name: webauthn_credentials_credential_id_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX webauthn_credentials_credential_id_key ON auth.webauthn_credentials USING btree (credential_id);


--
-- Name: webauthn_credentials_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_credentials_user_id_idx ON auth.webauthn_credentials USING btree (user_id);


--
-- Name: appointments_clinic_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appointments_clinic_id_idx ON public.appointments USING btree (clinic_id);


--
-- Name: appointments_clinic_patient_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appointments_clinic_patient_id_idx ON public.appointments USING btree (clinic_patient_id);


--
-- Name: appointments_patient_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appointments_patient_id_idx ON public.appointments USING btree (patient_id);


--
-- Name: appointments_practitioner_membership_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appointments_practitioner_membership_id_idx ON public.appointments USING btree (practitioner_membership_id);


--
-- Name: appointments_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appointments_start_time_idx ON public.appointments USING btree (start_time);


--
-- Name: clinic_memberships_clinic_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX clinic_memberships_clinic_idx ON public.clinic_memberships USING btree (clinic_id);


--
-- Name: clinic_memberships_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX clinic_memberships_user_idx ON public.clinic_memberships USING btree (user_id);


--
-- Name: clinic_patients_clinic_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX clinic_patients_clinic_idx ON public.clinic_patients USING btree (clinic_id);


--
-- Name: clinic_patients_patient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX clinic_patients_patient_idx ON public.clinic_patients USING btree (patient_id);


--
-- Name: clinics_slug_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX clinics_slug_unique ON public.clinics USING btree (slug);


--
-- Name: cognitive_assessments_clinic_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cognitive_assessments_clinic_id_idx ON public.cognitive_assessments USING btree (clinic_id);


--
-- Name: cognitive_assessments_visit_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX cognitive_assessments_visit_id_unique ON public.cognitive_assessments USING btree (visit_id);


--
-- Name: developmental_history_clinic_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX developmental_history_clinic_id_idx ON public.developmental_history USING btree (clinic_id);


--
-- Name: developmental_history_visit_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX developmental_history_visit_id_unique ON public.developmental_history USING btree (visit_id);


--
-- Name: patient_clinic_consents_active_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patient_clinic_consents_active_unique ON public.patient_clinic_consents USING btree (clinic_id, patient_id) WHERE (revoked_at IS NULL);


--
-- Name: patient_clinic_consents_clinic_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_clinic_consents_clinic_idx ON public.patient_clinic_consents USING btree (clinic_id);


--
-- Name: patient_clinic_consents_invitation_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_clinic_consents_invitation_idx ON public.patient_clinic_consents USING btree (invitation_id);


--
-- Name: patient_clinic_consents_patient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_clinic_consents_patient_idx ON public.patient_clinic_consents USING btree (patient_id);


--
-- Name: patient_family_data_clinic_patient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_family_data_clinic_patient_idx ON public.patient_family_data USING btree (clinic_id, patient_id);


--
-- Name: patient_family_data_clinic_patient_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patient_family_data_clinic_patient_unique ON public.patient_family_data USING btree (clinic_id, patient_id);


--
-- Name: patient_invitations_appointment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_invitations_appointment_idx ON public.patient_invitations USING btree (appointment_id);


--
-- Name: patient_invitations_clinic_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_invitations_clinic_id_idx ON public.patient_invitations USING btree (clinic_id);


--
-- Name: patient_invitations_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_invitations_email_idx ON public.patient_invitations USING btree (email);


--
-- Name: patient_invitations_flow_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_invitations_flow_idx ON public.patient_invitations USING btree (flow);


--
-- Name: patient_invitations_session_start_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_invitations_session_start_idx ON public.patient_invitations USING btree (session_start_at);


--
-- Name: patient_invitations_target_patient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_invitations_target_patient_idx ON public.patient_invitations USING btree (target_patient_id);


--
-- Name: patient_invitations_token_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patient_invitations_token_unique ON public.patient_invitations USING btree (token);


--
-- Name: patient_personal_data_clinic_patient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_personal_data_clinic_patient_idx ON public.patient_personal_data USING btree (clinic_id, patient_id);


--
-- Name: patient_personal_data_clinic_patient_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patient_personal_data_clinic_patient_unique ON public.patient_personal_data USING btree (clinic_id, patient_id);


--
-- Name: patient_visits_appointment_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patient_visits_appointment_id_unique ON public.patient_visits USING btree (appointment_id);


--
-- Name: patient_visits_clinic_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_visits_clinic_id_idx ON public.patient_visits USING btree (clinic_id);


--
-- Name: patient_visits_clinic_patient_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_visits_clinic_patient_id_idx ON public.patient_visits USING btree (clinic_patient_id);


--
-- Name: patient_visits_patient_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_visits_patient_id_idx ON public.patient_visits USING btree (patient_id);


--
-- Name: patients_mrn_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patients_mrn_unique ON public.patients USING btree (mrn);


--
-- Name: patients_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patients_user_id_idx ON public.patients USING btree (user_id);


--
-- Name: referrals_and_feedback_clinic_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX referrals_and_feedback_clinic_id_idx ON public.referrals_and_feedback USING btree (clinic_id);


--
-- Name: referrals_and_feedback_patient_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX referrals_and_feedback_patient_id_idx ON public.referrals_and_feedback USING btree (patient_id);


--
-- Name: referrals_and_feedback_practitioner_membership_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX referrals_and_feedback_practitioner_membership_idx ON public.referrals_and_feedback USING btree (practitioner_membership_id);


--
-- Name: referrals_and_feedback_secure_pin_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX referrals_and_feedback_secure_pin_idx ON public.referrals_and_feedback USING btree (secure_pin);


--
-- Name: referrals_and_feedback_visit_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX referrals_and_feedback_visit_id_idx ON public.referrals_and_feedback USING btree (visit_id);


--
-- Name: therapy_sessions_clinic_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX therapy_sessions_clinic_id_idx ON public.therapy_sessions USING btree (clinic_id);


--
-- Name: therapy_sessions_session_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX therapy_sessions_session_date_idx ON public.therapy_sessions USING btree (session_date);


--
-- Name: therapy_sessions_visit_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX therapy_sessions_visit_id_idx ON public.therapy_sessions USING btree (visit_id);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_action_filter_key; Type: INDEX; Schema: realtime; Owner: -
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_action_filter_key ON realtime.subscription USING btree (subscription_id, entity, filters, action_filter);


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: buckets_analytics_unique_name_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX buckets_analytics_unique_name_idx ON storage.buckets_analytics USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: vector_indexes_name_bucket_id_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX vector_indexes_name_bucket_id_idx ON storage.vector_indexes USING btree (name, bucket_id);


--
-- Name: users on_auth_user_created; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();


--
-- Name: clinic_memberships trg_clinic_memberships_sync_profile; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_clinic_memberships_sync_profile BEFORE INSERT OR UPDATE ON public.clinic_memberships FOR EACH ROW EXECUTE FUNCTION public.sync_clinic_membership_profile_defaults();


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: -
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: buckets protect_buckets_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects protect_objects_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: webauthn_challenges webauthn_challenges_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: appointments appointments_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: appointments appointments_clinic_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_clinic_patient_id_fkey FOREIGN KEY (clinic_patient_id) REFERENCES public.clinic_patients(id) ON DELETE RESTRICT;


--
-- Name: appointments appointments_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: appointments appointments_practitioner_membership_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_practitioner_membership_id_fkey FOREIGN KEY (practitioner_membership_id) REFERENCES public.clinic_memberships(id) ON DELETE RESTRICT;


--
-- Name: clinic_memberships clinic_memberships_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_memberships
    ADD CONSTRAINT clinic_memberships_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: clinic_memberships clinic_memberships_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_memberships
    ADD CONSTRAINT clinic_memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: clinic_patients clinic_patients_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_patients
    ADD CONSTRAINT clinic_patients_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: clinic_patients clinic_patients_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinic_patients
    ADD CONSTRAINT clinic_patients_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: clinics clinics_owner_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinics
    ADD CONSTRAINT clinics_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: cognitive_assessments cognitive_assessments_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cognitive_assessments
    ADD CONSTRAINT cognitive_assessments_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: cognitive_assessments cognitive_assessments_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cognitive_assessments
    ADD CONSTRAINT cognitive_assessments_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.patient_visits(id) ON DELETE CASCADE;


--
-- Name: developmental_history developmental_history_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developmental_history
    ADD CONSTRAINT developmental_history_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: developmental_history developmental_history_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developmental_history
    ADD CONSTRAINT developmental_history_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.patient_visits(id) ON DELETE CASCADE;


--
-- Name: patient_clinic_consents patient_clinic_consents_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_clinic_consents
    ADD CONSTRAINT patient_clinic_consents_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: patient_clinic_consents patient_clinic_consents_invitation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_clinic_consents
    ADD CONSTRAINT patient_clinic_consents_invitation_id_fkey FOREIGN KEY (invitation_id) REFERENCES public.patient_invitations(id) ON DELETE SET NULL;


--
-- Name: patient_clinic_consents patient_clinic_consents_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_clinic_consents
    ADD CONSTRAINT patient_clinic_consents_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: patient_family_data patient_family_data_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_family_data
    ADD CONSTRAINT patient_family_data_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: patient_family_data patient_family_data_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_family_data
    ADD CONSTRAINT patient_family_data_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: patient_invitations patient_invitations_appointment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_invitations
    ADD CONSTRAINT patient_invitations_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE SET NULL;


--
-- Name: patient_invitations patient_invitations_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_invitations
    ADD CONSTRAINT patient_invitations_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: patient_invitations patient_invitations_invited_by_membership_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_invitations
    ADD CONSTRAINT patient_invitations_invited_by_membership_id_fkey FOREIGN KEY (invited_by_membership_id) REFERENCES public.clinic_memberships(id) ON DELETE SET NULL;


--
-- Name: patient_invitations patient_invitations_practitioner_membership_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_invitations
    ADD CONSTRAINT patient_invitations_practitioner_membership_id_fkey FOREIGN KEY (practitioner_membership_id) REFERENCES public.clinic_memberships(id) ON DELETE SET NULL;


--
-- Name: patient_invitations patient_invitations_replaced_by_invitation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_invitations
    ADD CONSTRAINT patient_invitations_replaced_by_invitation_id_fkey FOREIGN KEY (replaced_by_invitation_id) REFERENCES public.patient_invitations(id) ON DELETE SET NULL;


--
-- Name: patient_invitations patient_invitations_target_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_invitations
    ADD CONSTRAINT patient_invitations_target_patient_id_fkey FOREIGN KEY (target_patient_id) REFERENCES public.patients(id) ON DELETE SET NULL;


--
-- Name: patient_personal_data patient_personal_data_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_personal_data
    ADD CONSTRAINT patient_personal_data_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: patient_personal_data patient_personal_data_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_personal_data
    ADD CONSTRAINT patient_personal_data_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: patient_visits patient_visits_appointment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_visits
    ADD CONSTRAINT patient_visits_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE CASCADE;


--
-- Name: patient_visits patient_visits_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_visits
    ADD CONSTRAINT patient_visits_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: patient_visits patient_visits_clinic_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_visits
    ADD CONSTRAINT patient_visits_clinic_patient_id_fkey FOREIGN KEY (clinic_patient_id) REFERENCES public.clinic_patients(id) ON DELETE RESTRICT;


--
-- Name: patient_visits patient_visits_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_visits
    ADD CONSTRAINT patient_visits_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: patients patients_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: referrals_and_feedback referrals_and_feedback_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals_and_feedback
    ADD CONSTRAINT referrals_and_feedback_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: referrals_and_feedback referrals_and_feedback_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals_and_feedback
    ADD CONSTRAINT referrals_and_feedback_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id) ON DELETE CASCADE;


--
-- Name: referrals_and_feedback referrals_and_feedback_practitioner_membership_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals_and_feedback
    ADD CONSTRAINT referrals_and_feedback_practitioner_membership_id_fkey FOREIGN KEY (practitioner_membership_id) REFERENCES public.clinic_memberships(id) ON DELETE SET NULL;


--
-- Name: referrals_and_feedback referrals_and_feedback_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals_and_feedback
    ADD CONSTRAINT referrals_and_feedback_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.patient_visits(id) ON DELETE CASCADE;


--
-- Name: therapy_sessions therapy_sessions_clinic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.therapy_sessions
    ADD CONSTRAINT therapy_sessions_clinic_id_fkey FOREIGN KEY (clinic_id) REFERENCES public.clinics(id) ON DELETE CASCADE;


--
-- Name: therapy_sessions therapy_sessions_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.therapy_sessions
    ADD CONSTRAINT therapy_sessions_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.patient_visits(id) ON DELETE CASCADE;


--
-- Name: users users_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: vector_indexes vector_indexes_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets_vectors(id);


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: appointments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

--
-- Name: appointments appointments_clinic_ops_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY appointments_clinic_ops_all ON public.appointments TO authenticated USING (public.has_ops_access(clinic_id)) WITH CHECK (public.has_ops_access(clinic_id));


--
-- Name: clinic_memberships; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.clinic_memberships ENABLE ROW LEVEL SECURITY;

--
-- Name: clinic_memberships clinic_memberships_member_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY clinic_memberships_member_select ON public.clinic_memberships FOR SELECT TO authenticated USING (public.has_active_membership(clinic_id));


--
-- Name: clinic_memberships clinic_memberships_owner_manage; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY clinic_memberships_owner_manage ON public.clinic_memberships TO authenticated USING (public.has_owner_access(clinic_id)) WITH CHECK (public.has_owner_access(clinic_id));


--
-- Name: clinic_patients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.clinic_patients ENABLE ROW LEVEL SECURITY;

--
-- Name: clinic_patients clinic_patients_ops_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY clinic_patients_ops_all ON public.clinic_patients TO authenticated USING (public.has_ops_access(clinic_id)) WITH CHECK (public.has_ops_access(clinic_id));


--
-- Name: clinics; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.clinics ENABLE ROW LEVEL SECURITY;

--
-- Name: clinics clinics_member_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY clinics_member_select ON public.clinics FOR SELECT TO authenticated USING (public.has_active_membership(id));


--
-- Name: clinics clinics_owner_manage; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY clinics_owner_manage ON public.clinics TO authenticated USING (public.has_owner_access(id)) WITH CHECK (public.has_owner_access(id));


--
-- Name: cognitive_assessments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.cognitive_assessments ENABLE ROW LEVEL SECURITY;

--
-- Name: cognitive_assessments cognitive_assessments_clinic_ops_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY cognitive_assessments_clinic_ops_all ON public.cognitive_assessments TO authenticated USING (public.has_ops_access(clinic_id)) WITH CHECK (public.has_ops_access(clinic_id));


--
-- Name: developmental_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.developmental_history ENABLE ROW LEVEL SECURITY;

--
-- Name: developmental_history developmental_history_clinic_ops_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY developmental_history_clinic_ops_all ON public.developmental_history TO authenticated USING (public.has_ops_access(clinic_id)) WITH CHECK (public.has_ops_access(clinic_id));


--
-- Name: patient_clinic_consents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.patient_clinic_consents ENABLE ROW LEVEL SECURITY;

--
-- Name: patient_clinic_consents patient_clinic_consents_clinic_ops_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY patient_clinic_consents_clinic_ops_all ON public.patient_clinic_consents TO authenticated USING (public.has_ops_access(clinic_id)) WITH CHECK (public.has_ops_access(clinic_id));


--
-- Name: patient_family_data; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.patient_family_data ENABLE ROW LEVEL SECURITY;

--
-- Name: patient_family_data patient_family_data_clinic_ops_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY patient_family_data_clinic_ops_all ON public.patient_family_data TO authenticated USING (public.has_ops_access(clinic_id)) WITH CHECK (public.has_ops_access(clinic_id));


--
-- Name: patient_invitations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.patient_invitations ENABLE ROW LEVEL SECURITY;

--
-- Name: patient_invitations patient_invitations_clinic_ops_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY patient_invitations_clinic_ops_all ON public.patient_invitations TO authenticated USING (public.has_ops_access(clinic_id)) WITH CHECK (public.has_ops_access(clinic_id));


--
-- Name: patient_personal_data; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.patient_personal_data ENABLE ROW LEVEL SECURITY;

--
-- Name: patient_personal_data patient_personal_data_clinic_ops_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY patient_personal_data_clinic_ops_all ON public.patient_personal_data TO authenticated USING (public.has_ops_access(clinic_id)) WITH CHECK (public.has_ops_access(clinic_id));


--
-- Name: patient_visits; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.patient_visits ENABLE ROW LEVEL SECURITY;

--
-- Name: patient_visits patient_visits_clinic_ops_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY patient_visits_clinic_ops_all ON public.patient_visits TO authenticated USING (public.has_ops_access(clinic_id)) WITH CHECK (public.has_ops_access(clinic_id));


--
-- Name: patients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

--
-- Name: patients patients_clinic_access_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY patients_clinic_access_all ON public.patients TO authenticated USING (public.has_patient_access(id)) WITH CHECK (public.is_portal_staff());


--
-- Name: referrals_and_feedback; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.referrals_and_feedback ENABLE ROW LEVEL SECURITY;

--
-- Name: referrals_and_feedback referrals_and_feedback_clinic_practitioner_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY referrals_and_feedback_clinic_practitioner_all ON public.referrals_and_feedback TO authenticated USING (public.has_practitioner_access(clinic_id)) WITH CHECK (public.has_practitioner_access(clinic_id));


--
-- Name: therapy_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.therapy_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: therapy_sessions therapy_sessions_clinic_practitioner_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY therapy_sessions_clinic_practitioner_all ON public.therapy_sessions TO authenticated USING (public.has_practitioner_access(clinic_id)) WITH CHECK (public.has_practitioner_access(clinic_id));


--
-- Name: users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

--
-- Name: users users_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_select_own ON public.users FOR SELECT TO authenticated USING ((auth.uid() = id));


--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_vectors; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_vectors ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: vector_indexes; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.vector_indexes ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: ensure_rls; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER ensure_rls ON ddl_command_end
         WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
   EXECUTE FUNCTION public.rls_auto_enable();


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- PostgreSQL database dump complete
--

\unrestrict F5vV2pbCdQnKrARPKQyWc9Y7qlLvmBJozUpDB1IlGRCmmKtPrFcFWJMYybwdQbL

