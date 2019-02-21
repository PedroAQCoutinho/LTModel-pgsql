--Breaking by municipality
SELECT :var_proc num_proc;
INSERT INTO lt_model.v_pacotes_proc03_breakmun
    SELECT
        a.gid,
        b.cd_mun,
        CASE WHEN ST_Contains(b.geom,a.geom) THEN a.geom
            ELSE ST_Intersection(ST_Buffer(a.geom,0.0001),ST_Buffer(b.geom,0.0001)) 
        END AS geom
    FROM lt_model.v_pacotes_proc02_imoveisfull AS a
    JOIN lt_model.aux_pa_br_municipios_5570 AS b
        ON ST_Intersects(a.geom,b.geom)
    WHERE a.gid % :threads = :var_proc;