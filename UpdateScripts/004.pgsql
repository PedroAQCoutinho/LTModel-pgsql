ALTER TABLE recorte.params 
ADD COLUMN param_text TEXT;

INSERT INTO recorte.params (param_name, param_desc, param_text)
VALUES ('snci_input_table', 'Nome da tabela do SNCI utilizada para o processamento', 'input_acervofundiario_snci_particular_2018_incra');

INSERT INTO recorte.params (param_name, param_desc, param_text)
VALUES ('snci_cert_date_column', 'Nome da coluna da data do certificado na tabela SNCI utilizada para processamento', 'data_certi');

INSERT INTO recorte.params (param_name, param_desc, param_text)
VALUES ('snci_code_column', 'Nome da coluna com código do imóvel na tabela SNCI utilizada para processamento', 'cod_imovel');


INSERT INTO recorte.params (param_name, param_desc, param_text)
VALUES ('sigef_input_table', 'Nome da tabela do SIGEF utilizada para o processamento', 'input_acervofundiario_sigef_particular_2018_incra');

INSERT INTO recorte.params (param_name, param_desc, param_text)
VALUES ('sigef_cert_date_column', 'Nome da coluna da data do certificado na tabela SIGEF utilizada para processamento', 'data_aprov');

INSERT INTO recorte.params (param_name, param_desc, param_text)
VALUES ('sigef_code_column', 'Nome da coluna com código do imóvel na tabela SIGEF utilizada para processamento', 'codigo_imo');

------------------------------
-- FUNCAO
------------------------------
CREATE OR REPLACE FUNCTION recorte.clean_sigef(
    table_name text,
    key_name text,
    var_date_name text,
    seq_val integer,
    state integer DEFAULT '-1'::integer)
  RETURNS void AS
$BODY$
DECLARE join_clause TEXT = '';
sigef_alias TEXT = CASE WHEN table_name ~ 'snci' THEN '_law' ELSE '_base' END;
BEGIN
IF state != -1 THEN
	join_clause = format('JOIN public.pa_br_limiteestadual_250_2015_ibge b ON "CD_GEOCUF" = %1$L AND ST_Contains(ST_Transform(b.the_geom, 97823), a.geom)', state);
END IF;
	--Validate
	EXECUTE format($$
	DROP TABLE IF EXISTS clean_autooverlay;
	CREATE TEMP TABLE clean_autooverlay AS
	SELECT *, ST_Area(geom) shape_area FROM (
	SELECT a.gid, a.%3$s cod, a.%4$I::date cert_date, ST_CollectionExtract(ST_MakeValid(a.geom),3) geom, ST_IsValid(a.geom) is_valid FROM %1$I a %2$s) b;
	$$, table_name, join_clause, key_name, var_date_name);

	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT seq_val,
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
	SELECT a.gid, a.shape_area 
	FROM clean_autooverlay a
	JOIN clean_autooverlay b ON ST_Equals(a.geom, b.geom) AND a.gid > b.gid;

	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT seq_val,
		operation.id,
		COUNT(*),
		SUM(shape_area)
	FROM log_operation operation,
	equal_shape b
	WHERE operation.nom_operation = 'sigef' || sigef_alias || '_equal_shape'
	GROUP BY operation.id;
	
	DELETE FROM clean_autooverlay a
	USING equal_shape b
	WHERE a.gid = b.gid;

	-- Get intersections
	DROP TABLE IF EXISTS sigef_intersect_temp;
	CREATE TEMP TABLE sigef_intersect_temp AS
	SELECT 
		c1.gid original_gid, c1.cod, c1.shape_area original_area, c1.shape_area, c2.gid gid2, c1.geom geom1, c2.geom geom2, c1.cert_date, c2.cert_date cert_date2
	FROM clean_autooverlay c1
	LEFT JOIN clean_autooverlay c2 ON c1.gid <> c2.gid AND ST_Intersects(c1.geom, c2.geom) AND NOT ST_Touches(c1.geom, c2.geom) AND c1.cert_date < c2.cert_date;

	--Log intersections
	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT seq_val,
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
	(SELECT original_gid, cod, original_area, CASE WHEN MAX(gid2) IS NULL THEN geom1 ELSE ST_Difference(geom1, ST_Buffer(ST_Collect(geom2), 0.01)) END geom, cert_date
	FROM sigef_intersect_temp
	GROUP BY geom1, cod, original_gid, original_area, cert_date) a;

	ALTER TABLE sigef_cleaned
	ADD COLUMN area_loss DECIMAL (7,4);

	UPDATE sigef_cleaned 
	SET area_loss = 100*(1-new_area/original_area::DECIMAL);

	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT seq_val,
		operation.id,
		COUNT(*),
		SUM(original_area)
	FROM log_operation operation,
	sigef_cleaned b
	WHERE operation.nom_operation = 'sigef' || sigef_alias || '_area_loss_gt_95' AND b.area_loss > (SELECT param_value FROM recorte.params WHERE param_name = 'incra_pr_exclusion_tolerance')
	GROUP BY operation.id;

	DELETE FROM sigef_cleaned
	WHERE area_loss > (SELECT param_value FROM recorte.params WHERE param_name = 'incra_pr_exclusion_tolerance');

END $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION recorte.clean_sigef(text, text, text, integer, integer)
  OWNER TO postgres;
------------------------------------------------------------------------

--------------------
-- ROLLBACK
--------------------
-- DELETE FROM recorte.params
-- WHERE param_name IN ('snci_input_table', 'snci_cert_date_column', 'snci_code_column');

