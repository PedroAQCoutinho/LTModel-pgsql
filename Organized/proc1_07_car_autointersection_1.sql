SET search_path TO lt_model, public;


DROP TABLE IF EXISTS proc1_02_car_result;
CREATE TABLE proc1_02_car_result
(
  gid BIGINT,
  geom geometry
)