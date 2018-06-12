SET search_path TO lt_model, public;


-- Sigef union (CAR -  SiGEF)
DROP TABLE IF EXISTS proc1_13_car_sigef;
CREATE TABLE proc1_13_car_sigef (
	car INT,
	car_geom geometry,
	intersection_geom geometry,
	area DOUBLE PRECISION,
	area_original DOUBLE PRECISION,
	sigef_area DOUBLE PRECISION,
	shape_leng DOUBLE PRECISION,
	area_loss NUMERIC(10,6)
);