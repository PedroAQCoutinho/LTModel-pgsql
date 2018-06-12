SET search_path TO lt_model, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM lt_model.log_outputs));


-- Log greater than or equal 50
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(
		CASE WHEN shape_area IS NULL THEN 
			0 
		ELSE 
			shape_area 
		END)
FROM log_operation operation
LEFT JOIN proc1_00_car_sigef b ON b.area_loss >= 0.5 OR b.area_loss IS NULL
WHERE operation.nom_operation = 'car_sigef_gte_50'
GROUP BY operation.id;


-- Log less than 50
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(
		CASE WHEN shape_area IS NULL THEN 
			0 
		ELSE 
			shape_area 
		END)
FROM log_operation operation
LEFT JOIN proc1_00_car_sigef b ON b.area_loss < 0.5
WHERE operation.nom_operation = 'car_sigef_lt_50'
GROUP BY operation.id;