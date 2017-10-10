SET search_path TO lt_model, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM lt_model.log_outputs));


DROP TABLE IF EXISTS proc1_00_3car_same_car;
CREATE TABLE proc1_00_3car_same_car AS
SELECT DISTINCT ON (a.cod_imovel) a.*
FROM proc1_00_0makevalid a 
JOIN proc1_00_0makevalid b ON a.gid <> b.gid AND a.cod_imovel = b.cod_imovel
ORDER BY a.cod_imovel, a.shape_area DESC;


WITH deleted AS
(DELETE FROM proc1_00_0makevalid a
USING proc1_00_3car_same_car b
WHERE b.gid <> a.gid AND b.cod_imovel = a.cod_imovel
RETURNING a.*)
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
SELECT currval('seq_current_run'),
	operation.id,
	COUNT(gid),
	SUM(
		CASE WHEN shape_area IS NULL THEN 
			0 
		ELSE 
			shape_area 
		END)
FROM log_operation operation
LEFT JOIN deleted b ON true
WHERE operation.nom_operation = 'car_same_num_car'
GROUP BY operation.id;