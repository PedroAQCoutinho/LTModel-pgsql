DROP TABLE IF EXISTS proc3_13_limpa_area_simulada_result;
CREATE TABLE proc3_13_limpa_area_simulada_result (
cd_mun INT,
geom geometry,
gid INT,
area_ha INT,
rnd DOUBLE PRECISION DEFAULT random()
);