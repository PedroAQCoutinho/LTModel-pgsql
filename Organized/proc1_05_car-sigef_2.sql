SET search_path TO lt_model, public;

INSERT INTO proc1_00_car_sigef
SELECT *, 1.0-(ST_Area(intersection_geom)/shape_area) area_loss FROM (
SELECT 
	a.gid car, 
	a.geom car_geom, 
	CASE WHEN COUNT(b.gid) = 1 THEN 
		CASE WHEN ST_Within(a.geom, ST_GeometryN(ST_Collect(b.geom), 1)) THEN 
			ST_GeomFromText('Polygon Empty')
		ELSE 
			ST_Difference(a.geom, ST_GeometryN(ST_Collect(b.geom), 1)) 
		END 
	WHEN COUNT(b.gid) > 1 THEN 
		ST_Safe_Difference(a.geom, ST_Collect(b.geom)) 
	ELSE 
		a.geom 
	END intersection_geom, 
	a.shape_area, 
	MAX(ST_Area(b.geom)) sigef_area, 
	a.shape_leng
FROM proc1_00_0makevalid a
LEFT JOIN lt_model.lt_model_incra_pr b ON ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom) 
	--AND ST_XMax(b.geom) < 658294.02429628 AND ST_XMin(b.geom) > 542810.3515331885 AND ST_YMax(b.geom) < -1077895.2638318148 AND ST_YMin(b.geom) > -1179502.5469183084
WHERE (a.gid % :var_num_proc) = :var_proc
GROUP BY a.gid, a.geom, a.shape_area, a.shape_leng) c;