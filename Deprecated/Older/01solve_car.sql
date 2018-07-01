SELECT clock_timestamp();

-- CAR SOLVING
SET search_path TO lt_model, public;

SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM lt_model.log_outputs));
-- SELECT nextval('seq_current_run');


-- Copy original table
DROP TABLE IF EXISTS temp_car_1;
CREATE TEMP TABLE temp_car_1 AS
SELECT 
	a.gid, 
	cod_imovel cod_imovel, 
	ST_Area(geom) shape_area, 
	ST_Perimeter(geom) shape_leng, 
	ST_Buffer(ST_CollectionExtract(ST_MakeValid(geom), 3), 0) geom,
	ST_IsValid(geom) is_valid
FROM :car_table a;
--WHERE ST_XMax(a.geom) < 658294.02429628 AND ST_XMin(a.geom) > 542810.3515331885 AND ST_YMax(a.geom) < -1077895.2638318148 AND ST_YMin(a.geom) > -1179502.5469183084;

-- Validates geometry
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(shape_area)
FROM log_operation operation,
temp_car_1 b
WHERE operation.nom_operation = 'car_valid' AND NOT b.is_valid
GROUP BY operation.id;


-- Create indexes 1m06s
--DROP INDEX ix_temp_car_1_1;
CREATE INDEX ix_temp_car_1_1 ON temp_car_1 USING BTREE (shape_area, shape_leng);
CREATE INDEX ix_temp_car_1_2 ON temp_car_1 USING GIST (geom);
CREATE INDEX ix_temp_car_1_3 ON temp_car_1 USING BTREE ((ST_XMin(geom)), (ST_YMin(geom)), (ST_XMax(geom)), (ST_YMax(geom))); --13.7s


-- Delete features outside brazil boundary (Albers) (5)
DROP TABLE IF EXISTS car_outside_br;
CREATE TEMP TABLE car_outside_br AS
SELECT gid, ST_Area(geom) area FROM temp_car_1 
WHERE NOT (ST_XMin(geom) > -2178085.86161649 AND (ST_YMin(geom)) > -2385741.85034503 AND (ST_XMax(geom)) < 2610329.15296495 AND (ST_YMax(geom)) < 1902805.48184162);


INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(area)
FROM log_operation operation,
car_outside_br b
WHERE operation.nom_operation = 'car_outside_brazil'
GROUP BY operation.id;

DELETE
FROM temp_car_1 a
USING car_outside_br b
WHERE a.gid = b.gid;

-- View duplicate
-- CREATE TABLE temp_car_equal_pol AS
-- SELECT a.*, CASE WHEN a.gid > b.gid THEN 1 ELSE 2 END which
-- FROM temp_car_1 a 
-- JOIN temp_car_1 b ON a.gid <> b.gid AND a.shape_area = b.shape_area AND a.shape_leng = b.shape_leng AND ST_Equals(a.geom, b.geom);

-- Clean equal shapes (56)
DROP TABLE IF EXISTS car_equal_shape;
CREATE TEMP TABLE car_equal_shape AS
SELECT a.gid, a.shape_area area
FROM temp_car_1 a
JOIN temp_car_1 b ON a.gid > b.gid AND a.shape_area = b.shape_area AND a.shape_leng = b.shape_leng AND ST_Equals(a.geom, b.geom);

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(area)
FROM log_operation operation,
car_equal_shape b
WHERE operation.nom_operation = 'car_same_shape'
GROUP BY operation.id;

DELETE FROM temp_car_1 a 
USING car_equal_shape b 
WHERE a.gid = b.gid;

-- View duplicated CAR number
-- SELECT a.*, b.gid gid2 FROM temp_car_1 a
-- , temp_car_1 b
-- WHERE a.gid > b.gid AND a.cod_imovel = b.cod_imovel;


-- Clean equal CAR number keeping largest area (0) 
CREATE INDEX ix_temp_car_1_4 ON temp_car_1 USING BTREE (gid, cod_imovel);


DROP TABLE IF EXISTS temp_car_2;
CREATE  TEMP TABLE temp_car_2 AS
SELECT DISTINCT ON (a.cod_imovel) a.*
FROM temp_car_1 a 
JOIN temp_car_1 b ON a.gid <> b.gid AND a.cod_imovel = b.cod_imovel
ORDER BY a.cod_imovel, a.shape_area DESC;


