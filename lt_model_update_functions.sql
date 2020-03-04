CREATE OR REPLACE FUNCTION lt_model.proc0_insert_all_into_result(
    var_table_name text,
    var_input lt_model.inputs,
    var_envelope text)
  RETURNS void AS
$BODY$
DECLARE geom_name TEXT = (select column_name from information_schema.columns WHERE table_name = var_table_name AND udt_name = 'geometry');
BEGIN
	SET search_path TO public, lt_model;
	RAISE NOTICE 'Inserting all geometries from %...', var_table_name;
		IF var_envelope != '' THEN
			EXECUTE FORMAT($$
					INSERT INTO lt_model.result(table_source, ownership_class, sub_class, area_original, geom, original_gid, area)
					SELECT *, area_original area 
					FROM (SELECT %1$L table_source, %2$L ownership_class, %3$L sub_class, ST_Area(%4$I) area_original, ST_Multi(ST_Force2D(%4$I)) geom, original_gid original_gid
					FROM %1$I
					WHERE ST_Intersects(%4$I, ST_GeomFromText(%5$L, 97823))) t
				$$, var_table_name, var_input.ownership_class, var_input.sub_class, geom_name, var_envelope);
		ELSE
			EXECUTE FORMAT($$
					INSERT INTO lt_model.result(table_source, ownership_class, sub_class, area_original, geom, original_gid, area)
					SELECT *, area_original area 
					FROM (SELECT %1$L table_source, %2$L ownership_class, %3$L sub_class, ST_Area(%4$I) area_original, ST_Multi(ST_Force2D(%4$I)) geom, original_gid original_gid
					FROM %1$I
					) t
				$$, var_table_name, var_input.ownership_class, var_input.sub_class, geom_name);
		END IF;
	ANALYZE lt_model.result;
	RAISE NOTICE 'Insertion of % completed!', var_table_name;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION lt_model.proc0_insert_all_into_result(text, lt_model.inputs, text)
  OWNER TO atlas;
  
CREATE OR REPLACE FUNCTION lt_model.proc0_insert_all_into_result(
    var_table_name text,
    var_input lt_model.inputs,
    var_envelope text,
    var_num_proc integer,
    var_proc integer)
  RETURNS void AS
$BODY$
DECLARE geom_name TEXT = (select column_name from information_schema.columns WHERE table_name = var_table_name AND udt_name = 'geometry');
BEGIN
	SET search_path TO public, lt_model;
	RAISE NOTICE 'Inserting all geometries from %...', var_table_name;
		IF var_envelope != '' THEN
			EXECUTE FORMAT($$
					INSERT INTO lt_model.result(table_source, ownership_class, sub_class, area_original, geom, original_gid, area)
					SELECT *, area_original area 
					FROM (SELECT %1$L table_source, %2$L ownership_class, %3$L sub_class, ST_Area(%4$I) area_original, ST_Multi(ST_Force2D(%4$I)) geom, original_gid original_gid
					FROM %1$I
					WHERE (gid %% %6$L) = %7$L AND ST_Intersects(%4$I, ST_GeomFromText(%5$L, 97823))) t
				$$, var_table_name, var_input.ownership_class, var_input.sub_class, geom_name, var_envelope, var_num_proc, var_proc);
		ELSE
			EXECUTE FORMAT($$
					INSERT INTO lt_model.result(table_source, ownership_class, sub_class, area_original, geom, original_gid, area)
					SELECT *, area_original area 
					FROM (SELECT %1$L table_source, %2$L ownership_class, %3$L sub_class, ST_Area(%4$I) area_original, ST_Multi(ST_Force2D(%4$I)) geom, original_gid original_gid
					FROM %1$I
					WHERE (gid %% %5$L) = %6$L) t
				$$, var_table_name, var_input.ownership_class, var_input.sub_class, geom_name, var_num_proc, var_proc);
		END IF;
	ANALYZE lt_model.result;
	RAISE NOTICE 'Insertion of % completed!', var_table_name;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION lt_model.proc0_insert_all_into_result(text, lt_model.inputs, text, integer, integer)
  OWNER TO atlas;
  
  CREATE OR REPLACE FUNCTION lt_model.proc0_update_intersection(
    var_input lt_model.inputs,
    var_table_name text)
  RETURNS void AS
