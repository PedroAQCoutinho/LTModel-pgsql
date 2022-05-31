-- Identifying unregistered lands

-- 0..19 | foreach {start cmd "/k psql -U felipe -d atlas -h ima-pgdb2.intranet.imaflora.org -v var_proc=$_ -v threads=20 -a -f LTbreak_proc03-identifying-unregistered-lands.sql"}

SELECT :var_proc num_proc;
INSERT INTO lt_model.v_pacotes_proc03_unregistered
SELECT
    9999999,
    a.cd_mun,
    a.cd_bioma,
    a.cd_bacia,
    ST_CollectionExtract(
                (ST_Dump(
                    COALESCE(
                        ST_Safe_Difference(a.geom,
                            (SELECT ST_Collect(dp.geom)
                            -- FROM lt_model.:ltenure AS b
                            FROM consolidado.landtenure_v202105_random AS b,
                            LATERAL (SELECT dp.geom FROM st_dump(b.geom) as dp) as dp
                            WHERE ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom))
                        ),
                    a.geom))
                ).geom
                ,3)
                as geom
FROM   lt_model.v_pacotes_proc02_ottobacia AS a
WHERE (a.cd_mun % :threads) = :var_proc;

