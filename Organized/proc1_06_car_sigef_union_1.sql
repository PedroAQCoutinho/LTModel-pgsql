SET search_path TO lt_model, public;
SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM lt_model.log_outputs));


DROP TABLE IF EXISTS proc1_01_car_sigef_union;
CREATE TABLE proc1_01_car_sigef_union AS
SELECT gid, ST_Multi(geom) geom, ST_Area(geom) shape_area, ST_Perimeter(geom) shape_leng, 0::double precision area_loss, true fla_sigef
FROM lt_model.lt_model_sigef
--WHERE ST_XMax(geom) < 658294.02429628 AND ST_XMin(geom) > 542810.3515331885 AND ST_YMax(geom) < -1077895.2638318148 AND ST_YMin(geom) > -1179502.5469183084
;

INSERT INTO proc1_01_car_sigef_union
SELECT car, ST_Multi(car_geom) geom, shape_area, shape_leng, 0 area_loss, false fla_sigef
FROM proc1_00_car_sigef
WHERE area_loss IS NULL OR area_loss <= 0;

-- Add CAR that lost less than 50% of its area
INSERT INTO proc1_01_car_sigef_union
SELECT car, ST_Multi(intersection_geom) geom, shape_area, shape_leng, area_loss*shape_area area_loss, false fla_sigef
FROM proc1_00_car_sigef
WHERE area_loss <= 0.5 AND area_loss > 0;

CREATE INDEX gix_proc1_01_car_sigef_union ON proc1_01_car_sigef_union USING GIST (geom);
CREATE INDEX ix_proc1_01_car_sigef_union ON proc1_01_car_sigef_union USING BTREE (gid);

