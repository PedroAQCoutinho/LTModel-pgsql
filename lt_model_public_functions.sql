CREATE OR REPLACE FUNCTION public.st_safe_difference(geom_a geometry, geom_b geometry)
 RETURNS geometry
 LANGUAGE plpgsql
 IMMUTABLE STRICT
AS $function$
DECLARE
    v_error_stack text;
BEGIN
    RETURN ST_Difference(geom_a, geom_b);
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
		geom_a = ST_CollectionExtract(ST_MakeValid(geom_a), 3);
		geom_b = ST_CollectionExtract(ST_MakeValid(geom_b), 3);
                RETURN ST_Difference(geom_a, geom_b);
                EXCEPTION
                WHEN OTHERS THEN
		    BEGIN
			RETURN ST_Difference(geom_a, ST_CollectionExtract(ST_SimplifyPreserveTopology(geom_b), 0.0001, 3));
			EXCEPTION
			WHEN OTHERS THEN
			    BEGIN
				RETURN ST_Difference(geom_a, ST_CollectionExtract(ST_Buffer(ST_UnaryUnion(geom_b), 0), 3));
				EXCEPTION
				WHEN OTHERS THEN
				    BEGIN
					RETURN ST_Difference(geom_a, ST_CollectionExtract(ST_Buffer(geom_b, -0.01), 3));
					EXCEPTION
					WHEN OTHERS THEN
					    BEGIN
						RETURN ST_Difference(ST_Buffer(geom_a, 0.01), ST_Buffer(geom_b, -0.01));
						EXCEPTION
						WHEN OTHERS THEN
						    BEGIN
							RETURN ST_Difference(ST_Buffer(geom_a, 0.01), ST_Buffer(geom_b, 0.01));
							EXCEPTION
							WHEN OTHERS THEN
							    BEGIN
								RETURN (SELECT ST_Difference(geom_a, ST_Union(a.geom2)) geom FROM (SELECT ST_CollectionExtract(ST_Buffer((ST_Dump(ST_CollectionExtract(geom_b, 3))).geom ,0.01),3) geom2) a WHERE ST_Intersects(geom_a, geom2) AND NOT ST_Touches(geom_a, geom2) GROUP BY geom_a);
								EXCEPTION
								WHEN OTHERS THEN
								    BEGIN
									GET STACKED DIAGNOSTICS v_error_stack = PG_EXCEPTION_CONTEXT;
									RAISE NOTICE 'Error difference geom_a: %', geom_a;
									RAISE NOTICE 'Error difference geom_b: %', geom_b;
									RAISE EXCEPTION 'Stack trace: "%"', v_error_stack;
								    END; 
								END;
						    END;
					    END;
					END;
				END;
			END;
		END;
END
$function$;

CREATE OR REPLACE FUNCTION public.st_safe_difference_simulate(geom_a geometry, geom_b geometry)
 RETURNS geometry
 LANGUAGE plpgsql
 IMMUTABLE STRICT
AS $function$
DECLARE
    v_error_stack text;
    geom_c GEOMETRY[];
    geom_d GEOMETRY;
BEGIN
    geom_c = (SELECT ST_Accum(geom2) FROM (SELECT (ST_Dump(geom_b)).geom geom2) a WHERE ST_Intersects(geom2, geom_a) AND NOT ST_Touches(geom2, geom_a));
    geom_d =  ST_Buffer(ST_Collect(geom_c), 0);
    RETURN ST_Difference(geom_a, geom_d);
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
		geom_d =  ST_Buffer(ST_Collect(geom_c), 0);
                RETURN ST_Difference(geom_a, geom_d);
                EXCEPTION
                WHEN OTHERS THEN
		    BEGIN
			geom_d =  ST_Union(ST_Buffer(a,0.01)) FROM unnest(geom_c) a;
			RETURN ST_Difference(geom_a, geom_d);
			EXCEPTION
			WHEN OTHERS THEN
			    BEGIN
			        geom_b = ST_Collect(geom_c);
				RETURN ST_Difference(geom_a, ST_CollectionExtract(ST_Buffer(ST_UnaryUnion(geom_b), 0), 3));
				EXCEPTION
				WHEN OTHERS THEN
				    BEGIN
					RETURN ST_Difference(geom_a, ST_CollectionExtract(ST_Buffer(geom_b, -0.01), 3));
					EXCEPTION
					WHEN OTHERS THEN
					    BEGIN
						RETURN ST_Difference(ST_Buffer(geom_a, 0.01), ST_Buffer(geom_b, -0.01));
						EXCEPTION
						WHEN OTHERS THEN
						    BEGIN
							RETURN ST_Difference(ST_Buffer(geom_a, 0.01), ST_Buffer(geom_b, 0.01));
							EXCEPTION
							WHEN OTHERS THEN
							    BEGIN
								RETURN (SELECT ST_Difference(geom_a, ST_Union(a.geom2)) geom FROM (SELECT ST_CollectionExtract(ST_Buffer((ST_Dump(ST_CollectionExtract(geom_b, 3))).geom ,0.01),3) geom2) a WHERE ST_Intersects(geom_a, geom2) AND NOT ST_Touches(geom_a, geom2) GROUP BY geom_a);
								EXCEPTION
								WHEN OTHERS THEN
								    BEGIN
									GET STACKED DIAGNOSTICS v_error_stack = PG_EXCEPTION_CONTEXT;
									RAISE NOTICE 'Error difference geom_a: %', geom_a;
									RAISE NOTICE 'Error difference geom_b: %', geom_b;
									RAISE EXCEPTION 'Stack trace: "%"', v_error_stack;
								    END; 
								END;
						    END;
					    END;
					END;
				END;
			END;
		END;
