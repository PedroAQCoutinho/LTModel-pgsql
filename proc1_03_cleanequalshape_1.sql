SET search_path TO lt_model, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM recorte.log_outputs));

DROP TABLE IF EXISTS proc1_00_2car_equal_shape;
CREATE TABLE proc1_00_2car_equal_shape AS
SELECT a.gid, a.shape_area area
FROM proc1_00_0makevalid a
JOIN proc1_00_0makevalid b ON a.gid > b.gid AND a.shape_area = b.shape_area AND a.shape_leng = b.shape_leng AND ST_Equals(a.geom, b.geom);

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(area)
FROM log_operation operation,
proc1_00_2car_equal_shape b
WHERE operation.nom_operation = 'car_same_shape'
GROUP BY operation.id;

DELETE FROM proc1_00_0makevalid a 
USING proc1_00_2car_equal_shape b 
WHERE a.gid = b.gid;