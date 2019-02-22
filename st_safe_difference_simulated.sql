-- Function: public.st_safe_difference_simulate(geometry, geometry)

-- DROP FUNCTION public.st_safe_difference_simulate(geometry, geometry);

CREATE OR REPLACE FUNCTION public.st_safe_difference_simulate(
    geom_a geometry,
    geom_b geometry)
  RETURNS geometry AS
$BODY$
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
$BODY$
  LANGUAGE plpgsql IMMUTABLE STRICT
  COST 100;
ALTER FUNCTION public.st_safe_difference_simulate(geometry, geometry)
  OWNER TO atlas;