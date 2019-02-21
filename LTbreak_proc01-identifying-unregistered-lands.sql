-- Identifying unregistered lands
SELECT :var_proc num_proc;
INSERT INTO testes.v_pacotes_proc01_unregistered (gid,cd_mun,geom)
SELECT
    9999999,
    a.cd_mun,
    ST_CollectionExtract((ST_Dump(COALESCE(ST_Safe_Difference_Simulate(a.geom,
                (SELECT ST_Collect(b.geom) FROM testes.v_pacotes_input_imoveis AS b
                WHERE ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom))),
                a.geom))).geom,3)
FROM   geo.recgeo_municipio_completo_albers AS a
WHERE (a.gid % :threads) = :var_proc;
