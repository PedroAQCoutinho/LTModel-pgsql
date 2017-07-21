DO $$
DECLARE var_input lt_model.inputs;
DECLARE pcursor REFCURSOR;
BEGIN
	OPEN pcursor FOR SELECT * 
	FROM lt_model.inputs a
	WHERE ownership_class = 'PR' AND sub_class = 'INCRA' ORDER BY proc_order DESC;
		LOOP
		FETCH FROM pcursor INTO var_input;
		EXIT WHEN NOT FOUND;
		RAISE NOTICE '%: %', var_input.proc_order, var_input.table_name;
	END LOOP;
END $$;


CREATE OR REPLACE FUNCTION lt_model.clean_sigef (table_name text, state INT = -1) 
RETURNS void AS
$BODY$
DECLARE join_clause TEXT = '';
BEGIN
IF state != -1 THEN
	join_clause = 'JOIN public.pa_br_limiteestadual_250_2015_ibge b ON "CD_GEOCUF" = %2$L AND ST_Contains(ST_Transform(b.the_geom, 97823), a.geom)';
END IF;
EXECUTE format($$
	DROP TABLE IF EXISTS clean_autooverlay;
	CREATE TEMP TABLE clean_autooverlay AS
	SELECT a.gid, ST_MakeValid(a.geom) geom, ST_Area(geom) shape_area FROM %1$I a %2$s;
	$$, table_name, join_clause);
	
	
	CREATE INDEX gix_clean_autooverlay ON clean_autooverlay USING GIST (geom);

	--Clean equal area length
	DELETE FROM clean_autooverlay a
	USING clean_autooverlay b
	WHERE ST_Equals(a.geom, b.geom) AND a.gid <> b.gid;

	--Clean priority to small
	DROP TABLE IF EXISTS sigef_cleaned;
	CREATE TEMP TABLE sigef_cleaned AS
	SELECT *, ST_Area(geom) new_area
	FROM
	(SELECT c1.gid original_gid, c1.shape_area original_area, ST_Difference(c1.geom, ST_Buffer(ST_Collect(c2.geom), 0.01)) geom
	FROM clean_autooverlay c1
	LEFT JOIN clean_autooverlay c2 ON c1.gid <> c2.gid AND ST_DWithin(c1.geom, c2.geom, 0) AND c1.shape_area > c2.shape_area
	GROUP BY c1.geom, c1.gid, c1.shape_area) a;

	ALTER TABLE sigef_cleaned
	ADD COLUMN area_loss DECIMAL (7,4);

	UPDATE sigef_cleaned 
	SET area_loss = 100*(1-new_area/original_area::DECIMAL);

	DELETE FROM sigef_cleaned
	WHERE new_area/original_area < 0.05;

END $BODY$ LANGUAGE plpgsql;





SELECT lt_model.clean_sigef('pa_br_acervofundiario_certimoveisruraislei10267_2001_privado_in');
CREATE TABLE lt_model.sigef_lei2001 AS 
SELECT * FROM sigef_cleaned;

SELECT lt_model.clean_sigef('pa_br_acervofundiario_basefundiaria_privado_2016_incra');
CREATE TABLE lt_model.sigef AS 
SELECT * FROM sigef_cleaned;

CREATE INDEX gix_sigef_lei2001 ON lt_model.sigef_lei2001 USING GIST (geom);
CREATE INDEX gix_sigef ON lt_model.sigef USING GIST (geom);

DROP TABLE IF EXISTS sigef_intersect;
CREATE TEMP TABLE sigef_intersect AS
SELECT a.original_gid, a.new_area old_area, ST_Intersection(a.geom, b.geom) geom, false::BOOLEAN is_lei2001 FROM lt_model.sigef a
JOIN lt_model.sigef_lei2001 b ON ST_DWithin(a.geom, b.geom, 0) AND NOT ST_Touches(a.geom, b.geom) AND a.new_area < b.new_area*1.3;

DROP TABLE IF EXISTS sigef_no_similar;
CREATE TEMP TABLE sigef_no_similar AS
SELECT * FROM lt_model.sigef;

DELETE FROM sigef_no_similar a
USING sigef_intersect b
WHERE ST_Area(b.geom) > b.old_area*0.7 AND a.original_gid = b.original_gid;

CREATE INDEX gix_sigef_no_similar ON sigef_no_similar USING GIST (geom);

DROP TABLE IF EXISTS sigef_diff;
CREATE TABLE sigef_diff AS
SELECT a.original_gid, a.new_area old_area, ST_Difference(a.geom, ST_Collect(b.geom)) geom, false::BOOLEAN is_lei2001 FROM sigef_no_similar a
LEFT JOIN lt_model.sigef_lei2001 b ON ST_DWithin(a.geom, b.geom, 0) AND NOT ST_Touches(a.geom, b.geom)
GROUP BY a.original_gid, a.new_area, a.geom;


INSERT INTO sigef_diff (original_gid, old_area, geom, is_lei2001)
SELECT original_gid, new_area, geom, true is_lei2001 FROM lt_model.sigef_lei2001;


ALTER TABLE sigef_diff
ADD COLUMN area_loss DECIMAL(7,4);


UPDATE sigef_diff
SET area_loss = CASE WHEN ST_Area(geom) = 0 THEN 100 ELSE 100*(1-(ST_Area(geom)/old_area::DECIMAL)) END;

DELETE FROM sigef_diff
WHERE area_loss > 90;