$BODY$
BEGIN
	SET search_path TO public, lt_model;
	RAISE NOTICE 'Erasing features which intersect with % and calculating area loss...', var_table_name; 

	EXECUTE FORMAT($$
		UPDATE lt_model.result a
		SET 
		geom = NULL::geometry, 
		%3$I = a.area,
		area = 0
		FROM %1$I b
		WHERE ST_Contains(b.geom, a.geom);


		-- DELETE FROM lt_model.result a
-- 		USING %1$I b
-- 		WHERE ST_Intersects(b.geom, a.geom) AND NOT ST_Touches(b.geom, a.geom) AND a.sub_class = %2$L;
	$$, var_table_name, var_input.sub_class, LOWER(var_input.sub_class) || '_area_loss');


	EXECUTE FORMAT($$
			DROP TABLE IF EXISTS tmp_atualiza;
			CREATE TEMP TABLE tmp_atualiza AS (
			SELECT 
				r.gid gid, 
				r.sub_class,
				ST_Force2D(ST_CollectionExtract(ST_Safe_Difference(r.geom, ST_Collect(m.geom)), 3)) geom,
				r.area previous_area
			FROM lt_model.result r
			JOIN lt_model.%1$I m ON NOT ST_IsEmpty(m.geom) AND ST_Intersects(r.geom, m.geom)
			GROUP BY r.gid, r.geom, r.area, r.sub_class);
	$$, var_table_name, LOWER(var_input.sub_class) || '_area_loss', var_input.sub_class);
	RAISE NOTICE 'Created tmp_atualiza';
	ALTER TABLE tmp_atualiza
	ADD COLUMN current_area NUMERIC;

	UPDATE tmp_atualiza
	SET current_area = ST_Area(geom);
	RAISE NOTICE 'Area calculated';
	EXECUTE FORMAT($$		
		UPDATE lt_model.result r
		SET 
			geom = ST_Multi(ST_CollectionExtract(CASE WHEN ST_IsValid(A.geom) THEN A.geom ELSE ST_MakeValid(A.geom) END, 3)), 
			%2$I = CASE WHEN A.sub_class = %3$L THEN NULL ELSE CASE WHEN %2$I IS NULL THEN 0 ELSE %2$I END + (previous_area - current_area) END,
			area = current_area
		FROM tmp_atualiza A
		WHERE r.gid = A.gid;
	$$, var_table_name, LOWER(var_input.sub_class) || '_area_loss', var_input.sub_class);


	--DELETE FROM lt_model.result WHERE ST_IsEmpty(geom);
	ANALYZE lt_model.result;
	RAISE NOTICE 'Erasing intersection with % completed!', var_table_name; 
END 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION lt_model.proc0_update_intersection(lt_model.inputs, text)
  OWNER TO atlas;
  
CREATE OR REPLACE FUNCTION lt_model.proc0_update_intersection(
    var_input lt_model.inputs,
    var_table_name text,
    var_num_proc integer,
    var_proc integer)
  RETURNS void AS
$BODY$
BEGIN
	SET search_path TO public, lt_model;
	RAISE NOTICE 'Erasing features which intersect with % and calculating area loss...', var_table_name; 


	EXECUTE FORMAT($$
		INSERT INTO lt_model.result_temp
		SELECT 
			A.gid,
			ST_Multi(ST_CollectionExtract(CASE WHEN ST_IsValid(A.geom) THEN A.geom ELSE ST_MakeValid(A.geom) END, 3)) geom, 
			CASE WHEN A.sub_class = %3$L THEN NULL ELSE CASE WHEN %2$I IS NULL THEN 0 ELSE %2$I END + (previous_area - current_area) END area_loss,
			current_area area
		FROM (
			SELECT *, ST_Area(B.geom) current_area
			FROM (
			SELECT 
				r.gid, 
				r.sub_class,
				ST_Force2D(CASE WHEN COUNT(m.gid) = 1 THEN
					ST_Difference(r.geom, ST_GeometryN(ST_Collect(m.geom), 1))
				ELSE
					ST_CollectionExtract(ST_Safe_Difference(r.geom, ST_Collect(m.geom)), 3)
				END) geom,
				r.area previous_area,
				%2$I
			FROM lt_model.result r
			JOIN lt_model.%1$I m ON NOT ST_IsEmpty(m.geom) AND ST_IsValid(m.geom) AND ST_Intersects(r.geom, m.geom) AND (r.gid %% %4$L) = %5$L
			GROUP BY r.gid, r.geom, r.area, r.sub_class, %2$I) B
			) A
		WHERE (A.gid %% %4$L) = %5$L
	$$, var_table_name, LOWER(var_input.sub_class) || '_area_loss', var_input.sub_class, var_num_proc, var_proc);


	ANALYZE lt_model.result;
	RAISE NOTICE 'Erasing intersection with % completed!', var_table_name; 
END 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION lt_model.proc0_update_intersection(lt_model.inputs, text, integer, integer)
  OWNER TO atlas;
  
CREATE OR REPLACE FUNCTION lt_model.simplify_if_needed(var_input lt_model.inputs)
  RETURNS text AS
