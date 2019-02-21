
--Building complete landtenure dataset
INSERT INTO testes.v_pacotes_proc02_imoveisfull (gid, geom)
    SELECT
        a.gid,
        a.geom
    FROM testes.v_pacotes_input_imoveis AS a
    UNION 
    SELECT
        b.gid,
        b.geom
    FROM testes.v_pacotes_proc01_unregistered AS b;
