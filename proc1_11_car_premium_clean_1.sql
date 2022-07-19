SET search_path TO recorte, public;

-- Clean CAR_premium with self overlay random priority -- 3m27s
DROP TABLE IF EXISTS proc1_05_car_premium_clean;
CREATE TABLE proc1_05_car_premium_clean
(
  gid BIGINT,
  geom geometry,
  shape_area double precision
);

CREATE INDEX gix_proc1_05_car_premium_clean
  ON proc1_05_car_premium_clean
  USING gist
  (geom);