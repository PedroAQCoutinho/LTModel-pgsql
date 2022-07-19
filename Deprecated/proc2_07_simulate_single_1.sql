DROP TABLE IF EXISTS recorte.proc3_04_simulate_single;
CREATE TABLE recorte.proc3_04_simulate_single (
gid SERIAL PRIMARY KEY,
cd_mun INT,
geom geometry
);