--
-- PostgreSQL database dump
--

\restrict cuk4TqhH20QHuhEt7ahv2WM2dWoniMhAaAhZj9NeXE8IczoRfr4uYrZdEhN7VdR

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
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
\.


--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.custom_oauth_providers (id, provider_type, identifier, name, client_id, client_secret, acceptable_client_ids, scopes, pkce_enabled, attribute_mapping, authorization_params, enabled, email_optional, issuer, discovery_url, skip_nonce_check, cached_discovery, discovery_cached_at, authorization_url, token_url, userinfo_url, jwks_uri, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at, invite_token, referrer, oauth_client_state_id, linking_target_id, email_optional) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
00000000-0000-0000-0000-000000000000	589ef416-6128-40dd-8b0d-892562b04fdf	authenticated	authenticated	laksamana.guntur24@gmail.com	$2a$10$p76RBAXLSxONGgcwblylu.hK0xQmQJx5dbJao4tunyEli22b8BIn.	2026-03-07 07:23:57.546975+00	\N		\N		\N			\N	2026-03-07 17:22:35.319425+00	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-03-07 07:23:57.520903+00	2026-03-07 17:22:35.350587+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	415e699e-d4ea-4038-880f-a1ff80419b8f	authenticated	authenticated	akbardzulfikarwork@gmail.com	$2a$10$GDQVCk60dzk7uVYUc9g.KOhZdXfmfgMpxEAyGDTGT5OD3GQHTRHZq	\N	\N	dc0f58b33b7c2c565882b750dbdbc8eb5f9f928e1137402fd6ee0b44	2026-03-06 04:09:44.131979+00		\N			\N	\N	{"provider": "email", "providers": ["email"]}	{"sub": "415e699e-d4ea-4038-880f-a1ff80419b8f", "role": "patient", "email": "akbardzulfikarwork@gmail.com", "email_verified": false, "phone_verified": false}	\N	2026-03-06 04:09:44.084179+00	2026-03-06 04:09:45.803399+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	c8411c53-10d0-4183-8e4e-dd14a91026d7	authenticated	authenticated	akbarown@test.com	$2a$10$ZSaKnRDk/y7NQsO/TnfsNOPsieuy98zhhUsUxVjz.4vf4b5Tbfa.u	2026-03-05 18:57:24.785736+00	\N		\N		\N			\N	2026-03-05 18:57:45.688169+00	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2026-03-05 18:57:24.752922+00	2026-03-06 07:44:46.484876+00	\N	\N			\N		0	\N		\N	f	\N	f
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
c8411c53-10d0-4183-8e4e-dd14a91026d7	c8411c53-10d0-4183-8e4e-dd14a91026d7	{"sub": "c8411c53-10d0-4183-8e4e-dd14a91026d7", "email": "akbarown@test.com", "email_verified": false, "phone_verified": false}	email	2026-03-05 18:57:24.781227+00	2026-03-05 18:57:24.781289+00	2026-03-05 18:57:24.781289+00	c461b2a3-40a0-4cf0-ab0f-abab1a64b4a2
415e699e-d4ea-4038-880f-a1ff80419b8f	415e699e-d4ea-4038-880f-a1ff80419b8f	{"sub": "415e699e-d4ea-4038-880f-a1ff80419b8f", "role": "patient", "email": "akbardzulfikarwork@gmail.com", "email_verified": false, "phone_verified": false}	email	2026-03-06 04:09:44.123029+00	2026-03-06 04:09:44.123077+00	2026-03-06 04:09:44.123077+00	75254dcd-826d-4b53-bae4-58bf5fe47252
589ef416-6128-40dd-8b0d-892562b04fdf	589ef416-6128-40dd-8b0d-892562b04fdf	{"sub": "589ef416-6128-40dd-8b0d-892562b04fdf", "email": "laksamana.guntur24@gmail.com", "email_verified": false, "phone_verified": false}	email	2026-03-07 07:23:57.536998+00	2026-03-07 07:23:57.53707+00	2026-03-07 07:23:57.53707+00	d009bed2-135c-4b9e-9d51-2d80aec252a7
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_clients (id, client_secret_hash, registration_type, redirect_uris, grant_types, client_name, client_uri, logo_uri, created_at, updated_at, deleted_at, client_type, token_endpoint_auth_method) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) FROM stdin;
f3ece5cb-6248-4747-8dce-b2ca5c4161b8	c8411c53-10d0-4183-8e4e-dd14a91026d7	2026-03-05 18:57:45.68826+00	2026-03-06 08:36:29.636354+00	\N	aal1	\N	2026-03-06 08:36:29.634513	node	104.28.163.99	\N	\N	\N	\N	\N
5fc72cea-7260-4b69-a9e6-5e67b6d224a0	589ef416-6128-40dd-8b0d-892562b04fdf	2026-03-07 08:54:58.425497+00	2026-03-07 15:30:05.394763+00	\N	aal1	\N	2026-03-07 15:30:05.394666	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	180.252.116.101	\N	\N	\N	\N	\N
7e0cb9fb-bd2d-4469-b499-53bb5cb04b3a	589ef416-6128-40dd-8b0d-892562b04fdf	2026-03-07 15:30:05.524716+00	2026-03-07 17:07:26.531246+00	\N	aal1	\N	2026-03-07 17:07:26.531146	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	180.252.116.101	\N	\N	\N	\N	\N
3ba680e3-b4f2-43cd-9a24-e84400f713be	589ef416-6128-40dd-8b0d-892562b04fdf	2026-03-07 17:22:35.31953+00	2026-03-07 17:22:35.31953+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	180.252.116.101	\N	\N	\N	\N	\N
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
f3ece5cb-6248-4747-8dce-b2ca5c4161b8	2026-03-05 18:57:45.694209+00	2026-03-05 18:57:45.694209+00	password	5082fa0b-2623-44c3-a6fd-00db508245a2
5fc72cea-7260-4b69-a9e6-5e67b6d224a0	2026-03-07 08:54:58.458626+00	2026-03-07 08:54:58.458626+00	password	e7aac624-d93f-4790-aadf-343c0ea082d6
7e0cb9fb-bd2d-4469-b499-53bb5cb04b3a	2026-03-07 15:30:05.561147+00	2026-03-07 15:30:05.561147+00	password	97f0d1cd-d35e-4c6d-98a2-305d27d36832
3ba680e3-b4f2-43cd-9a24-e84400f713be	2026-03-07 17:22:35.3518+00	2026-03-07 17:22:35.3518+00	password	6060aef9-50b7-4482-a27d-7c089bcd0169
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid, last_webauthn_challenge_data) FROM stdin;
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_authorizations (id, authorization_id, client_id, user_id, redirect_uri, scope, state, resource, code_challenge, code_challenge_method, response_type, status, authorization_code, created_at, expires_at, approved_at, nonce) FROM stdin;
\.


