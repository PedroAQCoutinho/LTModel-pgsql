SET search_path TO lt_model, public;

INSERT INTO proc1_04_car_poor_clean
SELECT a.gid, 
	ST_CollectionExtract(ST_MakeValid(
	CASE COUNT(b.gid) 
	WHEN 0 THEN 
		a.geom 
	WHEN 1 THEN
		CASE WHEN ST_Within(a.geom, ST_GeometryN(ST_Collect(b.geom),1)) THEN null ELSE 
			ST_Difference(a.geom, ST_GeometryN(ST_Collect(b.geom),1))
		END
	ELSE
			ST_Safe_Difference(a.geom, ST_Collect(b.geom))
	END), 3) geom, 
	a.shape_area, 
	a.incra_area_loss
FROM proc1_03_is_premium a
LEFT JOIN proc1_03_z1_car_intersects c ON a.gid = c.gid
LEFT JOIN proc1_03_is_premium b ON b.gid = c.gid2 AND a.rnd > b.rnd AND NOT b.fla_car_premium
WHERE NOT a.fla_car_premium AND (a.gid % :var_num_proc) = :var_proc
GROUP BY a.gid, a.geom, a.shape_area, a.incra_area_loss;