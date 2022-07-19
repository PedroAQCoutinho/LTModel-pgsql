--Building complete landtenure dataset
INSERT INTO recorte.v_pacotes_proc05_malha_break (gid_imovel, cd_mun, cd_bioma, cd_bacia, geom)
    SELECT * FROM recorte.v_pacotes_proc03_unregistered AS a
    UNION ALL
    SELECT * FROM recorte.v_pacotes_proc04_flagprop AS b;

ALTER TABLE recorte.v_pacotes_proc05_malha_break ADD PRIMARY KEY(gid_break);
CREATE INDEX gix_v_pacotes_proc05_malha_break ON recorte.v_pacotes_proc05_malha_break USING gist(geom);

-- \echo `rm var4.txt`
-- \echo `rm var5.txt`
-- \echo `rm var6.txt`