--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_client_states (id, provider_type, code_verifier, created_at) FROM stdin;
\.


--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.oauth_consents (id, user_id, client_id, scopes, granted_at, revoked_at) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
b5489af0-4376-4496-a9ea-d5f5dafce91c	415e699e-d4ea-4038-880f-a1ff80419b8f	confirmation_token	dc0f58b33b7c2c565882b750dbdbc8eb5f9f928e1137402fd6ee0b44	akbardzulfikarwork@gmail.com	2026-03-06 04:09:45.814913	2026-03-06 04:09:45.814913
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
00000000-0000-0000-0000-000000000000	6	hbkgwxst6g5t	c8411c53-10d0-4183-8e4e-dd14a91026d7	t	2026-03-05 18:57:45.691285+00	2026-03-05 19:56:56.997821+00	\N	f3ece5cb-6248-4747-8dce-b2ca5c4161b8
00000000-0000-0000-0000-000000000000	7	qhdc3vth3kiz	c8411c53-10d0-4183-8e4e-dd14a91026d7	t	2026-03-05 19:56:57.010804+00	2026-03-06 06:15:01.969931+00	hbkgwxst6g5t	f3ece5cb-6248-4747-8dce-b2ca5c4161b8
00000000-0000-0000-0000-000000000000	8	kw3urm3a74ki	c8411c53-10d0-4183-8e4e-dd14a91026d7	t	2026-03-06 06:15:01.987785+00	2026-03-06 07:44:46.457936+00	qhdc3vth3kiz	f3ece5cb-6248-4747-8dce-b2ca5c4161b8
00000000-0000-0000-0000-000000000000	9	uw2idyar5nav	c8411c53-10d0-4183-8e4e-dd14a91026d7	f	2026-03-06 07:44:46.475947+00	2026-03-06 07:44:46.475947+00	kw3urm3a74ki	f3ece5cb-6248-4747-8dce-b2ca5c4161b8
00000000-0000-0000-0000-000000000000	10	v7iwz2yno3a5	589ef416-6128-40dd-8b0d-892562b04fdf	t	2026-03-07 08:54:58.443302+00	2026-03-07 15:29:50.284691+00	\N	5fc72cea-7260-4b69-a9e6-5e67b6d224a0
00000000-0000-0000-0000-000000000000	11	7p2qmxu24c34	589ef416-6128-40dd-8b0d-892562b04fdf	f	2026-03-07 15:29:50.314887+00	2026-03-07 15:29:50.314887+00	v7iwz2yno3a5	5fc72cea-7260-4b69-a9e6-5e67b6d224a0
00000000-0000-0000-0000-000000000000	12	p4rdwwe5b7vo	589ef416-6128-40dd-8b0d-892562b04fdf	t	2026-03-07 15:30:05.546861+00	2026-03-07 17:07:26.49553+00	\N	7e0cb9fb-bd2d-4469-b499-53bb5cb04b3a
00000000-0000-0000-0000-000000000000	13	zqetsoquyuky	589ef416-6128-40dd-8b0d-892562b04fdf	f	2026-03-07 17:07:26.513269+00	2026-03-07 17:07:26.513269+00	p4rdwwe5b7vo	7e0cb9fb-bd2d-4469-b499-53bb5cb04b3a
00000000-0000-0000-0000-000000000000	14	dk35mh342ktj	589ef416-6128-40dd-8b0d-892562b04fdf	f	2026-03-07 17:22:35.34287+00	2026-03-07 17:22:35.34287+00	\N	3ba680e3-b4f2-43cd-9a24-e84400f713be
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
20250717082212
20250731150234
20250804100000
20250901200500
20250903112500
20250904133000
20250925093508
20251007112900
20251104100000
20251111201300
20251201000000
20260115000000
20260121000000
20260219120000
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, role, created_at, updated_at) FROM stdin;
c8411c53-10d0-4183-8e4e-dd14a91026d7	clinic_staff	2026-03-05 18:57:24.752569+00	2026-03-05 19:05:41.558251+00
415e699e-d4ea-4038-880f-a1ff80419b8f	patient	2026-03-06 04:09:44.083217+00	2026-03-06 04:09:45.89093+00
589ef416-6128-40dd-8b0d-892562b04fdf	clinic_staff	2026-03-07 07:23:57.51829+00	2026-03-07 07:23:57.51829+00
\.


