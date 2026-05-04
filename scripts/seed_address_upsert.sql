SET session_replication_role = replica;

UPDATE public.demo_requests
  SET province_id = NULL,
      city_id = NULL,
      district_id = NULL,
      subdistrict_id = NULL,
      postal_code_id = NULL;

DELETE FROM public.address_postal_code;
DELETE FROM public.address_subdistrict;
DELETE FROM public.address_district;
DELETE FROM public.address_city;
DELETE FROM public.address_province;

INSERT INTO public.address_province (prov_id, prov_name)
SELECT CAST(kode AS integer), nama
FROM _staging_wilayah
WHERE LENGTH(kode) = 2
ORDER BY kode;

INSERT INTO public.address_city (city_id, city_name, prov_id)
SELECT
  CAST(REPLACE(kode, '.', '') AS integer),
  nama,
  CAST(SPLIT_PART(kode, '.', 1) AS integer)
FROM _staging_wilayah
WHERE LENGTH(kode) = 5
ORDER BY kode;

INSERT INTO public.address_district (dis_id, dis_name, city_id)
SELECT
  CAST(REPLACE(kode, '.', '') AS integer),
  nama,
  CAST(REPLACE(SPLIT_PART(kode, '.', 1) || '.' || SPLIT_PART(kode, '.', 2), '.', '') AS integer)
FROM _staging_wilayah
WHERE LENGTH(kode) = 8
ORDER BY kode;

WITH numbered AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY kode)::integer AS subdis_id,
    nama AS subdis_name,
    CAST(REPLACE(SPLIT_PART(kode, '.', 1) || '.' || SPLIT_PART(kode, '.', 2) || '.' || SPLIT_PART(kode, '.', 3), '.', '') AS integer) AS dis_id,
    kode
  FROM _staging_wilayah
  WHERE LENGTH(kode) = 13
)
INSERT INTO public.address_subdistrict (subdis_id, subdis_name, dis_id)
SELECT subdis_id, subdis_name, dis_id
FROM numbered
ORDER BY kode;

WITH subdis_map AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY kode)::integer AS subdis_id,
    kode AS subdis_kode,
    CAST(REPLACE(SPLIT_PART(kode, '.', 1) || '.' || SPLIT_PART(kode, '.', 2) || '.' || SPLIT_PART(kode, '.', 3), '.', '') AS integer) AS dis_id,
    CAST(REPLACE(SPLIT_PART(kode, '.', 1) || '.' || SPLIT_PART(kode, '.', 2), '.', '') AS integer) AS city_id,
    CAST(SPLIT_PART(kode, '.', 1) AS integer) AS prov_id
  FROM _staging_wilayah
  WHERE LENGTH(kode) = 13
), postal_ranked AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY k.kode)::integer AS postal_id,
    k.kodepos AS postal_code,
    sm.subdis_id,
    sm.dis_id,
    sm.city_id,
    sm.prov_id
  FROM _staging_kodepos k
  JOIN subdis_map sm ON sm.subdis_kode = k.kode
)
INSERT INTO public.address_postal_code (postal_id, postal_code, subdis_id, dis_id, city_id, prov_id)
SELECT postal_id, postal_code, subdis_id, dis_id, city_id, prov_id
FROM postal_ranked
ORDER BY postal_id;

SET session_replication_role = DEFAULT;

SELECT tbl, cnt FROM (
  SELECT 'address_province' AS tbl, COUNT(*)::integer AS cnt FROM address_province UNION ALL
  SELECT 'address_city', COUNT(*) FROM address_city UNION ALL
  SELECT 'address_district', COUNT(*) FROM address_district UNION ALL
  SELECT 'address_subdistrict', COUNT(*) FROM address_subdistrict UNION ALL
  SELECT 'address_postal_code', COUNT(*) FROM address_postal_code
) t ORDER BY tbl;
