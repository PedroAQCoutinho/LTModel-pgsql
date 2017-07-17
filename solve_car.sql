-- CAR SOLVING
SET search_path TO lt_model, public;

CREATE SEQUENCE IF NOT EXISTS seq_current_run;

SELECT nextval('seq_current_run');


CREATE TABLE IF NOT EXISTS log_operation(id SERIAL PRIMARY KEY, nom_operation TEXT);

CREATE TABLE IF NOT EXISTS log_outputs(
	id SERIAL PRIMARY KEY,
	num_run INT,
	fk_operation INT REFERENCES log_operation(id),
	num_geom INT,
	val_area NUMERIC
);


CREATE TEMP TABLE invalid_geom AS
SELECT gid, ST_Area(geom) area
FROM es_sp_car_areaimovel_2016_sfb
WHERE NOT ST_IsValid(geom);


-- Validates geometry
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(area)
FROM log_operation operation,
invalid_geom b
WHERE operation.nom_operation = 'car_valid'
GROUP BY operation.id;

SELECT currval('log_outputs_id_seq');




-- Copy original table
DROP TABLE IF EXISTS temp_car_1;
CREATE TEMP TABLE temp_car_1 AS
SELECT a.gid, cod_imovel, num_area, cod_estado, nom_munici, num_modulo, ST_Area(geom) shape_area, ST_Perimeter(geom) shape_leng, ST_CollectionExtract(CASE WHEN b.gid > -1 THEN ST_MakeValid(geom) ELSE geom END , 3) geom
FROM es_sp_car_areaimovel_2016_sfb a
LEFT JOIN invalid_geom b ON a.gid = b.gid;

-- Create indexes 1m06s
--DROP INDEX ix_temp_car_1_1;
CREATE INDEX ix_temp_car_1_1 ON temp_car_1 USING BTREE (shape_area, shape_leng);
CREATE INDEX ix_temp_car_1_2 ON temp_car_1 USING GIST (geom);
CREATE INDEX ix_temp_car_1_3 ON temp_car_1 USING BTREE ((ST_XMin(geom)), (ST_YMin(geom)), (ST_XMax(geom)), (ST_YMax(geom))); --13.7s


-- Delete features outside brazil boundary (Albers) (5)
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

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(shape_area)
FROM log_operation operation,
temp_car_2 b
WHERE operation.nom_operation = 'car_same_num_car'
GROUP BY operation.id;

DELETE FROM temp_car_1 a
USING temp_car_2 b
WHERE b.gid <> a.gid AND b.cod_imovel = a.cod_imovel;


DROP TABLE IF EXISTS temp_car_3;
CREATE TEMP TABLE temp_car_3 AS
SELECT *, (2*SQRT(PI()*shape_area))/shape_leng ci
FROM temp_car_1;

CREATE INDEX ix_temp_car_3_1 ON temp_car_3 USING BTREE (ci); -- 9s
CREATE INDEX ix_temp_car_3_2 ON temp_car_3 USING BTREE (shape_area); --4.5s
CREATE INDEX ix_temp_car_3_3 ON temp_car_3 USING BTREE (gid); --2.8s
CREATE INDEX gix_temp_car_3 ON temp_car_3 USING GIST (geom); --54s

-- Clean CI below 0.12
-- DELETE FROM temp_car_3
-- WHERE ci <= 0.12;

-- SIGEF OVERLAYING
DROP TABLE temp_car_sigef;
CREATE TEMP TABLE temp_car_sigef AS
SELECT *, (1-(ST_Area(intersection_geom)/shape_area)) area_loss FROM (
SELECT a.gid car, a.geom car_geom, ST_CollectionExtract(ST_Difference(a.geom, ST_Buffer(ST_Buffer(ST_Collect(b.geom), 0.01), -0.01)), 3) intersection_geom, a.shape_area, a.shape_leng
FROM temp_car_3 a
LEFT JOIN pa_br_acervofundiario_basefundiaria_privado_2016_incra b ON ST_Intersects(a.geom, b.geom)
GROUP BY a.gid, a.geom, a.shape_area, a.shape_leng) c;

-- Log greater than or equal 70
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(shape_area)
FROM log_operation operation,
temp_car_sigef b
WHERE operation.nom_operation = 'car_sigef_gte_70' AND b.area_loss >= 0.3
GROUP BY operation.id;

-- Log less than 70
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(shape_area)
FROM log_operation operation,
temp_car_sigef b
WHERE operation.nom_operation = 'car_sigef_lt_70' AND b.area_loss < 0.3
GROUP BY operation.id;


DROP TABLE IF EXISTS temp_car_sigef_union;
CREATE TEMP TABLE temp_car_sigef_union AS
SELECT gid, geom::geometry(MultiPolygon) geom, ST_Area(geom) shape_area, ST_Perimeter(geom) shape_leng, 0 area_loss, true fla_sigef
FROM public.pa_br_acervofundiario_basefundiaria_privado_2016_incra;