--
-- Data for Name: clinics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clinics (id, name, slug, owner_user_id, is_active, created_at, updated_at) FROM stdin;
b803f28f-3bc8-4a11-abc9-84680c457c81	klinik sehat akbar	klinik-sehat-akbar	c8411c53-10d0-4183-8e4e-dd14a91026d7	t	2026-03-05 18:58:03.847039+00	2026-03-05 18:58:03.847039+00
307ab009-c160-460a-9fd3-3828f8d1896f	guntur name	guntur slug	589ef416-6128-40dd-8b0d-892562b04fdf	t	2026-03-07 07:40:12.710933+00	2026-03-07 07:40:12.710933+00
\.


--
-- Data for Name: clinic_memberships; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clinic_memberships (id, clinic_id, user_id, is_owner, is_staff, is_practitioner, profession, is_active, created_at, updated_at, full_name, email, birth_date, ktp_number, gender, address, phone, sip_number) FROM stdin;
04b873e8-696d-403d-8393-209422db68d0	b803f28f-3bc8-4a11-abc9-84680c457c81	c8411c53-10d0-4183-8e4e-dd14a91026d7	t	t	t	psychologist	t	2026-03-05 18:58:03.847039+00	2026-03-06 07:26:31.747601+00	akbarown	akbarown@test.com	1990-01-01	3174xxxxxxxxxxxx	male	Jakarta	081234567890	SIP-PSI-001
\.