END
$function$;

CREATE OR REPLACE FUNCTION public.st_safe_intersection(geom_a geometry, geom_b geometry)
 RETURNS geometry
 LANGUAGE plpgsql
 IMMUTABLE STRICT
AS $function$
DECLARE
    v_error_stack text;
BEGIN
    RETURN ST_Intersection(geom_a, geom_b);
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
		geom_a = ST_CollectionExtract(ST_MakeValid(geom_a), 3);
		geom_b = ST_CollectionExtract(ST_MakeValid(geom_b), 3);
                RETURN ST_Intersection(geom_a, geom_b);
                EXCEPTION
                WHEN OTHERS THEN
		    BEGIN
			RETURN ST_Intersection(geom_a, ST_CollectionExtract(ST_SimplifyPreserveTopology(geom_b), 0.0001, 3));
			EXCEPTION
			WHEN OTHERS THEN
			    BEGIN
				RETURN ST_Intersection(geom_a, ST_CollectionExtract(ST_Buffer(ST_UnaryUnion(geom_b), 0), 3));
				EXCEPTION
				WHEN OTHERS THEN
				    BEGIN
					RETURN ST_Intersection(geom_a, ST_CollectionExtract(ST_Buffer(geom_b, -0.01), 3));
					EXCEPTION
					WHEN OTHERS THEN
					    BEGIN
						RETURN ST_Intersection(ST_Buffer(geom_a, 0.01), ST_Buffer(geom_b, -0.01));
						EXCEPTION
						WHEN OTHERS THEN
						    BEGIN
							RETURN ST_Intersection(ST_Buffer(geom_a, 0.01), ST_Buffer(geom_b, 0.01));
							EXCEPTION
							WHEN OTHERS THEN
							    BEGIN
								RETURN (SELECT ST_Intersection(geom_a, ST_Union(a.geom2)) geom FROM (SELECT ST_CollectionExtract(ST_Buffer((ST_Dump(ST_CollectionExtract(geom_b, 3))).geom ,0.01),3) geom2) a WHERE ST_Intersects(geom_a, geom2) AND NOT ST_Touches(geom_a, geom2) GROUP BY geom_a);
								EXCEPTION
								WHEN OTHERS THEN
								    BEGIN
									GET STACKED DIAGNOSTICS v_error_stack = PG_EXCEPTION_CONTEXT;
									RAISE NOTICE 'Error intersection geom_a: %', geom_a;
									RAISE NOTICE 'Error intersection geom_b: %', geom_b;
									RAISE EXCEPTION 'Stack trace: "%"', v_error_stack;
								    END; 
								END;
						    END;
					    END;
					END;
				END;
			END;
		END;
END
$function$;

CREATE OR REPLACE FUNCTION public.st_safe_intersects(geom_a geometry, geom_b geometry)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE STRICT
AS $function$
DECLARE
    v_error_stack text;
