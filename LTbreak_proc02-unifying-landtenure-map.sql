
--Building complete landtenure dataset
INSERT INTO lt_model.v_pacotes_proc02_imoveisfull (gid, geom)
    SELECT
        a.gid,
        a.geom
    FROM lt_model.:ltenure AS a
    UNION 
    SELECT
        b.gid,
        b.geom
    FROM lt_model.v_pacotes_proc01_unregistered AS b;
