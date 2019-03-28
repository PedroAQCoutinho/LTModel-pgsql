--Breaking by biome
SELECT :var_proc num_proc;
INSERT INTO lt_model.v_pacotes_proc01_breakbiome
    SELECT
        a.cd_mun,
        b.id_bioma,
        CASE WHEN ST_Contains(b.geom,a.geom) THEN a.geom
            ELSE ST_Intersection(ST_Buffer(a.geom,0.0001),ST_Buffer(b.geom,0.0001)) 
        END AS geom
    FROM lt_model.aux_pa_br_municipios_5570 AS a
    JOIN lt_model.aux_biomas_mapbiomas AS b
        ON ST_Intersects(a.geom,b.geom)
    WHERE a.cd_mun % :threads = :var_proc;
