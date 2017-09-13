SET search_path TO lt_model, public;


-- Sigef union (CAR -  SiGEF)
DROP TABLE IF EXISTS proc1_00_car_sigef;
CREATE TABLE proc1_00_car_sigef (
	car INT,
	car_geom geometry,
	intersection_geom geometry,
	shape_area DOUBLE PRECISION,
	sigef_area DOUBLE PRECISION,
	shape_leng DOUBLE PRECISION,
	area_loss NUMERIC(10,6)
);