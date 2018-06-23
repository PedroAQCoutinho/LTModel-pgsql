SET search_path TO lt_model, public;

DO $$
DECLARE var_car_premium_tolerance INT = (SELECT param_value FROM lt_model.params WHERE param_name = 'car_premium_tolerance');
BEGIN
INSERT INTO proc1_03_is_premium 
(
  gid,
  geom,
  shape_area,
  shape_leng,
  area_loss,
  new_area,
  fla_car_premium
)
SELECT 
  gid, 
  geom,
  shape_area,
  shape_leng,
  shape_area-new_area area_loss,
  new_area,
	CASE WHEN new_area IS NULL THEN 
		false 
	ELSE 
		(new_area/shape_area) >= var_car_premium_tolerance 
	END fla_car_premium
FROM (
SELECT a.*, ST_Area(ST_CollectionExtract(b.geom,3)) new_area
FROM proc1_00_0makevalid a
LEFT JOIN proc1_02_car_result b ON a.gid = b.gid
WHERE (a.gid % :var_num_proc) = :var_proc) c;
END $$;



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