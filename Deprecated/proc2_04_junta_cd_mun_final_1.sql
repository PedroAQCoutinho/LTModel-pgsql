DROP TABLE IF EXISTS recorte.proc3_02_mun3;
CREATE TABLE recorte.proc3_02_mun3 AS
SELECT DISTINCT ON (gid) gid, codmun7 
FROM recorte.proc3_01_mun2
ORDER BY gid, area DESC;


UPDATE recorte.result a
SET cd_mun_2006 = b.codmun7
FROM recorte.proc3_02_mun3 b
WHERE a.gid = b.gid;

VACUUM ANALYZE recorte.result;