-- \set mun_table_name `tail -1 var4.txt`
-- \set biome_table_name `tail -1 var5.txt`

--Breaking by biome
--0..39 | foreach {start cmd "/k psql -U felipe -d atlas -h ima-pgdb2.intranet.imaflora.org -v var_proc=$_ -v threads=40 -a -f LTbreak_proc01-breaking-mun-by-biome.sql"}
SELECT :var_proc num_proc;
INSERT INTO lt_model.v_pacotes_proc01_breakbiome
    SELECT
        a.cd_mun::int,
        b.id::int,
        CASE WHEN ST_Contains(b.geom,a.geom) THEN a.geom
            ELSE ST_Intersection(ST_Buffer(a.geom,0.0001),ST_Buffer(b.geom,0.0001)) 
        END AS geom
    -- FROM lt_model.:"mun_table_name" AS a
    -- JOIN lt_model.:"biome_table_name" AS b
        FROM lt_model.aux_pa_br_municipios_5572_2018 AS a
        JOIN lt_model.aux_biomas_250_2019_ibge AS b
        ON ST_Intersects(a.geom,b.geom)
    WHERE a.cd_mun::int % :threads = :var_proc;
