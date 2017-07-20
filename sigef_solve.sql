DO $$
DECLARE var_input lt_model.inputs;
DECLARE pcursor REFCURSOR;
BEGIN
	OPEN pcursor FOR SELECT * FROM lt_model.inputs WHERE ownership_class = 'PR' AND sub_class = 'INCRA' ORDER BY proc_order DESC;
		LOOP
		FETCH FROM pcursor INTO var_input;
		EXIT WHEN NOT FOUND;
		RAISE NOTICE '%: %', var_input.proc_order, var_input.table_name;
	END LOOP;
END $$;

SET search_path TO lt_model, public;

DO $BODY$
DECLARE table_name TEXT = 'pa_br_acervofundiario_basefundiaria_privado_2016_incra';
DECLARE state INT = 35;
BEGIN
EXECUTE format($$
	CREATE TEMP TABLE clean_autooverlay AS
	SELECT * FROM %1$I WHERE cod_uf14 = %2$L;
$$, table_name, state);
END $BODY$; 

CREATE INDEX gix_clean_autooverlay ON clean_autooverlay USING GIST (geom);


CREATE TEMP TABLE clean_auto_cleaned AS
SELECT *, ST_Area(geom) new_area
FROM
(SELECT c1.gid original_gid, ST_Area(c1.geom) original_area, CASE WHEN MAX(c2.gid) IS NULL THEN c1.geom ELSE ST_Difference(c1.geom, ST_Collect(c2.geom)) END geom
FROM clean_autooverlay c1
LEFT JOIN clean_autooverlay c2 ON c1.gid <> c2.gid AND ST_DWithin(c1.geom, c2.geom, 0) AND c1.shape_area < c2.shape_area
GROUP BY c1.geom, c1.gid, c1.shape_area) a;