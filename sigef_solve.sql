SET search_path TO lt_model, public;

SELECT nextval('seq_current_run');


CREATE OR REPLACE FUNCTION lt_model.clean_sigef (table_name text, key_name TEXT, state INT = -1) 
RETURNS void AS
$BODY$
DECLARE join_clause TEXT = '';
sigef_alias TEXT = CASE WHEN '2001' ~ table_name THEN '_law' ELSE '' END;
BEGIN
IF state != -1 THEN
	join_clause = format('JOIN public.pa_br_limiteestadual_250_2015_ibge b ON "CD_GEOCUF" = %1$L AND ST_Contains(ST_Transform(b.the_geom, 97823), a.geom)', state);
END IF;
	--Validate
	EXECUTE format($$
	DROP TABLE IF EXISTS clean_autooverlay;
	CREATE TEMP TABLE clean_autooverlay AS
	SELECT a.gid, a.%3$s cod, ST_MakeValid(a.geom) geom, ST_Area(geom) shape_area, ST_IsValid(a.geom) is_valid FROM %1$I a %2$s;
	$$, table_name, join_clause, key_name);

	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
		operation.id,
		COUNT(*),
		SUM(shape_area)
	FROM log_operation operation,
	clean_autooverlay b
	WHERE operation.nom_operation = 'sigef' || sigef_alias || '_valid' AND NOT b.is_valid
	GROUP BY operation.id;

		
	CREATE INDEX gix_clean_autooverlay ON clean_autooverlay USING GIST (geom);

	--Clean equal shape
	DROP TABLE IF EXISTS equal_shape;
	CREATE TEMP TABLE equal_shape AS
	SELECT a.gid 
	FROM clean_autooverlay a
	JOIN clean_autooverlay b ON ST_Equals(a.geom, b.geom) AND a.gid > b.gid;

	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
		operation.id,
		COUNT(*),
		SUM(shape_area)
	FROM log_operation operation,
	clean_autooverlay b
	WHERE operation.nom_operation = 'sigef' || sigef_alias || '_equal_shape'
	GROUP BY operation.id;
	
	DELETE FROM clean_autooverlay a
	USING equal_shape b
	WHERE a.gid = b.gid;

	-- Get intersections
	DROP TABLE IF EXISTS sigef_intersect_temp;
	CREATE TEMP TABLE sigef_intersect_temp AS
	SELECT 
		c1.gid original_gid, c1.cod, c1.shape_area original_area, c1.shape_area, c2.gid gid2, c1.geom geom1, c2.geom geom2
	FROM clean_autooverlay c1
	LEFT JOIN clean_autooverlay c2 ON c1.gid <> c2.gid AND ST_Intersects(c1.geom, c2.geom) AND NOT ST_Touches(c1.geom, c2.geom) AND c1.shape_area > c2.shape_area;

	--Log intersections
	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
		operation.id,
		COUNT(*),
		SUM(original_area)
	FROM log_operation operation,
	sigef_intersect_temp b
	WHERE operation.nom_operation = 'sigef' || sigef_alias || '_autointersection' AND b.gid2 IS NOT NULL
	GROUP BY operation.id;
	
	
	--Clean priority to small
	DROP TABLE IF EXISTS sigef_cleaned;
	CREATE TEMP TABLE sigef_cleaned AS
	SELECT *, ST_Area(geom) new_area
	FROM
	(SELECT original_gid, cod, original_area, CASE WHEN MAX(gid2) IS NULL THEN geom1 ELSE ST_Difference(geom1, ST_Buffer(ST_Collect(geom2), 0.01)) END geom
	FROM sigef_intersect_temp
	GROUP BY geom1, cod, original_gid, original_area) a;

	ALTER TABLE sigef_cleaned
	ADD COLUMN area_loss DECIMAL (7,4);

	UPDATE sigef_cleaned 
	SET area_loss = 100*(1-new_area/original_area::DECIMAL);

	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
		operation.id,
		COUNT(*),
		SUM(original_area)
	FROM log_operation operation,
	sigef_cleaned b
	WHERE operation.nom_operation = 'sigef' || '_area_loss_gt_95' AND b.area_loss > 95
	GROUP BY operation.id;

	DELETE FROM sigef_cleaned
	WHERE area_loss > 95;

END $BODY$ LANGUAGE plpgsql;


-- SIGEF clean
DROP TABLE IF EXISTS sigef_lei2001;
SELECT lt_model.clean_sigef('pa_br_acervofundiario_certimoveisruraislei10267_2001_privado_in', 'cod_imov1', 35);
ALTER TABLE sigef_cleaned
RENAME TO sigef_lei2001;

-- SIGEF law clean
DROP TABLE IF EXISTS sigef;
SELECT lt_model.clean_sigef('pa_br_acervofundiario_basefundiaria_privado_2016_incra', 35);
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
FROM (SELECT original_gid, original_area, CASE WHEN MAX(original_gid2) IS NULL THEN geom1 ELSE ST_Difference(geom1, ST_Buffer(ST_Collect(geom2), 0)) END geom, MAX(original_gid2) IS NULL is_sigef2001_lt_sigef
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