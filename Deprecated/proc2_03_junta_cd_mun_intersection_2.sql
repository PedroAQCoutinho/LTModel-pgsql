INSERT INTO recorte.proc3_01_mun2 
SELECT a.gid, a.codmun7, ST_Area(ST_Intersection(ST_CollectionExtract(ST_MakeValid(b.geom), 3), ST_CollectionExtract(ST_MakeValid(c.geom), 3))) area 
FROM recorte.proc2_00_lo_mun a 
JOIN public.pa_br_limitemunicipal_2006_ibge b ON a.codmun7 = b.codmun7 JOIN recorte.result c ON c.cd_mun_2006 IS NULL AND a.gid = c.gid 
WHERE (b.codmun7 % :var_num_proc) = :var_proc;