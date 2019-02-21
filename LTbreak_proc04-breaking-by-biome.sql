--Breaking by biome
SELECT :var_proc num_proc;
INSERT INTO testes.v_pacotes_proc04_breakbiome
    SELECT
        a.gid,
        a.cd_mun,
        b.id_bioma,
        CASE WHEN ST_Contains(b.geom,a.geom) THEN a.geom
            ELSE ST_Intersection(ST_Buffer(a.geom,0.0001),ST_Buffer(b.geom,0.0001)) 
        END AS geom
    FROM testes.v_pacotes_proc03_breakmun AS a
    JOIN luga_inputs.aux_biomas_mapbiomas AS b
        ON ST_Intersects(a.geom,b.geom)
    WHERE a.gid % :threads = :var_proc;