BEGIN
    RETURN ST_Intersects(geom_a, geom_b);
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
		geom_a = ST_CollectionExtract(ST_MakeValid(geom_a), 3);
		geom_b = ST_CollectionExtract(ST_MakeValid(geom_b), 3);
                RETURN ST_Intersects(geom_a, geom_b);
                EXCEPTION
                WHEN OTHERS THEN
		    BEGIN
			RETURN ST_Intersects(geom_a, ST_CollectionExtract(ST_SimplifyPreserveTopology(geom_b), 0.0001, 3));
			EXCEPTION
			WHEN OTHERS THEN
			    BEGIN
				RETURN ST_Intersects(geom_a, ST_CollectionExtract(ST_Buffer(ST_UnaryUnion(geom_b), 0), 3));
				EXCEPTION
				WHEN OTHERS THEN
				    BEGIN
					RETURN ST_Intersects(geom_a, ST_CollectionExtract(ST_Buffer(geom_b, -0.01), 3));
					EXCEPTION
					WHEN OTHERS THEN
					    BEGIN
						RETURN ST_Intersects(ST_Buffer(geom_a, 0.01), ST_Buffer(geom_b, -0.01));
						EXCEPTION
						WHEN OTHERS THEN
						    BEGIN
							RETURN ST_Intersects(ST_Buffer(geom_a, 0.01), ST_Buffer(geom_b, 0.01));
							EXCEPTION
							WHEN OTHERS THEN
							    BEGIN
								RETURN (SELECT ST_Intersects(geom_a, ST_Union(a.geom2)) geom FROM (SELECT ST_CollectionExtract(ST_Buffer((ST_Dump(ST_CollectionExtract(geom_b, 3))).geom ,0.01),3) geom2) a WHERE ST_Intersects(geom_a, geom2) AND NOT ST_Touches(geom_a, geom2) GROUP BY geom_a);
								EXCEPTION
								WHEN OTHERS THEN
								    BEGIN
									GET STACKED DIAGNOSTICS v_error_stack = PG_EXCEPTION_CONTEXT;
									RAISE NOTICE 'Error intersects geom_a: %', geom_a;
									RAISE NOTICE 'Error intersects geom_b: %', geom_b;
									RAISE EXCEPTION 'Stack trace: "%"', v_error_stack;
								    END; 
								END;
						    END;
					    END;
					END;
				END;
			END;
		END;
END
$function$;






CREATE OR REPLACE FUNCTION lt_model.st_makevalidsnapping(geom geometry)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE
AS $function$
SELECT ST_CollectionExtract(ST_MakeValid(ST_SnapToGrid(geom, 1e-6)), 3);
$function$
;



CREATE OR REPLACE FUNCTION lt_model.eliminate_car()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	DROP TABLE IF EXISTS temp_bounds_big; 
	CREATE TEMP TABLE temp_bounds_big AS --5s --
	SELECT DISTINCT a.rid, (ST_Dump(ST_ExteriorRing(a.geom))).geom::geometry(Linestring, 97823) geom, a.fla_eliminate
	FROM proc1_11_temp_car_consolidated a;

	CREATE INDEX gix_temp_bounds_big ON temp_bounds_big USING GIST (geom); --3.7s
	CREATE INDEX gix_temp_bounds_big_eliminate ON temp_bounds_big USING BTREE (fla_eliminate); --0.3s

	DROP TABLE IF EXISTS temp_small_points CASCADE;
	CREATE TABLE IF NOT EXISTS temp_small_points AS
	SELECT rid, (dump).path[1] ind, (dump).path[2] ind2, (dump).geom
	FROM (SELECT DISTINCT a.rid, (ST_DumpPoints(a.geom)) dump, a.fla_eliminate
	FROM proc1_09_car_single a
	WHERE fla_eliminate) b;

	CREATE INDEX gix_temp_small_points ON temp_small_points USING GIST (geom);
	CREATE INDEX ix_temp_small_points_1 ON temp_small_points USING BTREE (ind);
	CREATE INDEX ix_temp_small_points_2 ON temp_small_points USING BTREE (ind2); 
	CREATE INDEX ix_temp_small_points_3 ON temp_small_points USING BTREE (rid); 
	
	

	CREATE OR REPLACE VIEW v_temp_small_points AS
	SELECT a.* 
	FROM temp_small_points a
	LEFT JOIN temp_already_process b ON a.rid = b.small
	WHERE b.small IS NULL;

	DROP TABLE IF EXISTS temp_small_big_touching;
	CREATE TEMP TABLE temp_small_big_touching AS -- 25.2s
	SELECT DISTINCT a.rid small, b.rid big
	FROM v_temp_small_points a
	JOIN temp_bounds_big b ON ST_DWithin(a.geom, b.geom, 0);

	CREATE INDEX ix_temp_small_big_touching ON temp_small_big_touching USING BTREE (small, big); --50ms


	-- Create table with nodes that are within 20m from consolidated CAR
	DROP TABLE IF EXISTS temp_small_points2; --16.6s --22.5s
	CREATE TEMP TABLE temp_small_points2 AS
	SELECT small.rid small, big.rid big, ind, ind2, small.geom geom
	FROM temp_small_big_touching touch 
	JOIN v_temp_small_points small ON small.rid = touch.small
	JOIN temp_bounds_big big ON ST_DWithin(small.geom, big.geom, 20) AND big.rid = touch.big
	WHERE NOT big.fla_eliminate;

	CREATE INDEX gix_temp_small_points2 ON temp_small_points2 USING BTREE (small, big, ind, ind2); --681ms
	
	-- Create lines from points and get id pairs of consolidated/eliminate where length is maximum
	DROP TABLE IF EXISTS temp_max_intersect; 
	CREATE TEMP TABLE temp_max_intersect AS --8.4s --10.2s --5.5s
	WITH connected_points AS
	(SELECT DISTINCT A.small, A.big, A.ind, A.ind2, A.geom
	FROM temp_small_points2 A
	JOIN temp_small_points2 B ON A.small = B.small AND A.big = B.big AND A.ind = B.ind AND (A.ind2 = (B.ind2 -1) OR A.ind2 = (B.ind2 + 1))
	ORDER BY A.small, A.big, A.ind, A.ind2),
	linestrings AS
	(SELECT small, big, ST_MakeLine(geom) geom
	FROM connected_points
	GROUP BY small, big)
	SELECT DISTINCT ON (A.small) A.small, A.big, geom
	FROM linestrings A
	ORDER BY A.small, ST_Length(A.geom) DESC;

	INSERT INTO temp_already_process
	SELECT DISTINCT small FROM temp_max_intersect;
	

	-- Union of consolidated + all eliminates associated
	UPDATE proc1_11_temp_car_consolidated a -- 21.9s -- 14.9s
 	SET geom = ST_CollectionExtract(ST_MakeValid(ST_Union(a.geom, d.geom)), 3)
 	FROM (SELECT b.big rid, ST_Buffer(ST_Collect(c.geom), 0.01) geom
	FROM temp_max_intersect b
		JOIN proc1_09_car_single c ON b.small = c.rid
	GROUP BY b.big) d
	WHERE d.rid = a.rid;
