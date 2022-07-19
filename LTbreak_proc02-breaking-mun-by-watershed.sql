-- \set otto_table_name `tail -1 var6.txt`

--Breaking by ottobacia

-- 0..39 | foreach {start cmd "/k psql -U felipe -d atlas -h ima-pgdb2.intranet.imaflora.org -v var_proc=$_ -v threads=40 -a -f LTbreak_proc02-breaking-mun-by-watershed.sql"}
SELECT :var_proc num_proc;
INSERT INTO recorte.v_pacotes_proc02_ottobacia
    SELECT
        a.cd_mun,
        a.cd_bioma,
        b.cobacia,
        CASE WHEN ST_Contains(b.geom,a.geom) THEN a.geom
            ELSE ST_Intersection(ST_Buffer(a.geom,0.0001),ST_Buffer(b.geom,0.0001)) 
        END AS geom
    FROM recorte.v_pacotes_proc01_breakbiome AS a
    -- JOIN recorte.:"otto_table_name" AS b
    JOIN recorte.aux_ottobacias_multiescalas_2017_ana AS b
        ON ST_Intersects(a.geom,b.geom)
    WHERE a.cd_mun % :threads = :var_proc;

