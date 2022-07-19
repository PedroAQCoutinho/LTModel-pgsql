SET search_path TO lt_model, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM recorte.log_outputs));


INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(b.gid),
	SUM(CASE WHEN area_loss IS NULL THEN 0 ELSE area_loss END)
FROM log_operation operation
LEFT JOIN proc1_06_car_poor_clean_without_premium b ON b.fla_overlay_poor_premium
WHERE operation.nom_operation = 'car_poor_premium_overlay'
GROUP BY operation.id;
