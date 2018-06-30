SET search_path TO lt_model, public;

INSERT INTO proc1_13_car_sigef (
	gid,
	area_loss,
	area,
	area_original,
	is_premium,
	geom
)
SELECT 
	gid, 
	CASE WHEN area_original = 0 THEN 
		0
	ELSE
		1.0-(ST_Area(geom)/area_original) 
	END area_loss,
	ST_Area(geom) area, 
	area_original, 
	is_premium,
	geom
	 FROM (
SELECT 
	a.gid, 
	a.area_loss,
	a.area, 
	a.area_original, 
	a.is_premium, 
	ST_CollectionExtract(ST_MakeValid(CASE COUNT(b.rid)
	WHEN 0 THEN 
		a.geom 
	WHEN 1 THEN
		ST_Difference(a.geom, ST_GeometryN(ST_Collect(b.geom), 1))
	ELSE
		ST_Safe_Difference(a.geom, ST_Collect(b.geom))
	END), 3) geom
FROM lt_model.proc1_12_car_cleaned a
LEFT JOIN lt_model.lt_model_incra_pr b ON ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom) 
	--AND ST_XMax(b.geom) < 658294.02429628 AND ST_XMin(b.geom) > 542810.3515331885 AND ST_YMax(b.geom) < -1077895.2638318148 AND ST_YMin(b.geom) > -1179502.5469183084
WHERE (a.gid % :var_num_proc) = :var_proc
GROUP BY a.gid, a.area_loss, a.area, a.area_original, a.is_premium, a.geom) c;