--
-- Data for Name: patients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patients (id, user_id, mrn, full_name, email, phone, created_at, updated_at) FROM stdin;
d8ffffdb-6b17-4355-9326-4f91074f34c3	415e699e-d4ea-4038-880f-a1ff80419b8f	MRN-20260306-D0BFC6	akbar dzulfikar	akbardzulfikarwork@gmail.com	081234567890	2026-03-06 04:09:45.89093+00	2026-03-06 04:09:46.031642+00
\.


--
-- Data for Name: clinic_patients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clinic_patients (id, clinic_id, patient_id, mrn, is_active, created_at, updated_at) FROM stdin;
3024df41-3167-4b69-b118-587c8dce228a	b803f28f-3bc8-4a11-abc9-84680c457c81	d8ffffdb-6b17-4355-9326-4f91074f34c3	MRN-20260306-D0BFC6	t	2026-03-06 04:09:46.031642+00	2026-03-06 04:15:38.489595+00
\.


--
-- Data for Name: appointments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appointments (id, patient_id, start_time, end_time, status, notes, created_at, updated_at, clinic_id, clinic_patient_id, practitioner_membership_id) FROM stdin;
2507b030-a010-45cd-997f-e5f6b260bf07	d8ffffdb-6b17-4355-9326-4f91074f34c3	2026-03-09 08:55:00+00	2026-03-09 09:40:00+00	scheduled	Auto-created from patient registration + consent	2026-03-06 04:09:46.031642+00	2026-03-06 04:09:46.031642+00	b803f28f-3bc8-4a11-abc9-84680c457c81	3024df41-3167-4b69-b118-587c8dce228a	04b873e8-696d-403d-8393-209422db68d0
502f336a-ee15-4c51-bb9a-d52bf6376a94	d8ffffdb-6b17-4355-9326-4f91074f34c3	2026-03-09 09:41:00+00	2026-03-09 10:26:00+00	scheduled	Auto-created from info-only invitation	2026-03-06 04:15:38.489595+00	2026-03-06 04:15:38.489595+00	b803f28f-3bc8-4a11-abc9-84680c457c81	3024df41-3167-4b69-b118-587c8dce228a	04b873e8-696d-403d-8393-209422db68d0
\.


--
-- Data for Name: patient_visits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_visits (id, patient_id, appointment_id, status, created_at, updated_at, clinic_id, clinic_patient_id) FROM stdin;
ecd28371-4483-45ee-b7d0-20aa808cffd1	d8ffffdb-6b17-4355-9326-4f91074f34c3	2507b030-a010-45cd-997f-e5f6b260bf07	scheduled	2026-03-06 04:09:46.031642+00	2026-03-06 04:09:46.031642+00	b803f28f-3bc8-4a11-abc9-84680c457c81	3024df41-3167-4b69-b118-587c8dce228a
150afc83-db65-417e-96f3-d29c29104b27	d8ffffdb-6b17-4355-9326-4f91074f34c3	502f336a-ee15-4c51-bb9a-d52bf6376a94	scheduled	2026-03-06 04:15:38.489595+00	2026-03-06 04:15:38.489595+00	b803f28f-3bc8-4a11-abc9-84680c457c81	3024df41-3167-4b69-b118-587c8dce228a
\.


--
-- Data for Name: cognitive_assessments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cognitive_assessments (id, visit_id, knows_letters, knows_colors, writes, counts, reads, reading_spelling, fluent_reading, reversed_letters, autism_indication, adhd_indication, initial_conclusion, intervention_counseling_given, intervention_areas, other_medical_action, referral_action, assessment_result, created_at, updated_at, clinic_id) FROM stdin;
76b09634-ff30-4f90-8e35-fd99f3322a81	ecd28371-4483-45ee-b7d0-20aa808cffd1	t	t	t	t	f	f	f	t	low_risk	possible_adhd	Perlu observasi lanjutan fokus dan regulasi perilaku.	t	Atensi, regulasi emosi, dan kesiapan belajar.	Belum ada.	Evaluasi berkala 4-6 minggu.	Kemampuan dasar baik, butuh intervensi perilaku terstruktur.	2026-03-06 04:09:46.031642+00	2026-03-06 04:09:46.031642+00	b803f28f-3bc8-4a11-abc9-84680c457c81
\.


