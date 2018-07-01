SET search_path TO lt_model, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM lt_model.log_outputs));

-- Delete features outside brazil boundary (Albers) (5)
DROP TABLE IF EXISTS proc1_00_1car_outside_br;
CREATE TABLE proc1_00_1car_outside_br AS
SELECT gid, ST_Area(geom) area FROM proc1_00_0makevalid 
WHERE NOT (ST_XMin(geom) > -2178085.86161649 AND (ST_YMin(geom)) > -2385741.85034503 AND (ST_XMax(geom)) < 2610329.15296495 AND (ST_YMax(geom)) < 1902805.48184162);


INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(area)
FROM log_operation operation,
proc1_00_1car_outside_br b
WHERE operation.nom_operation = 'car_outside_brazil'
GROUP BY operation.id;

DELETE
FROM proc1_00_0makevalid a
USING proc1_00_1car_outside_br b
WHERE a.gid = b.gid;