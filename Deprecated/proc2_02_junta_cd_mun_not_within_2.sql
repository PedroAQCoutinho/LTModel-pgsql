INSERT INTO recorte.proc2_00_lo_mun 
SELECT a.gid, b.codmun7 
FROM recorte.result a 
    JOIN pa_br_limitemunicipal_2006_ibge b ON ST_Intersects(a.geom, b.geom) 
WHERE a.cd_mun_2006 IS NULL AND (b.codmun7 % :var_num_proc) = :var_proc AND a.ownership_class = 'PL';