--
-- Data for Name: developmental_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.developmental_history (id, visit_id, mother_pregnancy_notes, birth_process, gestational_age_weeks, birth_weight_kg, birth_length_cm, walking_age_months, speaking_age_months, hearing_function, speech_articulation, vision_function, child_medical_history, special_notes, created_at, updated_at, clinic_id) FROM stdin;
1a904c43-c661-454a-99e0-0be796b3fbf0	ecd28371-4483-45ee-b7d0-20aa808cffd1	Kehamilan terpantau rutin, tanpa komplikasi mayor.	normal	39	3.10	49.00	13	20	Baik	Perlu stimulasi ringan	Baik	Tidak ada riwayat penyakit berat.	Anak mudah terdistraksi saat belajar.	2026-03-06 04:09:46.031642+00	2026-03-06 04:09:46.031642+00	b803f28f-3bc8-4a11-abc9-84680c457c81
\.


--
-- Data for Name: patient_invitations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_invitations (id, email, token, expires_at, is_used, used_at, created_at, clinic_id, invited_by_membership_id, flow, session_start_at, session_end_at, session_timezone, target_patient_id, practitioner_membership_id, used_reason, replaced_by_invitation_id, appointment_id) FROM stdin;
7eb9a752-4c2b-4417-9b74-52a2be60b149	akbardzulfikarwork@gmail.com	a54f438b55cf219ed5460fc7a5f690c82d38533cc674f73a16b55debf4c558e0	2026-03-09 04:08:01.456474+00	t	2026-03-06 04:09:46.031642+00	2026-03-06 04:08:01.456474+00	b803f28f-3bc8-4a11-abc9-84680c457c81	04b873e8-696d-403d-8393-209422db68d0	registration_required	2026-03-09 08:55:00+00	2026-03-09 09:40:00+00	Asia/Jakarta	d8ffffdb-6b17-4355-9326-4f91074f34c3	04b873e8-696d-403d-8393-209422db68d0	registration_completed	\N	2507b030-a010-45cd-997f-e5f6b260bf07
f58cf9c2-259c-417d-90fc-90c5f34e1d8a	akbardzulfikarwork@gmail.com	69831c362e01171a49e9df482e4a0427f00aa35bd0fdefe3e7be4d7db250f869	2026-03-09 04:15:38.489595+00	t	2026-03-06 04:15:38.489595+00	2026-03-06 04:15:38.489595+00	b803f28f-3bc8-4a11-abc9-84680c457c81	04b873e8-696d-403d-8393-209422db68d0	info_only	2026-03-09 09:41:00+00	2026-03-09 10:26:00+00	Asia/Jakarta	d8ffffdb-6b17-4355-9326-4f91074f34c3	04b873e8-696d-403d-8393-209422db68d0	info_only_notified	\N	502f336a-ee15-4c51-bb9a-d52bf6376a94
\.


--
-- Data for Name: patient_clinic_consents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_clinic_consents (id, clinic_id, patient_id, invitation_id, consent_version, consent_text, source, accepted_at, accepted_ip, accepted_user_agent, revoked_at, revoked_reason, created_at, updated_at) FROM stdin;
ec620638-c736-4979-8a9d-1707a6cf01e9	b803f28f-3bc8-4a11-abc9-84680c457c81	d8ffffdb-6b17-4355-9326-4f91074f34c3	7eb9a752-4c2b-4417-9b74-52a2be60b149	v1	Saya menyetujui berbagi data medis saya dengan klinik tujuan untuk keperluan layanan psikologi.	registration_wizard	2026-03-06 04:09:46.031642+00	::1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N	\N	2026-03-06 04:09:46.031642+00	2026-03-06 04:09:46.031642+00
\.


