SET search_path TO lt_model, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM recorte.log_outputs));

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(shape_area)
FROM log_operation operation,
proc1_00_0makevalid b
WHERE operation.nom_operation = 'car_valid' AND NOT b.is_valid
GROUP BY operation.id;

\echo `rm *.txt`;