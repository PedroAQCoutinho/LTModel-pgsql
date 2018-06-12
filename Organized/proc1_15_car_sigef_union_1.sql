SET search_path TO lt_model, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM lt_model.log_outputs));


DROP TABLE IF EXISTS proc1_14_car_sigef_union;
CREATE TABLE proc1_14_car_sigef_union AS
SELECT gid, ST_Multi(geom) geom, ST_Area(geom) shape_area, ST_Perimeter(geom) shape_leng, 0::double precision area_loss, true fla_sigef
FROM lt_model.lt_model_incra_pr
--WHERE ST_XMax(geom) < 658294.02429628 AND ST_XMin(geom) > 542810.3515331885 AND ST_YMax(geom) < -1077895.2638318148 AND ST_YMin(geom) > -1179502.5469183084
;

DROP TABLE IF EXISTS lt_model.lt_model_car_pr
CREATE TABLE lt_model.lt_model_car_pr AS
SELECT car gid, ST_Multi(intersection_geom) geom, area_original, shape_leng perimeter, shape_area*area_loss
FROM proc1_13_car_sigef
WHERE area_loss IS NULL OR area_loss <= 
    (SELECT 1-param_value FROM lt_model.params WHERE param_name = 'car_premium_tolerance');

-- Add CAR that lost less than 50% of its area
DROP TABLE IF EXISTS lt_model.lt_model_car_po
CREATE TABLE lt_model.lt_model_car_po AS
SELECT car gid, ST_Multi(intersection_geom) geom, area_original, shape_leng perimeter, area_loss*shape_area area_loss
FROM proc1_13_car_sigef
WHERE area_loss <=
(SELECT param_value FROM lt_model.params WHERE param_name = 'car_area_loss_tolerance') AND area_loss > (SELECT 1-param_value FROM lt_model.params WHERE param_name = 'car_premium_tolerance');

