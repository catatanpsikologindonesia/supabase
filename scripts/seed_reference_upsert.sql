INSERT INTO public.religion (name, order_index)
SELECT *
FROM (
  VALUES
    ('Islam', 1),
    ('Kristen Protestan', 2),
    ('Katolik', 3),
    ('Hindu', 4),
    ('Buddha', 5),
    ('Konghucu', 6),
    ('Lainnya', 7)
) AS seed(name, order_index)
ON CONFLICT DO NOTHING;

INSERT INTO public.education (name, order_index)
SELECT *
FROM (
  VALUES
    ('Belum Sekolah', 1),
    ('TK A', 2),
    ('TK B', 3),
    ('SD', 4),
    ('SMP', 5),
    ('SMA/SMK', 6),
    ('D1', 7),
    ('D2', 8),
    ('D3', 9),
    ('S1', 10),
    ('S2', 11),
    ('S3', 12),
    ('Lainnya', 13)
) AS seed(name, order_index)
ON CONFLICT DO NOTHING;

INSERT INTO public.occupation (name, order_index)
SELECT *
FROM (
  VALUES
    ('Pelajar/Mahasiswa', 1),
    ('Karyawan Swasta', 2),
    ('Pegawai Negeri Sipil (PNS)', 3),
    ('Wiraswasta', 4),
    ('Ibu Rumah Tangga', 5),
    ('Tidak Bekerja', 6),
    ('Lainnya', 7)
) AS seed(name, order_index)
ON CONFLICT DO NOTHING;

INSERT INTO public.marital_status (name, order_index)
SELECT *
FROM (
  VALUES
    ('Belum Menikah', 1),
    ('Menikah', 2),
    ('Cerai Hidup', 3),
    ('Cerai Mati', 4),
    ('Lainnya', 5)
) AS seed(name, order_index)
ON CONFLICT DO NOTHING;