INSERT INTO temp_car_sigef_union
SELECT car, car_geom::geometry(MultiPolygon) geom, shape_area, shape_leng, 0 area_loss, false fla_sigef
FROM temp_car_sigef
WHERE area_loss IS NULL OR area_loss = 0;

INSERT INTO temp_car_sigef_union
SELECT car, ST_Multi(intersection_geom) geom, shape_area, shape_leng, area_loss*shape_area area_loss, false fla_sigef
FROM temp_car_sigef
WHERE area_loss < 0.3;


CREATE INDEX gix_temp_car_sigef_union ON temp_car_sigef_union USING GIST (geom);
CREATE INDEX ix_temp_car_sigef_union ON temp_car_sigef_union USING BTREE (gid);

UPDATE lt_model.temp_car_sigef_union
SET geom = ST_Multi(ST_Buffer(ST_MakeValid(geom), 0))
;

-- SELF OVERLAYING IN CAR
-- Tratamento do CAR priozando o menor
DROP TABLE IF EXISTS car_result;
CREATE TEMP TABLE car_result AS --
SELECT c1.gid gid, ST_Difference(c1.geom, ST_Buffer(ST_Collect(c2.geom), -0.01)) geom
FROM lt_model.temp_car_sigef_union c1 
LEFT JOIN lt_model.temp_car_sigef_union c2 ON c1.gid != c2.gid AND ST_Intersects(c1.geom, c2.geom)
WHERE NOT c1.fla_sigef AND NOT c2.fla_sigef
GROUP BY c1.gid, c1.geom;

CREATE TEMP TABLE is_premium AS
SELECT *, (1- (new_area/shape_area)) <= 0.05 fla_car_premium
FROM (
SELECT b.*, ST_Area(b.geom) new_area
FROM car_result a
JOIN lt_model.temp_car_sigef_union b ON a.gid = b.gid
WHERE NOT fla_sigef) c;

CREATE INDEX ix_is_premium ON is_premium USING BTREE (gid);
CREATE INDEX ix_is_premium_2 ON is_premium USING BTREE (fla_car_premium);
CREATE INDEX gix_is_premium ON is_premium USING GIST (geom);


-- CREATE TABLE of everything that intersects
CREATE TEMP TABLE car_intersects AS
SELECT a.gid, b.gid gid2, a.fla_car_premium, b.fla_car_premium fla_car_premium2, a.new_area
FROM is_premium a
JOIN is_premium b ON a.gid <> b.gid AND ST_DWithin(a.geom, b.geom, 0);

-- log premium
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(shape_area)
FROM log_operation operation,
is_premium b
WHERE operation.nom_operation = 'car_premium' AND fla_car_premium
GROUP BY operation.id;

--log not prime
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(shape_area)
FROM log_operation operation,
is_premium b
WHERE operation.nom_operation = 'car_prime' AND NOT fla_car_premium
GROUP BY operation.id;

--log prime self intersection
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(new_area)
FROM log_operation operation,
(SELECT DISTINCT ON (gid) * FROM car_intersects 
) b
WHERE operation.nom_operation = 'car_prime_self_overlay' AND NOT b.fla_car_premium AND NOT b.fla_car_premium2
GROUP BY operation.id;


--log premium self intersection
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(*),
	SUM(new_area)
FROM log_operation operation,
(SELECT DISTINCT ON (gid) * FROM car_intersects 
) b
WHERE operation.nom_operation = 'car_premium_self_overlay' AND b.fla_car_premium AND b.fla_car_premium2
GROUP BY operation.id;


-- Clean CAR_prime with self overlay priority to small
DROP TABLE IF EXISTS car_prime_clean;
CREATE TEMP TABLE car_prime_clean AS
SELECT a.gid, ST_Difference(a.geom, ST_Buffer(ST_Collect(b.geom),-0.01)) geom, a.shape_area
FROM car_intersects c
JOIN is_premium a ON c.gid = a.gid
JOIN is_premium b ON c.gid2 = b.gid AND a.shape_area > b.shape_area
WHERE NOT c.fla_car_premium AND NOT c.fla_car_premium2
GROUP BY a.gid, a.geom, a.shape_area;

-- Clean CAR_premium with self overlay priority to smaller
DROP TABLE IF EXISTS car_premium_clean;
CREATE TEMP TABLE car_premium_clean AS
SELECT a.gid, CASE WHEN MAX(B.gid) IS NULL THEN a.geom ELSE ST_Difference(a.geom, ST_Buffer(ST_Collect(b.geom),-0.01)) END geom, a.shape_area
FROM car_intersects c
JOIN is_premium a ON c.gid = a.gid
LEFT JOIN is_premium b ON c.gid2 = b.gid AND a.gid > b.gid
WHERE c.fla_car_premium AND c.fla_car_premium2
GROUP BY a.gid, a.geom, a.shape_area;

