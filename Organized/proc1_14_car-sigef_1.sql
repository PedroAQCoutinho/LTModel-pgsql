SET search_path TO lt_model, public;


-- Sigef union (CAR -  SiGEF)
DROP TABLE IF EXISTS proc1_13_car_sigef;
CREATE TABLE proc1_13_car_sigef (
	gid INTEGER, 
	area_loss NUMERIC(10,6), 
	area DOUBLE PRECISION, 
	area_original DOUBLE PRECISION, 
	is_premium BOOLEAN, 
	geom GEOMETRY
);