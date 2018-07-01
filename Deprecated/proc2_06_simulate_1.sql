CREATE INDEX IF NOT EXISTS ix_lt_model_result2 ON lt_model.result2 USING GIST (geom);

DROP TABLE IF EXISTS lt_model.proc3_03_simulate;
CREATE TABLE lt_model.proc3_03_simulate (
cd_mun INT,
geom geometry
);