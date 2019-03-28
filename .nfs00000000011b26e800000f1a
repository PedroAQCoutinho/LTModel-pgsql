--Breaking by municipality
SELECT :var_proc num_proc;
INSERT INTO lt_model.v_pacotes_proc04_flagprop
    SELECT
        a.gid,
        b.cd_mun,
        b.cd_bioma,
        b.cd_bacia,
        CASE WHEN ST_Contains(b.geom,a.geom) THEN a.geom
            ELSE ST_Intersection(ST_Buffer(a.geom,0.0001),ST_Buffer(b.geom,0.0001)) 
        END AS geom
    FROM lt_model.:ltenure AS a
    JOIN lt_model.v_pacotes_proc02_ottobacia AS b
        ON ST_Intersects(a.geom,b.geom)
    WHERE b.cd_mun % :threads = :var_proc;