SET search_path TO lt_model, public;

ANALYZE proc1_04_car_poor_clean;
ANALYZE proc1_05_car_premium_clean;


--Create poor without premium -- 8m54s
DROP TABLE IF EXISTS proc1_06_car_poor_clean_without_premium;
CREATE TABLE proc1_06_car_poor_clean_without_premium
(
  gid BIGINT,
  geom geometry,
  shape_area double precision,
  area_loss double precision,
  incra_area_loss DOUBLE PRECISION,
  fla_overlay_poor_premium boolean
);
