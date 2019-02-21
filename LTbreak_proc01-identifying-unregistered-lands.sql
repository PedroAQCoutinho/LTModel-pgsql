-- Identifying unregistered lands
SELECT :var_proc num_proc;
INSERT INTO lt_model.v_pacotes_proc01_unregistered (gid,cd_mun,geom)
SELECT
    9999999,
    a.cd_mun,
    ST_CollectionExtract((ST_Dump(COALESCE(ST_Safe_Difference_Simulate(a.geom,
                (SELECT ST_Collect(b.geom) FROM lt_model.:ltenure AS b
                WHERE ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom))),
                a.geom))).geom,3)
FROM   lt_model.aux_pa_br_municipios_5570 AS a
WHERE (a.gid % :threads) = :var_proc;