END
$function$
;



CREATE OR REPLACE FUNCTION lt_model.eliminate_car_recursive()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
	CREATE INDEX IF NOT EXISTS gix_temp_car_consolidated ON proc1_11_temp_car_consolidated USING GIST (geom);

	CREATE OR REPLACE VIEW v_temp_small_points AS
	SELECT a.* 
	FROM temp_small_points a
	LEFT JOIN temp_already_process b ON a.rid = b.small
	WHERE b.small IS NULL;

	DROP TABLE IF EXISTS temp_small_big_touching;
	CREATE TEMP TABLE temp_small_big_touching AS -- 25.2s
	SELECT DISTINCT a.rid small, b.rid big
	FROM v_temp_small_points a
	JOIN proc1_11_temp_car_consolidated b ON ST_DWithin(a.geom, b.geom, 0);

	

	CREATE INDEX ix_temp_small_big_touching ON temp_small_big_touching USING BTREE (small, big); --50ms

	DROP TABLE IF EXISTS temp_max_intersect; 
	CREATE TEMP TABLE temp_max_intersect AS --8.4s --10.2s --5.5s
	SELECT DISTINCT ON (touch.small) touch.small, touch.big
	FROM proc1_09_car_single small
	JOIN temp_small_big_touching touch ON small.rid = touch.small
	JOIN proc1_11_temp_car_consolidated big ON big.rid = touch.big
	WHERE small.fla_eliminate
	ORDER BY touch.small, ST_Area(ST_Intersection(small.geom, big.geom)) DESC;
	

	INSERT INTO temp_already_process
	SELECT DISTINCT small FROM temp_max_intersect;

	UPDATE proc1_11_temp_car_consolidated a -- 21.9s -- 14.9s
-- 	SET geom = ST_MakeValidSnapping(ST_Union(a.geom, d.geom))
	SET geom = ST_CollectionExtract(ST_MakeValid(ST_Union(a.geom, ST_CollectionExtract(ST_MakeValid(d.geom), 3))), 3)
