-- CAR SOLVING
SET search_path TO lt_model, public;

CREATE SEQUENCE IF NOT EXISTS seq_current_run;

SELECT nextval('seq_current_run');


DROP TABLE IF EXISTS invalid_geom;
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
DROP TABLE IF EXISTS temp_car_sigef;
CREATE TEMP TABLE temp_car_sigef AS
SELECT *, (1.0-(ST_Area(intersection_geom)/shape_area)) area_loss FROM (
SELECT a.gid car, a.geom car_geom, ST_CollectionExtract(ST_Difference(a.geom, ST_Buffer(ST_Buffer(ST_Collect(b.geom), 0.01), -0.01)), 3) intersection_geom, a.shape_area, a.shape_leng
FROM temp_car_3 a
LEFT JOIN pa_br_acervofundiario_basefundiaria_privado_2016_incra b ON ST_DWithin(a.geom, b.geom, 0)
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
WHERE area_loss < 0.3 AND area_loss > 0;



CREATE INDEX gix_temp_car_sigef_union ON temp_car_sigef_union USING GIST (geom);
CREATE INDEX ix_temp_car_sigef_union ON temp_car_sigef_union USING BTREE (gid);

UPDATE temp_car_sigef_union
SET geom = ST_Multi(ST_Buffer(ST_MakeValid(geom), 0));

-- SELF OVERLAYING IN CAR
-- Tratamento do CAR priozando o menor
DROP TABLE IF EXISTS car_result;
CREATE TEMP TABLE car_result AS --
SELECT c1.gid gid, ST_Difference(c1.geom, ST_Buffer(ST_Collect(c2.geom), -0.01)) geom, c1.area_loss incra_area_loss
FROM temp_car_sigef_union c1 
LEFT JOIN temp_car_sigef_union c2 ON c1.gid != c2.gid AND ST_DWithin(c1.geom, c2.geom, 0)
WHERE NOT c1.fla_sigef AND NOT c2.fla_sigef
GROUP BY c1.gid, c1.geom, c1.area_loss;

DROP TABLE IF EXISTS is_premium;
CREATE TEMP TABLE is_premium AS
SELECT *, (new_area/shape_area) >= 0.95 fla_car_premium
FROM (
SELECT b.*, ST_Area(a.geom) new_area, a.incra_area_loss
FROM car_result a
JOIN temp_car_sigef_union b ON a.gid = b.gid
WHERE NOT fla_sigef) c;

CREATE INDEX ix_is_premium ON is_premium USING BTREE (gid);
CREATE INDEX ix_is_premium_2 ON is_premium USING BTREE (fla_car_premium);
CREATE INDEX gix_is_premium ON is_premium USING GIST (geom);


-- CREATE TABLE of everything that intersects
DROP TABLE IF EXISTS car_intersects;
CREATE TEMP TABLE car_intersects AS
SELECT a.gid, b.gid gid2, a.fla_car_premium, b.fla_car_premium fla_car_premium2, a.new_area, a.incra_area_loss
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
SELECT a.gid, CASE WHEN MAX(b.gid) IS NULL THEN a.geom ELSE ST_Difference(a.geom, ST_Buffer(ST_Collect(b.geom),-0.01)) END geom, a.shape_area, a.incra_area_loss
FROM car_intersects c
JOIN is_premium a ON c.gid = a.gid
LEFT JOIN is_premium b ON c.gid2 = b.gid AND a.shape_area > b.shape_area
WHERE NOT c.fla_car_premium AND NOT c.fla_car_premium2
GROUP BY a.gid, a.geom, a.shape_area, a.incra_area_loss;


-- Clean CAR_premium with self overlay priority to smaller gid
DROP TABLE IF EXISTS car_premium_clean;
CREATE TEMP TABLE car_premium_clean AS
SELECT a.gid, CASE WHEN MAX(B.gid) IS NULL THEN a.geom ELSE ST_Difference(a.geom, ST_Buffer(ST_Collect(b.geom),-0.01)) END geom, a.shape_area, a.incra_area_loss
FROM is_premium a
LEFT JOIN car_intersects c ON c.gid = a.gid
LEFT JOIN is_premium b ON c.gid2 = b.gid AND a.gid > b.gid
WHERE c.fla_car_premium AND c.fla_car_premium2
GROUP BY a.gid, a.geom, a.shape_area, a.incra_area_loss;

CREATE INDEX IF NOT EXISTS ix_is_premium ON is_premium USING BTREE (gid);
CREATE INDEX IF NOT EXISTS  ix_car_intersects ON car_intersects USING BTREE (gid, gid2);

CREATE INDEX gix_car_prime_clean ON car_prime_clean USING GIST (geom);
CREATE INDEX gix_car_premium_clean ON car_premium_clean USING GIST (geom);

--Create prime without premium
DROP TABLE IF EXISTS car_prime_clean_without_premium;
CREATE TEMP TABLE car_prime_clean_without_premium AS
SELECT gid, geom, shape_area, (area_previous-ST_Area(geom)) area_loss, incra_area_loss
FROM (SELECT prime.gid, ST_Difference(prime.geom, ST_Buffer(ST_Collect(premium.geom), -0.01)) geom, ST_Area(prime.geom) area_previous, prime.shape_area, prime.incra_area_loss
FROM car_prime_clean prime
JOIN car_premium_clean premium ON ST_DWithin(prime.geom, premium.geom, 0)
GROUP BY prime.gid, prime.geom, prime.shape_area, prime.incra_area_loss) a;

DELETE FROM car_prime_clean a
USING car_prime_clean_without_premium b
WHERE a.gid = b.gid;


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
SELECT *, true is_premium 
FROM car_premium_clean;

INSERT INTO car_solved
SELECT gid, geom, shape_area, incra_area_loss, false
FROM car_prime_clean;

INSERT INTO car_solved
SELECT gid, geom, shape_area, incra_area_loss, false
FROM car_prime_clean_without_premium;

INSERT INTO car_solved
SELECT a.gid, geom, shape_area, a.incra_area_loss, true
FROM is_premium a
LEFT JOIN car_intersects b ON a.gid = b.gid
WHERE b.fla_car_premium AND NOT b.fla_car_premium2;


ALTER TABLE car_solved
ADD COLUMN is_single BOOLEAN DEFAULT false;

UPDATE car_solved
SET is_single = ST_GeometryType(geom) = 'ST_Polygon';

ALTER TABLE car_solved
ADD COLUMN new_area NUMERIC(30,2);

UPDATE car_solved
SET new_area = ST_Area(geom);

-- Get only CAR prime
DROP TABLE IF EXISTS car_prime_no_overlay;
CREATE TEMP TABLE car_prime_no_overlay AS
SELECT * 
FROM car_solved
WHERE NOT is_premium;


-- Log CAR prime multipolygon
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(b.gid),
	SUM(new_area)
FROM log_operation operation,
car_prime_no_overlay b
WHERE operation.nom_operation = 'car_prime_multipolygon' AND NOT b.is_premium AND NOT b.is_single
GROUP BY operation.id;


-- Multi to single, calculate area and perimeter
DROP TABLE IF EXISTS car_single;
CREATE TEMP TABLE car_single AS
SELECT rid, gid, area_original, false fla_eliminate, 1-(area/area_original) area_loss, area, perimeter, (2*SQRT(PI() * area))/perimeter ci, geom, incra_area_loss
FROM (
	SELECT row_number() OVER () rid, gid, area_original, ST_Area(geom) area, ST_Perimeter(geom) perimeter, geom, incra_area_loss
	FROM (
		SELECT gid, shape_area area_original, (ST_Dump(geom)).geom, incra_area_loss
		FROM car_prime_no_overlay
		) A)
	B;

--Calculating area loss
UPDATE car_single
SET fla_eliminate =  true
WHERE 
	area_loss > 0.5 OR
	ci < 0.12;


--Log CAR prime consolidated and to join
INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(b.gid),
	SUM(area)
FROM log_operation operation,
car_single b
WHERE operation.nom_operation = 'car_prime_consolidated' AND NOT b.fla_eliminate
GROUP BY operation.id;

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
	operation.id,
	COUNT(b.gid),
	SUM(area)
FROM log_operation operation,
car_single b
WHERE operation.nom_operation = 'car_prime_to_join' AND b.fla_eliminate
GROUP BY operation.id;

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
	FROM car_single a;

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

ALTER TABLE temp_car_consolidated 
ADD COLUMN is_premium BOOLEAN DEFAULT FALSE;

INSERT INTO temp_car_consolidated (gid, area_original, fla_eliminate, area_loss, area, perimeter, ci, geom, fla_multipolygon, is_premium)
SELECT gid, shape_area, false, 1-(ST_Area(geom)/shape_area) area_loss, ST_Area(geom) area, ST_Perimeter(geom), 1 ci, geom, false, true
FROM car_solved
WHERE is_premium;


DROP TABLE IF EXISTS public.lt_model_car;
CREATE TABLE public.lt_model_car AS
SELECT * FROM temp_car_consolidated;

DROP TABLE IF EXISTS public.lt_model_sigef;
CREATE TABLE public.lt_model_sigef AS
SELECT * FROM temp_car_sigef_union WHERE fla_sigef;

