DROP TABLE IF EXISTS lt_model.proc3_02_mun3;
CREATE TABLE lt_model.proc3_02_mun3 AS
SELECT DISTINCT ON (gid) gid, codmun7 
FROM lt_model.proc3_01_mun2
ORDER BY gid, area DESC;


UPDATE lt_model.result a
SET cd_mun_2006 = b.codmun7
FROM lt_model.proc3_02_mun3 b
WHERE a.gid = b.gid;

VACUUM ANALYZE lt_model.result;