-- 	FROM (SELECT b.big rid, ST_MakeValidSnapping(ST_Collect(c.geom)) geom
	FROM (SELECT b.big rid, ST_Buffer(ST_Collect(c.geom), 0.01) geom
	FROM temp_max_intersect b
		JOIN proc1_09_car_single c ON b.small = c.rid
	GROUP BY b.big) d
	WHERE d.rid = a.rid;

	RETURN (SELECT COUNT(DISTINCT small) FROM temp_max_intersect);
END
$function$
;


CREATE OR REPLACE FUNCTION lt_model.clean_sigef(table_name text, key_name text, var_date_name text, seq_val integer, state integer DEFAULT '-1'::integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
	WHERE operation.nom_operation = 'sigef' || sigef_alias || '_area_loss_gt_95' AND b.area_loss > (SELECT param_value FROM lt_model.params WHERE param_name = 'incra_pr_exclusion_tolerance')
	GROUP BY operation.id;

	DELETE FROM sigef_cleaned
	WHERE area_loss > (SELECT param_value FROM lt_model.params WHERE param_name = 'incra_pr_exclusion_tolerance');

END $function$
;




CREATE OR REPLACE FUNCTION lt_model.add_layer(var_table_name text, var_sub_class text, var_cd_uf integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE var_input lt_model.inputs;
DECLARE var_envelope TEXT = CASE WHEN var_cd_uf = -1 THEN '' ELSE (SELECT ST_AsText(ST_Envelope(ST_Transform(geom, 97823))) FROM lt_model.aux_pa_br_estados WHERE cd_uf = var_cd_uf) END;
BEGIN
RAISE NOTICE 'Running: %', var_table_name;
var_table_name = LEFT(LOWER(var_table_name), 63);
SELECT * INTO var_input FROM lt_model.inputs WHERE table_name = var_table_name AND sub_class = var_sub_class;



		-- If is Multipolygon simplify
		var_table_name = lt_model.simplify_if_needed(var_input);


		IF (SELECT COUNT(*) FROM lt_model.result) > 0 THEN
			PERFORM lt_model.proc0_update_intersection(var_input, var_table_name);
			IF NOT EXISTS (SELECT table_source FROM lt_model.result WHERE table_source = var_table_name AND sub_class = var_sub_class) THEN
				PERFORM lt_model.proc0_insert_all_into_result(var_table_name, var_input, var_envelope);
			END IF;
		ELSE
			PERFORM lt_model.proc0_insert_all_into_result(var_table_name, var_input, var_envelope);
		END IF;
		RAISE NOTICE 'Finished at: %', clock_timestamp();
END $function$
;



CREATE OR REPLACE FUNCTION lt_model.run_statement(uf_code integer DEFAULT '-1'::integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE result TEXT;
BEGIN
CLUSTER lt_model.inputs;
SELECT 'SET search_path TO lt_model, public;SELECT clock_timestamp();DROP TABLE lt_model.result;SELECT lt_model.create_result();' || string_agg(format($$SELECT lt_model.add_layer('%s', '%s', %s)$$, table_name, sub_class, uf_code), ';') || ';SELECT clock_timestamp();' INTO result 
FROM lt_model.inputs
WHERE fla_proc;
RETURN result;
END $function$
;


CREATE OR REPLACE FUNCTION lt_model.simplify_multipolygon_name(var_table_name text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
	SELECT LEFT(regexp_replace(var_table_name, '(_[^_]*_*)$', '_sim\1'), 63);
$function$
;



CREATE OR REPLACE FUNCTION lt_model.create_result()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
CREATE TABLE lt_model.result
(
  gid SERIAL PRIMARY KEY,
  table_source text,
  ownership_class text,
  sub_class text,
  area_original numeric(30,4),
  original_gid bigint,
  geom geometry(MultiPolygon,97823),
  area numeric(30,4),
  ag_area_loss numeric(30,2),
  aru_area_loss numeric(30,2),
  carpo_area_loss numeric(30,2),
  carpr_area_loss numeric(30,2),
  com_area_loss numeric(30,2),
  ml_area_loss numeric(30,2),
  nd_b_area_loss numeric(30,2),
  nd_i_area_loss numeric(30,2),
  ql_area_loss numeric(30,2),
  sigef_area_loss numeric(30,2),
  ti_h_area_loss numeric(30,2),
  ti_n_area_loss numeric(30,2),
  tlpc_area_loss numeric(30,2),
  tlpl_area_loss numeric(30,2),
  trans_area_loss numeric(30,2),
  ucpi_area_loss numeric(30,2),
  ucus_area_loss numeric(30,2),
  urb_area_loss numeric(30,2),
  cd_mun_2006 integer,
  rast integer
)
WITH (
  OIDS=FALSE
);


-- Index: lt_model.gix_result

-- DROP INDEX lt_model.gix_result;

CREATE INDEX gix_result
  ON lt_model.result
  USING gist
  (geom);

END $function$
;


CREATE OR REPLACE FUNCTION lt_model.simplify_if_needed(var_input lt_model.inputs)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
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
$function$
;