WITH deleted AS
(DELETE FROM temp_car_1 a
USING temp_car_2 b
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


DROP TABLE IF EXISTS temp_car_3;
CREATE TEMP TABLE temp_car_3 AS
SELECT *, (2*SQRT(PI()*shape_area))/shape_leng ci
FROM temp_car_1;

CREATE INDEX ix_temp_car_3_1 ON temp_car_3 USING BTREE (ci);
CREATE INDEX ix_temp_car_3_2 ON temp_car_3 USING BTREE (shape_area); 
CREATE INDEX ix_temp_car_3_3 ON temp_car_3 USING BTREE (gid);
CREATE INDEX gix_temp_car_3 ON temp_car_3 USING GIST (geom); 

-- Clean CI below 0.12
-- DELETE FROM temp_car_3
-- WHERE ci <= 0.12;

-- SIGEF OVERLAYING
CREATE INDEX IF NOT EXISTS gix_lt_model_incra_pr ON lt_model.lt_model_incra_pr USING GIST (geom);



-- Sigef union (CAR -  SiGEF)
DROP TABLE IF EXISTS proc1_00_car_sigef;
CREATE TABLE proc1_00_car_sigef AS
SELECT *, 1.0-(ST_Area(intersection_geom)/shape_area) area_loss FROM (
SELECT 
	a.gid car, 
	a.geom car_geom, 
	CASE WHEN COUNT(b.gid) = 1 THEN 
		CASE WHEN ST_Within(a.geom, ST_GeometryN(ST_Collect(b.geom), 1)) THEN 
			NULL::geometry 
		ELSE 
			ST_Difference(a.geom, ST_GeometryN(ST_Collect(b.geom), 1)) 
		END 
	WHEN COUNT(b.gid) > 1 THEN 
		ST_CollectionExtract(ST_Difference(a.geom, ST_Buffer(ST_Collect(b.geom), -0.01)), 3) 
	ELSE 
		a.geom 
	END intersection_geom, 
	a.shape_area, 
	MAX(ST_Area(b.geom)) sigef_area, 
	a.shape_leng
FROM temp_car_3 a
LEFT JOIN lt_model.lt_model_incra_pr b ON ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom) 
	--AND ST_XMax(b.geom) < 658294.02429628 AND ST_XMin(b.geom) > 542810.3515331885 AND ST_YMax(b.geom) < -1077895.2638318148 AND ST_YMin(b.geom) > -1179502.5469183084
GROUP BY a.gid, a.geom, a.shape_area, a.shape_leng) c;



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


DROP TABLE IF EXISTS proc1_01_car_sigef_union;
CREATE TABLE proc1_01_car_sigef_union AS
SELECT gid, ST_Multi(geom) geom, ST_Area(geom) shape_area, ST_Perimeter(geom) shape_leng, 0 area_loss, true fla_sigef
FROM lt_model.lt_model_incra_pr
--WHERE ST_XMax(geom) < 658294.02429628 AND ST_XMin(geom) > 542810.3515331885 AND ST_YMax(geom) < -1077895.2638318148 AND ST_YMin(geom) > -1179502.5469183084
;

INSERT INTO proc1_01_car_sigef_union
SELECT car, ST_Multi(car_geom) geom, shape_area, shape_leng, 0 area_loss, false fla_sigef
FROM proc1_00_car_sigef
WHERE area_loss IS NULL OR area_loss <= 0;

-- Add CAR that lost less than 50% of its area
INSERT INTO proc1_01_car_sigef_union
SELECT car, ST_Multi(intersection_geom) geom, shape_area, shape_leng, area_loss*shape_area area_loss, false fla_sigef
FROM proc1_00_car_sigef
WHERE area_loss <= 0.5 AND area_loss > 0;

CREATE INDEX gix_proc1_01_car_sigef_union ON proc1_01_car_sigef_union USING GIST (geom);
CREATE INDEX ix_proc1_01_car_sigef_union ON proc1_01_car_sigef_union USING BTREE (gid);


-- SELF OVERLAYING IN CAR
-- All differences from CAR - CAR for checking 5% overlay -- 52m52s
DROP TABLE IF EXISTS proc1_02_car_result;
CREATE TABLE proc1_02_car_result AS --
SELECT c1.gid gid, 
	CASE COUNT(c2.gid) 
		WHEN 0 THEN 
			c1.geom
		WHEN 1 THEN
			CASE WHEN ST_Within(c1.geom, ST_GeometryN(ST_Collect(c2.geom), 1)) THEN
				NULL::geometry
			ELSE
				ST_Difference(c1.geom, ST_GeometryN(ST_Collect(c2.geom), 1))
			END
		ELSE
			ST_CollectionExtract(ST_Difference(c1.geom, ST_Buffer(ST_Collect(c2.geom), 0.01)), 3) 
		END  geom, 
	c1.area_loss incra_area_loss
