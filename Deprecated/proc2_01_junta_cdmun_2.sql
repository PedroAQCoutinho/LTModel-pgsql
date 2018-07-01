UPDATE lt_model.result a 
SET cd_mun_2006 = b.codmun7 
FROM pa_br_limitemunicipal_2006_ibge b JOIN data.municipio_ibge c ON b.codmun7 = c.cod_ibge
WHERE ST_Within(a.geom, b.geom) AND (b.codmun7 % :var_num_proc) = :var_proc AND a.ownership_class = 'PL';