CREATE INDEX gix_car_prime_clean ON car_prime_clean USING GIST (geom);
CREATE INDEX gix_car_premium_clean ON car_premium_clean USING GIST (geom);

--Create prime without premium
DROP TABLE IF EXISTS car_prime_clean_without_premium;
CREATE TEMP TABLE car_prime_clean_without_premium AS
SELECT gid, geom, shape_area, (area_previous-ST_Area(geom)) area_loss
FROM (SELECT prime.gid, ST_Difference(prime.geom, ST_Buffer(ST_Collect(premium.geom), -0.01)) geom, ST_Area(prime.geom) area_previous, prime.shape_area
FROM car_prime_clean prime
JOIN car_premium_clean premium ON ST_DWithin(prime.geom, premium.geom, 0)
GROUP BY prime.gid, prime.geom, prime.shape_area) a

DELETE FROM car_prime_clean a
USING car_prime_clean_without_premium b
WHERE a.gid = b.gid


--Log prime premium intersection
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(b.gid),
	SUM(area_loss)
FROM log_operation operation,
car_prime_clean_without_premium b
WHERE operation.nom_operation = 'car_prime_premium_overlay'
GROUP BY operation.id;


--Output everything to single feature
DROP TABLE IF EXISTS car_solved;
CREATE TEMP TABLE car_solved AS
SELECT * 
FROM car_premium_clean 

INSERT INTO car_solved
SELECT gid, geom, shape_area
FROM car_prime_clean;

INSERT INTO car_solved
SELECT gid, geom, shape_area
FROM car_prime_clean_without_premium;


UPDATE car_result
SET fla_single = ST_GeometryType(geom) = 'ST_Polygon';

-- Multi to single, calculate area and perimeter
DROP TABLE IF EXISTS lt_model.car_single;
CREATE TABLE car_single AS
SELECT rid, gid, area_original, fla_single, false fla_eliminate, 1-(area/area_original) area_loss, area, perimeter, (2*SQRT(PI() * area))/perimeter ci, geom
FROM (
	SELECT row_number() OVER () rid, gid, area_original, fla_single, ST_Area(geom) area, ST_Perimeter(geom) perimeter, geom
	FROM (
		SELECT gid, area_original, fla_single, (ST_Dump(geom)).geom
		FROM car_result
		) A)
	B;

--Calculating area loss
UPDATE car_single
SET fla_eliminate =  true
WHERE 
	area_loss > 0.7 OR
	ci < 0.12;

-- SELECT fla_eliminate, COUNT(*) FROM car_single
-- GROUP BY fla_eliminate

CREATE INDEX ix_car_single_eliminate ON car_single USING BTREE (fla_eliminate);
CREATE INDEX gix_car_single ON car_single USING GIST (geom);

-- SELECT COUNT(*) FROM (
-- SELECT a.rid, COUNT(*) conta
-- FROM car_single a
-- JOIN car_single b ON ST_DWithin(a.geom, b.geom, 0)
-- WHERE a.fla_eliminate AND NOT b.fla_eliminate
-- GROUP BY a.rid) A
-- WHERE conta = 1

-- ELIMINATE
-- Create temporary copy of CAR to be consolidated
DROP TABLE IF EXISTS temp_car_consolidated;
CREATE TABLE temp_car_consolidated AS --2.6s
SELECT *, false fla_multipolygon FROM car_single WHERE NOT fla_eliminate;

DROP TABLE IF EXISTS temp_already_process CASCADE;
CREATE TEMP TABLE temp_already_process(small INT);

DROP TABLE IF EXISTS temp_bounds;
CREATE TEMP TABLE temp_bounds AS --5s --
	SELECT DISTINCT a.rid, (ST_Dump(ST_ExteriorRing(a.geom))).geom::geometry(Linestring, 97823) geom, a.fla_eliminate
	FROM lt_model.car_single a;

--Extract nodes from linestrings
DROP TABLE IF EXISTS temp_small_points; -- 0.7s
CREATE TEMP TABLE temp_small_points AS
SELECT rid, (dp).path[1] ind, (dp).geom geom
FROM (SELECT rid, (ST_DumpPoints(geom)) dp
FROM temp_bounds
WHERE fla_eliminate) A;

CREATE INDEX gix_temp_small_points ON temp_small_points USING GIST (geom); --5.1s

SELECT lt_model.eliminate_car();


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
SELECT lt_model.eliminate_car_recursive();
DO $$
DECLARE previous INT = -1;
DECLARE current INT = 1;
BEGIN
LOOP
    current = (SELECT COUNT(*) FROM car_single WHERE fla_eliminate) - (SELECT COUNT(*) FROM temp_already_process);
    IF current = 0 OR previous = current THEN
	RAISE NOTICE 'Eliminated everything possible!';
	EXIT;
    END IF;

    PERFORM lt_model.eliminate_car_recursive();
    previous = current;
END LOOP;
END $$;

