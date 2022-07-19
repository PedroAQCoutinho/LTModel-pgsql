SET search_path TO recorte, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM recorte.log_outputs));


-- Log greater than or equal 50
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(
		CASE WHEN area IS NULL THEN 
			0 
		ELSE 
			area 
		END)
FROM log_operation operation
LEFT JOIN proc1_13_car_sigef b ON b.area_loss >= (SELECT param_value FROM recorte.params WHERE param_name = 'car_incra_tolerance') OR b.area_loss IS NULL
WHERE operation.nom_operation = 'car_sigef_gte_50'
GROUP BY operation.id;


-- Log less than 50
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(
		CASE WHEN area IS NULL THEN 
			0 
		ELSE 
			area 
		END)
FROM log_operation operation
LEFT JOIN proc1_13_car_sigef b ON b.area_loss < (SELECT param_value FROM recorte.params WHERE param_name = 'car_incra_tolerance')
WHERE operation.nom_operation = 'car_sigef_lt_50'
GROUP BY operation.id;