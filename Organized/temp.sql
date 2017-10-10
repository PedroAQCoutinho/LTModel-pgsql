INSERT INTO lt_model.result_temp 
SELECT a.gid, ST_Intersection(a.geom, b.geom)
FROM lt_model.result a
-- USING 
,
public.pa_br_limitenacional_2015_ibge_albers b 
WHERE sub_class = 'AG' AND (a.gid % 15) = :var_proc AND NOT ST_Within(a.geom, b.geom)