FROM proc1_01_car_sigef_union c1 
LEFT JOIN proc1_01_car_sigef_union c2 ON c1.gid != c2.gid AND ST_Intersects(c1.geom, c2.geom) AND NOT ST_Touches(c1.geom, c2.geom) AND NOT c2.fla_sigef
WHERE NOT c1.fla_sigef 
GROUP BY c1.gid, c1.geom, c1.area_loss;

-- 8.6s
DROP TABLE IF EXISTS proc1_03_is_premium;
CREATE TABLE proc1_03_is_premium AS
SELECT *, 
	CASE WHEN new_area IS NULL THEN 
		false 
	ELSE 
		(new_area/shape_area) >= 0.95 
	END fla_car_premium
FROM (
SELECT a.*, ST_Area(ST_CollectionExtract(b.geom,3)) new_area, b.incra_area_loss
FROM proc1_01_car_sigef_union a
LEFT JOIN proc1_02_car_result b ON a.gid = b.gid
WHERE NOT fla_sigef) c;

CREATE INDEX ix_proc1_03_is_premium ON proc1_03_is_premium USING BTREE (gid);
CREATE INDEX ix_proc1_03_is_premium_2 ON proc1_03_is_premium USING BTREE (fla_car_premium);
CREATE INDEX gix_proc1_03_is_premium ON proc1_03_is_premium USING GIST (geom);


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

--log not poor
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(shape_area)
FROM log_operation operation,
proc1_03_is_premium b
WHERE operation.nom_operation = 'car_poor' AND NOT fla_car_premium
GROUP BY operation.id;


-- CREATE TABLE of everything that intersects -- 11m29s
INSERT INTO lt_model.proc1_03_z1_car_intersects AS
SELECT a.gid, b.gid gid2, a.fla_car_premium, b.fla_car_premium fla_car_premium2, a.new_area, a.incra_area_loss
FROM proc1_03_is_premium a
JOIN proc1_03_is_premium b ON a.gid <> b.gid AND ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom)
WHERE (gid % 15) = :var_proc;

CREATE INDEX IF NOT EXISTS  ix_car_intersects ON lt_model.proc1_03_z1_car_intersects USING BTREE (gid, gid2);

--log poor self intersection
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(new_area)
FROM log_operation operation,
(SELECT DISTINCT ON (gid) * FROM lt_model.proc1_03_z1_car_intersects  
) b
WHERE operation.nom_operation = 'car_poor_self_overlay' AND NOT b.fla_car_premium AND NOT b.fla_car_premium2
GROUP BY operation.id;


--log premium self intersection
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(new_area)
FROM log_operation operation,
(SELECT DISTINCT ON (gid) * FROM lt_model.proc1_03_z1_car_intersects 
) b
WHERE operation.nom_operation = 'car_premium_self_overlay' AND b.fla_car_premium AND b.fla_car_premium2
GROUP BY operation.id;

-- Clean CAR_poor with self overlay priority to small
-- DROP TABLE IF EXISTS proc1_04_car_poor_clean;
-- CREATE TEMP TABLE proc1_04_car_poor_clean AS
-- SELECT a.gid, CASE WHEN MAX(b.gid) IS NULL THEN a.geom ELSE ST_Difference(a.geom, ST_Buffer(ST_Collect(b.geom),0.01)) END geom, a.shape_area, a.incra_area_loss
-- FROM car_intersects c
-- JOIN proc1_03_is_premium a ON c.gid = a.gid
-- LEFT JOIN proc1_03_is_premium b ON c.gid2 = b.gid AND a.shape_area > b.shape_area AND NOT c.fla_car_premium2
-- WHERE NOT c.fla_car_premium 
-- GROUP BY a.gid, a.geom, a.shape_area, a.incra_area_loss;

-- Create random column -- 6.4s
ALTER TABLE proc1_03_is_premium
DROP COLUMN IF EXISTS rnd;
ALTER TABLE proc1_03_is_premium
ADD COLUMN rnd DOUBLE PRECISION DEFAULT random();

CREATE INDEX ix_proc1_03_is_premium_3 ON proc1_03_is_premium USING BTREE (rnd);


