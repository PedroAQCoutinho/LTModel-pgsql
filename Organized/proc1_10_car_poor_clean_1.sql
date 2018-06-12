SET search_path TO lt_model, public;

DROP TABLE IF EXISTS proc1_04_car_poor_clean;
CREATE TABLE proc1_04_car_poor_clean (
	gid BIGINT,
	geom geometry,
	shape_area DOUBLE PRECISION
);

CREATE INDEX gix_proc1_04_car_poor_clean
  ON proc1_04_car_poor_clean
  USING gist
  (geom);
