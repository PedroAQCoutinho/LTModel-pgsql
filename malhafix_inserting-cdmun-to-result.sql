ALTER TABLE lt_model.:ltenure
ADD COLUMN cd_mun INTEGER,
ADD COLUMN cd_mun_contain BOOLEAN;

UPDATE lt_model.:ltenure a
SET cd_mun = b.cd_mun,
cd_mun_contain = b.cd_mun_contain
FROM lt_model.:ltenure_cdmun b
WHERE a.gid = b.gid;