SET search_path TO recorte, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM recorte.log_outputs));


DROP TABLE IF EXISTS proc1_07_car_solved;
CREATE TABLE proc1_07_car_solved AS
SELECT *, true is_premium 
FROM proc1_05_car_premium_clean
UNION ALL
SELECT gid, geom, shape_area, false
FROM proc1_06_car_poor_clean_without_premium;


ALTER TABLE proc1_07_car_solved
ADD COLUMN is_single BOOLEAN DEFAULT false;

UPDATE proc1_07_car_solved
SET is_single = ST_GeometryType(geom) = 'ST_Polygon';

ALTER TABLE proc1_07_car_solved
ADD COLUMN new_area NUMERIC(30,2);

UPDATE proc1_07_car_solved
SET new_area = ST_Area(geom);

-- Get only CAR poor -- 0.5s
DROP TABLE IF EXISTS proc1_08_car_poor_no_overlay;
CREATE TABLE proc1_08_car_poor_no_overlay AS
SELECT * 
FROM proc1_07_car_solved
WHERE NOT is_premium;


-- Log CAR poor multipolygon
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(b.gid),
	SUM(CASE WHEN new_area IS NULL THEN 0 ELSE new_area END)
FROM log_operation operation 
LEFT JOIN proc1_08_car_poor_no_overlay b ON NOT b.is_premium AND NOT b.is_single
WHERE operation.nom_operation = 'car_poor_multipolygon'
GROUP BY operation.id;


-- Multi to single, calculate area and perimeter - 2.3
DROP TABLE IF EXISTS proc1_09_car_single;
CREATE TABLE proc1_09_car_single AS
SELECT rid, gid, area_original, false fla_eliminate, 1-(area/area_original) area_loss, area, perimeter, CASE WHEN perimeter = 0 THEN 0 ELSE (2*SQRT(PI() * area))/perimeter END ci, lt_model.ST_MakeValidSnapping(geom) geom
FROM (
	SELECT row_number() OVER () rid, gid, area_original, ST_Area(geom) area, ST_Perimeter(geom) perimeter, geom
	FROM (
		SELECT gid, shape_area area_original, (ST_Dump(geom)).geom
		FROM proc1_08_car_poor_no_overlay
		) A)
	B;

	

--Calculating area loss
UPDATE proc1_09_car_single
SET fla_eliminate =  true
FROM (SELECT param_value param_area FROM recorte.params WHERE param_name = 'car_area_loss_tolerance') A,
(SELECT param_value param_ci FROM recorte.params WHERE param_name = 'car_ci_minimum') B
WHERE 
	area_loss > param_area OR
	ci < param_ci;


--Log CAR poor consolidated and to join
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(b.gid),
	SUM(area)
FROM log_operation operation,
proc1_09_car_single b
WHERE operation.nom_operation = 'car_poor_consolidated' AND NOT b.fla_eliminate
GROUP BY operation.id;

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(b.gid),
	SUM(area)
FROM log_operation operation,
proc1_09_car_single b
WHERE operation.nom_operation = 'car_poor_to_join' AND b.fla_eliminate
GROUP BY operation.id;


-- ELIMINATE
-- Create temporary copy of CAR to be consolidated
DROP TABLE IF EXISTS proc1_11_temp_car_consolidated;
CREATE TABLE proc1_11_temp_car_consolidated AS
SELECT 
rid, 
gid,
area_original,
fla_eliminate,
area_loss,
area,
perimeter,
ci,
geom geom, 
false fla_multipolygon FROM proc1_09_car_single WHERE NOT fla_eliminate;

DROP TABLE IF EXISTS temp_already_process CASCADE;
CREATE TEMP TABLE temp_already_process(small INT);

SELECT lt_model.eliminate_car();

DO $$
BEGIN
WHILE (SELECT lt_model.eliminate_car_recursive()) > 0 LOOP
END LOOP;
END $$;


ALTER TABLE proc1_11_temp_car_consolidated 
ADD COLUMN is_premium BOOLEAN DEFAULT FALSE;

DROP TABLE IF EXISTS recorte.proc1_12_car_cleaned;
CREATE TABLE recorte.proc1_12_car_cleaned AS
SELECT gid, 1.0-(ST_Area(geom)/area_original) area_loss, ST_Area(geom) area, area_original, ST_Perimeter(geom) perimeter, false is_premium, geom 
FROM (
	SELECT gid, area_original, ST_CollectionExtract(ST_MakeValid(ST_Collect(geom)), 3) geom
	FROM proc1_11_temp_car_consolidated
	GROUP BY gid, area_original
) a;

INSERT INTO recorte.proc1_12_car_cleaned
SELECT gid, 1-(ST_Area(geom)/shape_area) area_loss, ST_Area(geom) area, shape_area area_original, ST_Perimeter(geom) perimeter, is_premium, geom
FROM (SELECT gid, ST_CollectionExtract(ST_MakeValid(geom),3) geom, shape_area, is_premium FROM recorte.proc1_07_car_solved
WHERE is_premium) a;

UPDATE recorte.proc1_12_car_cleaned
SET area_original = area, area_loss = 0
WHERE area_loss < 0;

CREATE INDEX gix_proc1_12_car_cleaned
ON recorte.proc1_12_car_cleaned
USING GIST (geom);

SELECT clock_timestamp()-current_timestamp;
