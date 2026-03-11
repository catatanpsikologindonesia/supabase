--
-- PostgreSQL database dump
--

\restrict Pp48IDpye5PLifpUdGo0m9y5dSIKGFkRDyJi3m0R5WBNYUVUBlyqxNWlW9IJm5a

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
-- PostgreSQL database dump complete
--

\unrestrict Pp48IDpye5PLifpUdGo0m9y5dSIKGFkRDyJi3m0R5WBNYUVUBlyqxNWlW9IJm5a

