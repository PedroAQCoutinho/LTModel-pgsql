SET search_path TO lt_model, public;

INSERT INTO proc1_06_car_poor_clean_without_premium
SELECT gid, geom, shape_area, (area_previous-ST_Area(geom)) area_loss, incra_area_loss, fla_overlay_poor_premium
FROM (
SELECT poor.gid, 
	CASE WHEN ST_IsEmpty(poor.geom) THEN poor.geom ELSE 
	ST_CollectionExtract(
	CASE COUNT(premium.gid) 
	WHEN 0 THEN
		poor.geom
	WHEN 1 THEN
		CASE WHEN ST_Within(poor.geom, ST_GeometryN(ST_Collect(premium.geom), 1)) THEN ST_GeomFromText('Polygon Empty') ELSE
			ST_Difference(poor.geom, ST_GeometryN(ST_Collect(premium.geom), 1))
		END
	ELSE
		ST_Safe_Difference(poor.geom, ST_Collect(premium.geom))
	END, 3) END geom, 
ST_Area(poor.geom) area_previous, poor.shape_area, poor.incra_area_loss,
COUNT(premium.gid) > 0 fla_overlay_poor_premium
FROM proc1_04_car_poor_clean poor
LEFT JOIN proc1_05_car_premium_clean premium ON ST_Intersects(poor.geom, premium.geom) AND NOT ST_Touches(poor.geom, premium.geom)
WHERE (poor.gid % :var_num_proc) = :var_proc
GROUP BY poor.gid, poor.geom, poor.shape_area, poor.incra_area_loss) a;