-- Clean CAR_poor with self overlay random priority -- 1m58s
DROP TABLE IF EXISTS proc1_04_car_poor_clean;
CREATE TABLE proc1_04_car_poor_clean (
	gid INTEGER,
	geom geometry,
	shape_area NUMERIC,
	incra_area_loss NUMERIC
)


INSERT INTO proc1_04_car_poor_clean
SELECT a.gid, 
	ST_CollectionExtract(
	CASE COUNT(b.gid) 
	WHEN 0 THEN 
		a.geom 
	WHEN 1 THEN
		ST_Difference(a.geom, ST_GeometryN(ST_Collect(b.geom),1)) 
	ELSE 
		ST_Difference(a.geom, ST_Buffer(ST_Union(b.geom), 0)) 
	END, 3) geom, 
	a.shape_area, 
	a.incra_area_loss
FROM proc1_03_is_premium a
LEFT JOIN proc1_03_z1_car_intersects c ON a.gid = c.gid
LEFT JOIN proc1_03_is_premium b ON b.gid = c.gid2 AND a.rnd > b.rnd AND NOT b.fla_car_premium
WHERE NOT a.fla_car_premium AND (a.gid % 15) = :var_proc
GROUP BY a.gid, a.geom, a.shape_area, a.incra_area_loss;

-- Clean CAR_premium with self overlay random priority -- 3m27s
DROP TABLE IF EXISTS proc1_05_car_premium_clean;
CREATE TABLE proc1_05_car_premium_clean
(
  gid integer,
  geom geometry,
  shape_area double precision,
  incra_area_loss integer
);


INSERT INTO proc1_05_car_premium_clean
SELECT a.gid, 
	ST_CollectionExtract(
	CASE COUNT(B.gid) 
	WHEN 0 THEN 
		a.geom 
	WHEN 1 THEN 
		ST_Difference(a.geom, ST_GeometryN(ST_Collect(b.geom),1))
	ELSE 
		ST_Difference(a.geom, ST_Buffer(ST_Union(b.geom),0)) 
	END, 3) geom, a.shape_area, a.incra_area_loss
FROM proc1_03_is_premium a
LEFT JOIN proc1_03_z1_car_intersects c ON c.gid = a.gid
LEFT JOIN proc1_03_is_premium b ON c.gid2 = b.gid AND a.rnd > b.rnd AND b.fla_car_premium
WHERE a.fla_car_premium AND (a.gid % 15) = :var_proc
GROUP BY a.gid, a.geom, a.shape_area, a.incra_area_loss;


CREATE INDEX gix_proc1_04_car_poor_clean ON proc1_04_car_poor_clean USING GIST (geom);
CREATE INDEX gix_proc1_05_car_premium_clean ON proc1_05_car_premium_clean USING GIST (geom);
ANALYZE proc1_04_car_poor_clean ;
ANALYZE proc1_05_car_premium_clean ;


--Create poor without premium -- 8m54s
DROP TABLE IF EXISTS proc1_06_car_poor_clean_without_premium;
CREATE TABLE proc1_06_car_poor_clean_without_premium
(
  gid integer,
  geom geometry,
  shape_area double precision,
  area_loss double precision,
  incra_area_loss integer,
  fla_overlay_poor_premium boolean
);

INSERT INTO proc1_06_car_poor_clean_without_premium
SELECT gid, geom, shape_area, (area_previous-ST_Area(geom)) area_loss, incra_area_loss, fla_overlay_poor_premium
FROM (
SELECT poor.gid, 
	ST_CollectionExtract(
	CASE COUNT(premium.gid) 
	WHEN 0 THEN
		poor.geom
	WHEN 1 THEN
		ST_Difference(poor.geom, ST_GeometryN(ST_Collect(premium.geom), 1))
	ELSE
		ST_Difference(poor.geom, ST_Buffer(ST_Collect(premium.geom), 0.01)) 
	END, 3) geom, 
ST_Area(poor.geom) area_previous, poor.shape_area, poor.incra_area_loss,
COUNT(premium.gid) > 0 fla_overlay_poor_premium
FROM proc1_04_car_poor_clean poor
LEFT JOIN proc1_05_car_premium_clean premium ON ST_Intersects(poor.geom, premium.geom) AND NOT ST_Touches(poor.geom, premium.geom)
WHERE (poor.gid % 15) = :var_proc
GROUP BY poor.gid, poor.geom, poor.shape_area, poor.incra_area_loss) a;

--Log poor premium intersection
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(b.gid),
	SUM(CASE WHEN area_loss IS NULL THEN 0 ELSE area_loss END)
