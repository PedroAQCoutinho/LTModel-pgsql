SET search_path TO recorte, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM recorte.log_outputs));


--log poor self intersection
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(new_area)
FROM log_operation operation,
(SELECT DISTINCT ON (gid) * FROM recorte.proc1_03_z1_car_intersects  
) b
WHERE operation.nom_operation = 'car_poor_self_overlay' AND NOT b.fla_car_premium AND NOT b.fla_car_premium2
GROUP BY operation.id;


--log premium self intersection
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(new_area)
FROM log_operation operation,
(SELECT DISTINCT ON (gid) * FROM recorte.proc1_03_z1_car_intersects 
) b
WHERE operation.nom_operation = 'car_premium_self_overlay' AND b.fla_car_premium AND b.fla_car_premium2
GROUP BY operation.id;