SET search_path TO lt_model, public;

-- DROP VIEW IF EXISTS projetos_2017.malha_relatorio_01_car_bruto_eliminate;
DROP TABLE IF EXISTS proc1_03_is_premium;
CREATE TABLE proc1_03_is_premium
(
  gid bigint,
  geom geometry,
  shape_area double precision,
  shape_leng double precision,
  area_loss DOUBLE PRECISION,
  new_area double precision,
  fla_car_premium boolean,
  rnd double precision DEFAULT random()
);

CREATE INDEX gix_proc1_03_is_premium
  ON proc1_03_is_premium
  USING gist
  (geom);
CREATE INDEX ix_proc1_03_is_premium
  ON proc1_03_is_premium
  USING btree
  (gid);
CREATE INDEX ix_proc1_03_is_premium_2
  ON proc1_03_is_premium
  USING btree
  (fla_car_premium);
CREATE INDEX ix_proc1_03_is_premium_3
  ON proc1_03_is_premium
  USING btree
  (rnd);

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
WHERE NOT fla_sigef) c;
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