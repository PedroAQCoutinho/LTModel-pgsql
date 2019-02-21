--Breaking by ottobacia
SELECT :var_proc num_proc;
INSERT INTO testes.v_pacotes_proc05_ottobacia
    SELECT
        a.gid,
        a.cd_mun,
        a.cd_bioma,
        b.cobacia,
        CASE WHEN ST_Contains(b.geom,a.geom) THEN a.geom
            ELSE ST_Intersection(ST_Buffer(a.geom,0.0001),ST_Buffer(b.geom,0.0001)) 
        END AS geom
    FROM testes.v_pacotes_proc04_breakbiome AS a
    JOIN geo.recgeo_ottobacias_nivel12_250_ana AS b
        ON ST_Intersects(a.geom,b.geom)
    WHERE a.gid % :threads = :var_proc;