--
-- Data for Name: patient_family_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_family_data (id, patient_id, guardian_name, guardian_relation, guardian_phone, guardian_address, father_name, father_age, father_education, father_occupation, mother_name, mother_age, mother_education, mother_occupation, marital_status, number_of_children, monthly_income, family_notes, created_at, updated_at, clinic_id) FROM stdin;
cb75ac00-c07c-422e-8105-24ea4f0516d0	d8ffffdb-6b17-4355-9326-4f91074f34c3	Anita Sari	Ibu	081345678901	Jl. Melati No. 12, Jakarta	Budi Pratama	36	S1	Karyawan Swasta	Anita Sari	34	S1	Ibu Rumah Tangga	Menikah	2	12000000.00	Anak kedua, tinggal bersama orang tua kandung.	2026-03-06 04:09:46.031642+00	2026-03-06 04:09:46.031642+00	b803f28f-3bc8-4a11-abc9-84680c457c81
\.


--
-- Data for Name: patient_personal_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_personal_data (id, patient_id, case_number, sex, birth_date, address, religion, education, occupation, hobby, referral_source, created_at, updated_at, full_name, clinic_id) FROM stdin;
dcaac3b2-c86a-44bd-9156-e3c880cea181	d8ffffdb-6b17-4355-9326-4f91074f34c3	\N	L	2019-08-14	Jl. Melati No. 12, Jakarta	Islam	TK B	\N	Menggambar	Self registration invitation	2026-03-06 04:09:46.031642+00	2026-03-06 04:09:46.031642+00	akbar dzulfikar	b803f28f-3bc8-4a11-abc9-84680c457c81
\.


--
-- Data for Name: referrals_and_feedback; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.referrals_and_feedback (id, visit_id, patient_id, destination, notes, secure_pin, expires_at, created_at, updated_at, clinic_id, practitioner_membership_id) FROM stdin;
dfbbc50c-eaf9-421e-80bf-c9b3272446f6	150afc83-db65-417e-96f3-d29c29104b27	d8ffffdb-6b17-4355-9326-4f91074f34c3	Psikiater	asdaasdasdasda	982134	2026-03-14 00:00:00+00	2026-03-06 06:46:06.371144+00	2026-03-06 06:46:06.371144+00	b803f28f-3bc8-4a11-abc9-84680c457c81	04b873e8-696d-403d-8393-209422db68d0
\.


--
-- Data for Name: therapy_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.therapy_sessions (id, visit_id, session_date, session_time, activity_type, subject, clinical_notes, created_at, updated_at, clinic_id) FROM stdin;
21fed6a4-ad26-4b3c-8410-74ca2e4abc73	150afc83-db65-417e-96f3-d29c29104b27	2026-03-06	13:45:00	Observasi		adasd	2026-03-06 06:45:28.407543+00	2026-03-06 06:45:28.407543+00	b803f28f-3bc8-4a11-abc9-84680c457c81
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2026-03-01 09:42:15
20211116045059	2026-03-01 09:42:16
20211116050929	2026-03-01 09:42:16
20211116051442	2026-03-01 09:42:16
20211116212300	2026-03-01 09:42:16
20211116213355	2026-03-01 09:42:16
20211116213934	2026-03-01 09:42:16
20211116214523	2026-03-01 09:42:16
20211122062447	2026-03-01 09:42:16
20211124070109	2026-03-01 09:42:16
20211202204204	2026-03-01 09:42:16
20211202204605	2026-03-01 09:42:16
20211210212804	2026-03-01 09:42:16
20211228014915	2026-03-01 09:42:17
20220107221237	2026-03-01 09:42:17
20220228202821	2026-03-01 09:42:17
20220312004840	2026-03-01 09:42:17
20220603231003	2026-03-01 09:42:17
20220603232444	2026-03-01 09:42:17
20220615214548	2026-03-01 09:42:17
20220712093339	2026-03-01 09:42:17
20220908172859	2026-03-01 09:42:17
20220916233421	2026-03-01 09:42:17
20230119133233	2026-03-01 09:42:17
20230128025114	2026-03-01 09:42:17
20230128025212	2026-03-01 09:42:17
20230227211149	2026-03-01 09:42:17
20230228184745	2026-03-01 09:42:17
20230308225145	2026-03-01 09:42:17
20230328144023	2026-03-01 09:42:17
20231018144023	2026-03-01 09:42:17
20231204144023	2026-03-01 09:42:17
20231204144024	2026-03-01 09:42:17
20231204144025	2026-03-01 09:42:17
20240108234812	2026-03-01 09:42:17
20240109165339	2026-03-01 09:42:17
20240227174441	2026-03-01 09:42:17
20240311171622	2026-03-01 09:42:17
20240321100241	2026-03-01 09:42:17
20240401105812	2026-03-01 09:42:18
20240418121054	2026-03-01 09:42:18
20240523004032	2026-03-01 09:42:18
20240618124746	2026-03-01 09:42:18
20240801235015	2026-03-01 09:42:18
20240805133720	2026-03-01 09:42:18
20240827160934	2026-03-01 09:42:18
20240919163303	2026-03-01 09:42:18
20240919163305	2026-03-01 09:42:18
20241019105805	2026-03-01 09:42:18
20241030150047	2026-03-01 09:42:18
20241108114728	2026-03-01 09:42:18
20241121104152	2026-03-01 09:42:18
20241130184212	2026-03-01 09:42:18
20241220035512	2026-03-01 09:42:18
20241220123912	2026-03-01 09:42:18
20241224161212	2026-03-01 09:42:18
20250107150512	2026-03-01 09:42:18
20250110162412	2026-03-01 09:42:18
20250123174212	2026-03-01 09:42:18
20250128220012	2026-03-01 09:42:18
20250506224012	2026-03-01 09:42:18
20250523164012	2026-03-01 09:42:18
20250714121412	2026-03-01 09:42:18
20250905041441	2026-03-01 09:42:18
20251103001201	2026-03-01 09:42:18
20251120212548	2026-03-01 09:42:18
20251120215549	2026-03-01 09:42:18
20260218120000	2026-03-01 09:42:18
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: supabase_admin
--