$BODY$
DECLARE var_table_name TEXT = var_input.table_name;
DECLARE var_table_simplify TEXT = lt_model.simplify_multipolygon_name(LEFT(var_table_name, 63));
DECLARE var_test BOOLEAN;
DECLARE geom_name TEXT;
DECLARE columns_not_gid TEXT;
DECLARE where_clause TEXT = CASE WHEN var_input.where_clause IS NOT NULL AND var_input.where_clause != '' THEN ' AND ' || var_input.where_clause ELSE '' END;
BEGIN
	EXECUTE format($$SELECT column_name FROM information_schema.columns WHERE table_name = %L AND udt_name = 'geometry'$$, var_table_name) INTO geom_name;
	SELECT true INTO var_test;
	IF var_test THEN
		RAISE INFO 'Simplifying multipolygon in %...', var_table_name;
		EXECUTE FORMAT($$SELECT string_agg('"' || column_name || '"', ', ')
			FROM (
				SELECT DISTINCT column_name 
				FROM information_schema.columns 
				WHERE table_name = %L 
					AND column_name NOT IN ('gid', %L)) A$$
		, var_table_name, geom_name) INTO columns_not_gid;

		EXECUTE format($$
				DROP TABLE IF EXISTS "lt_model".%1$I;
				CREATE TABLE IF NOT EXISTS "lt_model".%1$I AS 
				-- Testing NO SIMPLIFY
				-- SELECT (row_number() OVER ())::INT gid, *
				-- FROM (
-- 					SELECT gid original_gid, %2$s, ST_CollectionExtract(ST_MakeValid((ST_DUMP(ST_Force2D(%3$I))).geom), 3) geom
-- 					FROM %4$I
-- 					WHERE true %6$s
-- 					) A;
				SELECT (row_number() OVER ())::INT gid, *
				FROM (
					SELECT gid original_gid, %2$s, ST_CollectionExtract(ST_MakeValid((ST_Force2D(%3$I))), 3) geom
					FROM %4$I
					WHERE true %6$s
					) A;
				CREATE INDEX IF NOT EXISTS ix_%5$s ON "lt_model".%1$I USING GIST (geom)
			$$, var_table_simplify, columns_not_gid, geom_name, var_table_name, LEFT(var_table_simplify, 60), where_clause);
		RAISE INFO 'Multipolygon to Polygon of % completed!', var_table_name;
		RETURN var_table_simplify;
	END IF;

	
	RETURN var_table_name;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION lt_model.simplify_if_needed(lt_model.inputs)
  OWNER TO atlas;
  
CREATE OR REPLACE FUNCTION lt_model.simplify_if_needed(
    var_input lt_model.inputs,
    var_replace boolean)
  RETURNS text AS
$BODY$
DECLARE var_table_name TEXT = var_input.table_name;
DECLARE var_table_simplify TEXT = lt_model.simplify_multipolygon_name(LEFT(var_table_name, 63));
DECLARE var_test BOOLEAN;
DECLARE geom_name TEXT;
DECLARE columns_not_gid TEXT;
DECLARE where_clause TEXT = CASE WHEN var_input.where_clause IS NOT NULL AND var_input.where_clause != '' THEN ' AND ' || var_input.where_clause ELSE '' END;
BEGIN
	EXECUTE format($$SELECT column_name FROM information_schema.columns WHERE table_name = %L AND udt_name = 'geometry'$$, var_table_name) INTO geom_name;
	SELECT true INTO var_test;
	IF var_test THEN
		RAISE INFO 'Simplifying multipolygon in %...', var_table_name;
		EXECUTE FORMAT($$SELECT string_agg('"' || column_name || '"', ', ')
			FROM (
				SELECT DISTINCT column_name 
				FROM information_schema.columns 
				WHERE table_name = %L 
					AND column_name NOT IN ('gid', %L)) A$$
		, var_table_name, geom_name) INTO columns_not_gid;

		EXECUTE format($$
				CREATE TABLE IF NOT EXISTS "lt_model".%1$I AS 
				SELECT (row_number() OVER ())::INT gid, *
				FROM (
					SELECT gid original_gid, %2$s, ST_CollectionExtract(ST_MakeValid((ST_DUMP(ST_Force2D(%3$I))).geom), 3) geom
					FROM %4$I
					WHERE true %6$s
					) A;
				CREATE INDEX IF NOT EXISTS ix_%5$s ON "lt_model".%1$I USING GIST (geom)
			$$, var_table_simplify, columns_not_gid, geom_name, var_table_name, LEFT(var_table_simplify, 60), where_clause);
		RAISE INFO 'Multipolygon to Polygon of % completed!', var_table_name;
		RETURN var_table_simplify;
	END IF;

	
	RETURN var_table_name;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION lt_model.simplify_if_needed(lt_model.inputs, boolean)
  OWNER TO atlas;