FROM log_operation operation
LEFT JOIN proc1_06_car_poor_clean_without_premium b ON b.fla_overlay_poor_premium
WHERE operation.nom_operation = 'car_poor_premium_overlay'
GROUP BY operation.id;


--Output everything to single feature -- 9.4s
DROP TABLE IF EXISTS proc1_07_car_solved;
CREATE TABLE proc1_07_car_solved AS
SELECT *, true is_premium 
FROM proc1_05_car_premium_clean
UNION ALL
SELECT gid, geom, shape_area, incra_area_loss, false
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
CREATE TEMP TABLE proc1_08_car_poor_no_overlay AS
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
SELECT rid, gid, area_original, false fla_eliminate, 1-(area/area_original) area_loss, area, perimeter, CASE WHEN perimeter = 0 THEN 0 ELSE (2*SQRT(PI() * area))/perimeter END ci, geom, incra_area_loss
FROM (
	SELECT row_number() OVER () rid, gid, area_original, ST_Area(geom) area, ST_Perimeter(geom) perimeter, geom, incra_area_loss
	FROM (
		SELECT gid, shape_area area_original, (ST_Dump(geom)).geom, incra_area_loss
		FROM proc1_08_car_poor_no_overlay
		) A)
	B;

	

--Calculating area loss
UPDATE proc1_09_car_single
SET fla_eliminate =  true
WHERE 
	area_loss > 0.5 OR
	ci < 0.12;


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

-- SELECT fla_eliminate, COUNT(*) FROM car_single
-- GROUP BY fla_eliminate

CREATE INDEX ix_car_single_eliminate ON proc1_09_car_single USING BTREE (fla_eliminate);
CREATE INDEX gix_car_single ON proc1_09_car_single USING GIST (geom);

-- SELECT COUNT(*) FROM (
-- SELECT a.rid, COUNT(*) conta
-- FROM car_single a
-- JOIN car_single b ON ST_DWithin(a.geom, b.geom, 0)
-- WHERE a.fla_eliminate AND NOT b.fla_eliminate
-- GROUP BY a.rid) A
-- WHERE conta = 1

-- ELIMINATE
-- Create temporary copy of CAR to be consolidated
DROP TABLE IF EXISTS proc1_11_temp_car_consolidated;
CREATE TABLE proc1_11_temp_car_consolidated AS --2.6s
SELECT *, false fla_multipolygon FROM proc1_09_car_single WHERE NOT fla_eliminate;

DROP TABLE IF EXISTS temp_already_process CASCADE;
CREATE TEMP TABLE temp_already_process(small INT);

SELECT lt_model.eliminate_car(); --1m45s

DO $$ --1m09s
BEGIN
WHILE (SELECT lt_model.eliminate_car_recursive()) > 0 LOOP
END LOOP;
END $$;

-- CREATE TABLE temp_small_points AS
-- SELECT * FROM temp_small_points;
-- 
-- ALTER TABLE lt_model.temp_small_points
-- ADD COLUMN fid SERIAL PRIMARY KEY;
-- 
-- CREATE TABLE lt_model.temp_small_points2 AS
-- SELECT * FROM temp_small_points2;
-- 
-- ALTER TABLE lt_model.temp_small_points2
-- ADD COLUMN fid SERIAL PRIMARY KEY;
-- 
-- CREATE TABLE lt_model.temp_max_intersect AS
-- SELECT * FROM temp_max_intersect;
-- 
-- ALTER TABLE lt_model.temp_max_intersect
-- ADD COLUMN fid SERIAL PRIMARY KEY;
-- 
-- 
-- CREATE TABLE lt_model.not_processed_1st AS
-- SELECT * FROM v_temp_small_points;
-- 

-- 4.7s
ALTER TABLE proc1_11_temp_car_consolidated 
ADD COLUMN is_premium BOOLEAN DEFAULT FALSE;

DROP TABLE IF EXISTS lt_model.lt_model_car_po;
CREATE TABLE lt_model.lt_model_car_po AS
SELECT * FROM proc1_11_temp_car_consolidated;

DROP TABLE IF EXISTS lt_model.lt_model_car_pr;
CREATE TABLE lt_model.lt_model_car_pr AS
SELECT gid, shape_area, false, 1-(ST_Area(geom)/shape_area) area_loss, ST_Area(geom) area, ST_Perimeter(geom), 1 ci, geom
FROM proc1_07_car_solved
WHERE is_premium;

SELECT clock_timestamp()-current_timestamp;