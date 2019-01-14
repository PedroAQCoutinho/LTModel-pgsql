-- Function: public.st_safe_difference(geometry, geometry) -- DROP FUNCTION public.st_safe_difference(geometry, geometry); 
CREATE OR REPLACE FUNCTION public.st_safe_difference( geom_a geometry, geom_b geometry) 
    RETURNS geometry AS 
    $BODY$ 
    DECLARE 
      v_error_stack text; 
    BEGIN RETURN ST_Difference(geom_a, geom_b); EXCEPTION
      WHEN OTHERS THEN
        BEGIN geom_a = ST_CollectionExtract(ST_MakeValid(geom_a), 3); geom_b = ST_CollectionExtract(ST_MakeValid(geom_b), 3); RETURN ST_Difference(geom_a, geom_b); EXCEPTION
        WHEN OTHERS THEN
          BEGIN RETURN ST_Difference(geom_a, ST_CollectionExtract(ST_SimplifyPreserveTopology(geom_b), 0.0001, 3)); EXCEPTION
            WHEN OTHERS THEN
              BEGIN RETURN ST_Difference(geom_a, ST_CollectionExtract(ST_Buffer(ST_UnaryUnion(geom_b), 0), 3)); EXCEPTION
              WHEN OTHERS THEN
                BEGIN RETURN ST_Difference(geom_a, ST_CollectionExtract(ST_Buffer(geom_b, -0.01), 3)); EXCEPTION
                WHEN OTHERS THEN
                  BEGIN RETURN ST_Difference(ST_Buffer(geom_a, 0.01), ST_Buffer(geom_b, -0.01)); EXCEPTION
                  WHEN OTHERS THEN
                    BEGIN RETURN ST_Difference(ST_Buffer(geom_a, 0.01), ST_Buffer(geom_b, 0.01)); EXCEPTION
                    WHEN OTHERS THEN
                    BEGIN RETURN 
                      (SELECT ST_Difference(geom_a,
                          ST_Union(a.geom2)) geom
                      FROM 
                          (SELECT ST_CollectionExtract(ST_Buffer((ST_Dump(ST_CollectionExtract(geom_b,
                          3))).geom ,
                          0.01),
                          3) geom2) a
                          WHERE ST_Intersects(geom_a, geom2)
                                  AND NOT ST_Touches(geom_a, geom2)
                          GROUP BY  geom_a); EXCEPTION
                          WHEN OTHERS THEN
                      BEGIN GET STACKED DIAGNOSTICS v_error_stack = PG_EXCEPTION_CONTEXT; 
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
    LANGUAGE plpgsql IMMUTABLE STRICT COST 100; 
    ALTER FUNCTION public.st_safe_difference(geometry, geometry) OWNER TO postgres;