ALTER TABLE lt_model.result
ADD COLUMN IF NOT EXISTS cd_mun INTEGER,
ADD COLUMN IF NOT EXISTS cd_mun_contain BOOLEAN,
DROP COLUMN cd_mun_2006;

UPDATE lt_model.result a
SET cd_mun = b.cd_mun,
cd_mun_contain = b.cd_mun_contain
FROM lt_model.result_cdmun b
WHERE a.gid = b.gid AND a.geom IS NOT NULL;

\echo `rm var4.txt`