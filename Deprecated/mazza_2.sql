INSERT INTO projetos_2017.mazza_01_car_intersections
SELECT a.*, ST_Area(a.geom)/10000 area_ha2, CASE COUNT(b.gid) WHEN 0 THEN 0 ELSE 100*(ST_Area(a.geom)-ST_Area(ST_Safe_Difference(a.geom, ST_Collect(b.geom))))/ST_Area(a.geom) END perc_intersect, COUNT(b.gid) count
FROM lt_model.proc1_00_0makevalid a
LEFT JOIN lt_model.proc1_00_0makevalid b 
	ON a.gid != b.gid AND ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom)
WHERE (a.gid % :var_num_proc) = :var_proc
GROUP BY a.gid, a.cod_imovel, a.shape_area, a.shape_leng, a.geom, a.is_valid;