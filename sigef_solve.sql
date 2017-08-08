SET search_path TO lt_model, public;

--SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM lt_model.log_outputs));
SELECT nextval('seq_current_run');

-- SIGEF clean
DROP TABLE IF EXISTS sigef_lei2001;
SELECT lt_model.clean_sigef('pa_br_acervofundiario_certimoveisruraislei10267_2001_privado_in', 'cod_imov1', 'data_cer5', currval('seq_current_run')::int, 35);
ALTER TABLE sigef_cleaned
RENAME TO sigef_lei2001;


-- SIGEF law clean
DROP TABLE IF EXISTS sigef;
SELECT lt_model.clean_sigef('pa_br_acervofundiario_basefundiaria_privado_2016_incra', 'codigo_i4', 'data_apr7', currval('seq_current_run')::int, 35);
ALTER TABLE sigef_cleaned
RENAME TO sigef;

CREATE INDEX gix_sigef_lei2001 ON sigef_lei2001 USING GIST (geom);
CREATE INDEX gix_sigef ON sigef USING GIST (geom);
CREATE INDEX ix_sigef ON sigef USING BTREE (new_area);
CREATE INDEX ix_sigef_lei2001 ON sigef_lei2001 USING BTREE (new_area);


-- SIGEF - SIGEF2001 WHERE SIGEF2001 < SIGEF
DROP TABLE IF EXISTS sigef_intersect_temp;
CREATE TEMP TABLE sigef_intersect_temp AS
SELECT a.original_gid, a.original_area, b.original_gid original_gid2, a.geom geom1, b.geom geom2
FROM sigef a
LEFT JOIN sigef_lei2001 b ON ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom) AND b.new_area < a.new_area;


DROP TABLE IF EXISTS sigef_solved;
CREATE TEMP TABLE sigef_solved AS
SELECT *, ST_Area(geom) area, false is_law2001
FROM (SELECT original_gid, original_area, CASE WHEN MAX(original_gid2) IS NULL THEN geom1 ELSE ST_Difference(geom1, ST_Buffer(ST_Collect(geom2), 0)) END geom, MAX(original_gid2) IS NOT NULL is_sigef2001_lt_sigef
FROM sigef_intersect_temp
GROUP BY original_gid, original_area, geom1) A;

CREATE INDEX gix_sigef_solved ON sigef_solved USING GIST (geom);
CREATE INDEX ix_sigef_solved ON sigef_solved USING BTREE (area);

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
		operation.id,
		COUNT(*),
		SUM(area)
	FROM log_operation operation,
	sigef_solved b
	WHERE operation.nom_operation = 'sigef2001 < sigef' AND is_sigef2001_lt_sigef
	GROUP BY operation.id;


-- SIGEF2001 - SIGEF WHERE SIGEF < SIGEF2001
DROP TABLE IF EXISTS sigef_intersect_temp;
CREATE TEMP TABLE sigef_intersect_temp AS
SELECT a.original_gid, a.original_area, b.original_gid original_gid2, a.geom geom1, b.geom geom2
FROM sigef_lei2001 a
LEFT JOIN sigef_solved b ON ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom) AND b.area < a.new_area;

INSERT INTO sigef_solved
SELECT *, ST_Area(geom) area, true is_law_2001
FROM (SELECT original_gid, original_area, CASE WHEN MAX(original_gid2) IS NULL THEN geom1 ELSE ST_Difference(geom1, ST_Buffer(ST_Collect(geom2), -0.01)) END geom, MAX(original_gid2) IS NULL is_sigef2001_lt_sigef
FROM sigef_intersect_temp
GROUP BY original_gid, original_area, geom1) A;

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
		operation.id,
		COUNT(*),
		SUM(area)
	FROM log_operation operation,
	sigef_solved b
	WHERE operation.nom_operation = 'sigef < sigef2001' AND NOT is_sigef2001_lt_sigef AND is_law2001
	GROUP BY operation.id;


DROP TABLE IF EXISTS sigef_result;
CREATE TEMP TABLE sigef_result AS
SELECT * FROM sigef_solved;

ALTER TABLE sigef_result
ADD COLUMN area_loss DECIMAL;
UPDATE sigef_result
SET area_loss = (1-area/original_area)*100;

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
		operation.id,
		COUNT(*),
		SUM(area)
	FROM log_operation operation,
	sigef_result b
	WHERE operation.nom_operation = 'sigef_clean_lost_95area' AND b.area_loss > 95
	GROUP BY operation.id;

DELETE FROM sigef_result
WHERE area_loss > 95;

CREATE INDEX gix_sigef_result ON sigef_result USING GIST (geom);

DROP TABLE IF EXISTS public.lt_model_sigef;
CREATE TABLE public.lt_model_sigef AS
SELECT row_number() OVER () gid, * FROM sigef_result;