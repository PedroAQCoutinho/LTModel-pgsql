SET search_path TO lt_model, public;

INSERT INTO proc1_03_is_premium 
(
  gid,
  geom,
  shape_area,
  shape_leng,
  area_loss,
  new_area,\
  fla_car_premium
)
SELECT 
  gid, 
  geom,
  shape_area,
  shape_leng,
  shape_area-new_area area_loss,
  new_area,
	CASE WHEN new_area IS NULL THEN 
		false 
	ELSE 
		(new_area/shape_area) >= (SELECT param_value FROM lt_model.params WHERE param_name = 'car_premium_tolerance')
	END fla_car_premium
FROM (
SELECT a.*, ST_Area(ST_CollectionExtract(b.geom,3)) new_area
FROM proc1_00_0makevalid a
LEFT JOIN proc1_02_car_result b ON a.gid = b.gid
WHERE (a.gid % :var_num_proc) = :var_proc) c;