COPY realtime.subscription (id, subscription_id, entity, filters, claims, created_at, action_filter) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) FROM stdin;
\.


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets_analytics (name, type, format, created_at, updated_at, id, deleted_at) FROM stdin;
\.


--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets_vectors (id, type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2026-03-01 09:42:15.443801
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2026-03-01 09:42:15.629019
2	storage-schema	f6a1fa2c93cbcd16d4e487b362e45fca157a8dbd	2026-03-01 09:42:15.648882
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2026-03-01 09:42:15.83562
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2026-03-01 09:42:17.170616
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2026-03-01 09:42:17.209287
6	change-column-name-in-get-size	ded78e2f1b5d7e616117897e6443a925965b30d2	2026-03-01 09:42:17.265401
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2026-03-01 09:42:17.270618
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2026-03-01 09:42:17.277816
9	fix-search-function	af597a1b590c70519b464a4ab3be54490712796b	2026-03-01 09:42:17.28991
10	search-files-search-function	b595f05e92f7e91211af1bbfe9c6a13bb3391e16	2026-03-01 09:42:17.295012
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2026-03-01 09:42:17.313911
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2026-03-01 09:42:17.346518
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2026-03-01 09:42:17.356369
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2026-03-01 09:42:17.361635
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2026-03-01 09:42:17.503734
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2026-03-01 09:42:17.519983
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2026-03-01 09:42:17.524781
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2026-03-01 09:42:17.529799
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2026-03-01 09:42:17.549005
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2026-03-01 09:42:17.554019
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2026-03-01 09:42:17.563713
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2026-03-01 09:42:17.649695
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2026-03-01 09:42:17.673726
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2026-03-01 09:42:17.686546
25	custom-metadata	d974c6057c3db1c1f847afa0e291e6165693b990	2026-03-01 09:42:17.691598
26	objects-prefixes	215cabcb7f78121892a5a2037a09fedf9a1ae322	2026-03-01 09:42:17.699335
27	search-v2	859ba38092ac96eb3964d83bf53ccc0b141663a6	2026-03-01 09:42:17.707064
28	object-bucket-name-sorting	c73a2b5b5d4041e39705814fd3a1b95502d38ce4	2026-03-01 09:42:17.71177
29	create-prefixes	ad2c1207f76703d11a9f9007f821620017a66c21	2026-03-01 09:42:17.717621
30	update-object-levels	2be814ff05c8252fdfdc7cfb4b7f5c7e17f0bed6	2026-03-01 09:42:17.721848
31	objects-level-index	b40367c14c3440ec75f19bbce2d71e914ddd3da0	2026-03-01 09:42:17.726011
32	backward-compatible-index-on-objects	e0c37182b0f7aee3efd823298fb3c76f1042c0f7	2026-03-01 09:42:17.730385
33	backward-compatible-index-on-prefixes	b480e99ed951e0900f033ec4eb34b5bdcb4e3d49	2026-03-01 09:42:17.734654
34	optimize-search-function-v1	ca80a3dc7bfef894df17108785ce29a7fc8ee456	2026-03-01 09:42:17.739333
35	add-insert-trigger-prefixes	458fe0ffd07ec53f5e3ce9df51bfdf4861929ccc	2026-03-01 09:42:17.743708
36	optimise-existing-functions	6ae5fca6af5c55abe95369cd4f93985d1814ca8f	2026-03-01 09:42:17.747769
37	add-bucket-name-length-trigger	3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1	2026-03-01 09:42:17.751852
38	iceberg-catalog-flag-on-buckets	02716b81ceec9705aed84aa1501657095b32e5c5	2026-03-01 09:42:17.94093
39	add-search-v2-sort-support	6706c5f2928846abee18461279799ad12b279b78	2026-03-01 09:42:18.056754
40	fix-prefix-race-conditions-optimized	7ad69982ae2d372b21f48fc4829ae9752c518f6b	2026-03-01 09:42:18.061367
41	add-object-level-update-trigger	07fcf1a22165849b7a029deed059ffcde08d1ae0	2026-03-01 09:42:18.065675
42	rollback-prefix-triggers	771479077764adc09e2ea2043eb627503c034cd4	2026-03-01 09:42:18.069819
43	fix-object-level	84b35d6caca9d937478ad8a797491f38b8c2979f	2026-03-01 09:42:18.079054
44	vector-bucket-type	99c20c0ffd52bb1ff1f32fb992f3b351e3ef8fb3	2026-03-01 09:42:18.083405
45	vector-buckets	049e27196d77a7cb76497a85afae669d8b230953	2026-03-01 09:42:18.107812
46	buckets-objects-grants	fedeb96d60fefd8e02ab3ded9fbde05632f84aed	2026-03-01 09:42:18.164085
47	iceberg-table-metadata	649df56855c24d8b36dd4cc1aeb8251aa9ad42c2	2026-03-01 09:42:18.16961
48	iceberg-catalog-ids	e0e8b460c609b9999ccd0df9ad14294613eed939	2026-03-01 09:42:18.174408
49	buckets-objects-grants-postgres	072b1195d0d5a2f888af6b2302a1938dd94b8b3d	2026-03-01 09:42:18.219457
50	search-v2-optimised	6323ac4f850aa14e7387eb32102869578b5bd478	2026-03-01 09:42:18.224892
51	index-backward-compatible-search	2ee395d433f76e38bcd3856debaf6e0e5b674011	2026-03-01 09:42:47.238984
52	drop-not-used-indexes-and-functions	5cc44c8696749ac11dd0dc37f2a3802075f3a171	2026-03-01 09:42:47.252662
53	drop-index-lower-name	d0cb18777d9e2a98ebe0bc5cc7a42e57ebe41854	2026-03-01 09:42:47.282176
54	drop-index-object-level	6289e048b1472da17c31a7eba1ded625a6457e67	2026-03-01 09:42:47.285089
55	prevent-direct-deletes	262a4798d5e0f2e7c8970232e03ce8be695d5819	2026-03-01 09:42:47.286281
56	fix-optimized-search-function	cb58526ebc23048049fd5bf2fd148d18b04a2073	2026-03-01 09:42:49.611583
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.vector_indexes (id, name, bucket_id, data_type, dimension, distance_metric, metadata_configuration, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: supabase_admin
--

COPY vault.secrets (id, name, description, secret, key_id, nonce, created_at, updated_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 14, true);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: supabase_admin
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

\unrestrict cuk4TqhH20QHuhEt7ahv2WM2dWoniMhAaAhZj9NeXE8IczoRfr4uYrZdEhN7VdR

