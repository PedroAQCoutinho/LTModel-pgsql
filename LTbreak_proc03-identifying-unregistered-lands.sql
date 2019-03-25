-- Identifying unregistered lands
SELECT :var_proc num_proc;
INSERT INTO lt_model.v_pacotes_proc03_unregistered
SELECT
    9999999,
    a.cd_mun,
    a.cd_bioma,
    a.cd_bacia,
    ST_CollectionExtract((ST_Dump(COALESCE(ST_Safe_Difference(a.geom,
                (SELECT ST_Collect(b.geom)
                FROM lt_model.:ltenure AS b
                WHERE ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom))),
                a.geom))).geom,3)
FROM   lt_model.v_pacotes_proc02_ottobacia AS a
WHERE (a.cd_mun % :threads) = :var_proc;