-- ALTER TABLE recorte.params 
-- DROP COLUMN param_text;

-- -- Function: recorte.clean_sigef(text, text, text, integer, integer)

-- -- DROP FUNCTION recorte.clean_sigef(text, text, text, integer, integer);

-- CREATE OR REPLACE FUNCTION recorte.clean_sigef(
--     table_name text,
--     key_name text,
--     var_date_name text,
--     seq_val integer,
--     state integer DEFAULT '-1'::integer)
--   RETURNS void AS
-- $BODY$
-- DECLARE join_clause TEXT = '';
-- sigef_alias TEXT = CASE WHEN table_name ~ '2001' THEN '_law' ELSE '_base' END;
-- BEGIN
-- IF state != -1 THEN
-- 	join_clause = format('JOIN public.pa_br_limiteestadual_250_2015_ibge b ON "CD_GEOCUF" = %1$L AND ST_Contains(ST_Transform(b.the_geom, 97823), a.geom)', state);
-- END IF;
-- 	--Validate
-- 	EXECUTE format($$
-- 	DROP TABLE IF EXISTS clean_autooverlay;
-- 	CREATE TEMP TABLE clean_autooverlay AS
-- 	SELECT a.gid, a.%3$s cod, a.%4$I::date cert_date, ST_MakeValid(a.geom) geom, ST_Area(geom) shape_area, ST_IsValid(a.geom) is_valid FROM %1$I a %2$s;
-- 	$$, table_name, join_clause, key_name, var_date_name);

-- 	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
-- 	SELECT seq_val,
-- 		operation.id,
-- 		COUNT(*),
-- 		SUM(shape_area)
-- 	FROM log_operation operation,
-- 	clean_autooverlay b
-- 	WHERE operation.nom_operation = 'sigef' || sigef_alias || '_valid' AND NOT b.is_valid
-- 	GROUP BY operation.id;

		
-- 	CREATE INDEX gix_clean_autooverlay ON clean_autooverlay USING GIST (geom);

-- 	--Clean equal shape
-- 	DROP TABLE IF EXISTS equal_shape;
-- 	CREATE TEMP TABLE equal_shape AS
-- 	SELECT a.gid, a.shape_area 
-- 	FROM clean_autooverlay a
-- 	JOIN clean_autooverlay b ON ST_Equals(a.geom, b.geom) AND a.gid > b.gid;

-- 	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
-- 	SELECT seq_val,
-- 		operation.id,
-- 		COUNT(*),
-- 		SUM(shape_area)
-- 	FROM log_operation operation,
-- 	equal_shape b
-- 	WHERE operation.nom_operation = 'sigef' || sigef_alias || '_equal_shape'
-- 	GROUP BY operation.id;
	
-- 	DELETE FROM clean_autooverlay a
-- 	USING equal_shape b
-- 	WHERE a.gid = b.gid;

-- 	-- Get intersections
-- 	DROP TABLE IF EXISTS sigef_intersect_temp;
-- 	CREATE TEMP TABLE sigef_intersect_temp AS
-- 	SELECT 
-- 		c1.gid original_gid, c1.cod, c1.shape_area original_area, c1.shape_area, c2.gid gid2, c1.geom geom1, c2.geom geom2, c1.cert_date, c2.cert_date cert_date2
-- 	FROM clean_autooverlay c1
-- 	LEFT JOIN clean_autooverlay c2 ON c1.gid <> c2.gid AND ST_Intersects(c1.geom, c2.geom) AND NOT ST_Touches(c1.geom, c2.geom) AND c1.cert_date < c2.cert_date;

-- 	--Log intersections
-- 	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
-- 	SELECT seq_val,
-- 		operation.id,
-- 		COUNT(*),
-- 		SUM(original_area)
-- 	FROM log_operation operation,
-- 	sigef_intersect_temp b
-- 	WHERE operation.nom_operation = 'sigef' || sigef_alias || '_autointersection' AND b.gid2 IS NOT NULL
-- 	GROUP BY operation.id;
	
	
-- 	--Clean priority to small
-- 	DROP TABLE IF EXISTS sigef_cleaned;
-- 	CREATE TEMP TABLE sigef_cleaned AS
-- 	SELECT *, ST_Area(geom) new_area
-- 	FROM
-- 	(SELECT original_gid, cod, original_area, CASE WHEN MAX(gid2) IS NULL THEN geom1 ELSE ST_Difference(geom1, ST_Buffer(ST_Collect(geom2), 0.01)) END geom, cert_date
-- 	FROM sigef_intersect_temp
-- 	GROUP BY geom1, cod, original_gid, original_area, cert_date) a;

-- 	ALTER TABLE sigef_cleaned
-- 	ADD COLUMN area_loss DECIMAL (7,4);

-- 	UPDATE sigef_cleaned 
-- 	SET area_loss = 100*(1-new_area/original_area::DECIMAL);

-- 	INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
-- 	SELECT seq_val,
-- 		operation.id,
-- 		COUNT(*),
-- 		SUM(original_area)
-- 	FROM log_operation operation,
-- 	sigef_cleaned b
-- 	WHERE operation.nom_operation = 'sigef' || sigef_alias || '_area_loss_gt_95' AND b.area_loss > 95
-- 	GROUP BY operation.id;

-- 	DELETE FROM sigef_cleaned
-- 	WHERE area_loss > 95;

-- END $BODY$
--   LANGUAGE plpgsql VOLATILE
--   COST 100;
-- ALTER FUNCTION recorte.clean_sigef(text, text, text, integer, integer)
--   OWNER TO postgres;
