CREATE INDEX IF NOT EXISTS ix_lt_model_result2 ON recorte.result2 USING GIST (geom);

DROP TABLE IF EXISTS recorte.proc3_03_simulate;
CREATE TABLE recorte.proc3_03_simulate (
cd_mun INT,
geom geometry
);