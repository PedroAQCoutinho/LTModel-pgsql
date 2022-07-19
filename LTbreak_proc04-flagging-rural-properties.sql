--Breaking by municipality
-- 0..39 | foreach {start cmd "/k psql -U felipe -d atlas -h ima-pgdb2.intranet.imaflora.org -v var_proc=$_ -v threads=40 -a -f LTbreak_proc04-flagging-rural-properties.sql"}

-- SELECT :var_proc num_proc;
-- INSERT INTO recorte.v_pacotes_proc04_flagprop
--     SELECT
--         a.gid,
--         b.cd_mun,
--         b.cd_bioma,
--         b.cd_bacia,
--         CASE WHEN ST_Contains(b.geom,a.geom) THEN a.geom
--             ELSE ST_Intersection(st_buffer(a.geom,0.0001),st_buffer(b.geom,0.0001)) 
--         END AS geom
--     -- FROM recorte.:ltenure AS a
    -- FROM consolidado.landtenure_v202105_random AS a
    -- JOIN recorte.v_pacotes_proc02_ottobacia AS b
--         ON ST_Intersects(a.geom,b.geom)
--     WHERE b.cd_mun % :threads = :var_proc;

SELECT :var_proc num_proc;
INSERT INTO recorte.v_pacotes_proc04_flagprop
    SELECT
        a.gid,
        b.cd_mun,
        b.cd_bioma,
        b.cd_bacia,
        CASE WHEN ST_Contains(b.geom,a.geom) THEN a.geom
            ELSE ST_safe_Intersection(a.geom,b.geom) 
        END AS geom
    -- FROM recorte.:ltenure AS a
    FROM consolidado.landtenure_v202105_random AS a
    JOIN recorte.v_pacotes_proc02_ottobacia AS b
        ON ST_Intersects(a.geom,b.geom)
    WHERE b.cd_mun % :threads = :var_proc;