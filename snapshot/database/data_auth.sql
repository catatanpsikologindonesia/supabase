--
-- PostgreSQL database dump
--

\restrict Zab5qCcZFmBw6dIewF1xye8I1aHqEe2r7Xj4Kbfqz3ZTAqNhQzpF8LiP2pumxmJ

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
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 14, true);


--
-- PostgreSQL database dump complete
--

\unrestrict Zab5qCcZFmBw6dIewF1xye8I1aHqEe2r7Xj4Kbfqz3ZTAqNhQzpF8LiP2pumxmJ

