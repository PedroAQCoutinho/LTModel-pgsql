DROP TABLE IF EXISTS lt_model.proc3_04_simulate_single;
CREATE TABLE lt_model.proc3_04_simulate_single (
gid SERIAL PRIMARY KEY,
cd_mun INT,
geom geometry
);