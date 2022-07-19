SET search_path TO recorte, public;


INSERT INTO proc1_05_car_premium_clean
SELECT a.gid, 
	ST_CollectionExtract(
	CASE COUNT(B.gid) 
	WHEN 0 THEN 
		a.geom 
	WHEN 1 THEN 
		ST_Difference(a.geom, ST_GeometryN(ST_Collect(b.geom),1))
	ELSE 
		ST_Safe_Difference(a.geom, ST_Buffer(ST_Collect(b.geom),0.01)) 
	END, 3) geom, a.shape_area
FROM proc1_03_is_premium a
LEFT JOIN proc1_03_z1_car_intersects c ON c.gid = a.gid
LEFT JOIN proc1_03_is_premium b ON c.gid2 = b.gid 
AND (CASE (SELECT param_text param_priority FROM recorte.params WHERE param_name = 'priority_autointersection')
			WHEN 'S' THEN 
				b.shape_area < a.shape_area 
			WHEN 'L' THEN
				b.shape_area > a.shape_area
			ELSE
				b.rnd < a.rnd
		END)
AND b.fla_car_premium
WHERE a.fla_car_premium AND (a.gid % :var_num_proc) = :var_proc
GROUP BY a.gid, a.geom, a.shape_area;