\set mun_table_name `tail -1 var4.txt`
\set biome_table_name `tail -1 var5.txt`

--Breaking by biome
SELECT :var_proc num_proc;
INSERT INTO lt_model.v_pacotes_proc01_breakbiome
    SELECT
        a.cd_mun,
        b.id_bioma,
        CASE WHEN ST_Contains(b.geom,a.geom) THEN a.geom
            ELSE ST_Intersection(ST_Buffer(a.geom,0.0001),ST_Buffer(b.geom,0.0001)) 
        END AS geom
    FROM lt_model.:"mun_table_name" AS a
    JOIN lt_model.:"biome_table_name" AS b
        ON ST_Intersects(a.geom,b.geom)
    WHERE a.cd_mun % :threads = :var_proc;
