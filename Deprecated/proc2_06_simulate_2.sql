INSERT INTO recorte.proc3_03_simulate 
SELECT a.codmun7 cd_mun, ST_Safe_Difference_Simulate(a.geom, ST_Collect(b.geom)) geom 
FROM pa_br_limitemunicipal_2006_ibge a 
LEFT JOIN recorte.result2 b ON ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom) 
WHERE (a.codmun7 % :var_num_proc) = :var_proc
GROUP BY a.codmun7, a.geom;