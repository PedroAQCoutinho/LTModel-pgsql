SET search_path TO recorte, public;


DROP TABLE IF EXISTS proc1_02_car_result;
CREATE TABLE proc1_02_car_result
(
  gid BIGINT,
  geom geometry
)