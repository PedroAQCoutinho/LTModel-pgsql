SET search_path TO lt_model, public;

INSERT INTO proc1_02_car_result
SELECT c1.gid gid, 
	CASE COUNT(c2.gid) 
		WHEN 0 THEN 
			c1.geom
		WHEN 1 THEN
			CASE WHEN ST_Within(c1.geom, ST_GeometryN(ST_Collect(c2.geom), 1)) THEN
				NULL::geometry
			ELSE
				ST_Difference(c1.geom, ST_GeometryN(ST_Collect(c2.geom), 1))
			END
		ELSE
			ST_Safe_Difference(c1.geom, ST_Collect(c2.geom)) 
		END  geom, 
	c1.area_loss incra_area_loss
FROM proc1_01_car_sigef_union c1 
LEFT JOIN proc1_01_car_sigef_union c2 ON c1.gid != c2.gid AND ST_Intersects(c1.geom, c2.geom) AND NOT ST_Touches(c1.geom, c2.geom) AND NOT c2.fla_sigef
WHERE (c1.gid % :var_num_proc) = :var_proc AND NOT c1.fla_sigef 
GROUP BY c1.gid, c1.geom, c1.area_loss;