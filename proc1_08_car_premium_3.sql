SET search_path TO lt_model, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM lt_model.log_outputs));


-- log premium
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(shape_area)
FROM log_operation operation,
proc1_03_is_premium b
WHERE operation.nom_operation = 'car_premium' AND fla_car_premium
GROUP BY operation.id;

--log poor
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(shape_area)
FROM log_operation operation,
proc1_03_is_premium b
WHERE operation.nom_operation = 'car_poor' AND NOT fla_car_premium
GROUP BY operation.id;

\echo `rm var1.txt`
\echo `rm var2.txt` 
\echo `rm var3.txt` 
\echo `rm var7.txt` 
\echo `rm var8.txt` 
\echo `rm var9.txt` 
\echo `rm var10.txt` 
\echo `rm var11.txt` 
\echo `rm var12.txt` 