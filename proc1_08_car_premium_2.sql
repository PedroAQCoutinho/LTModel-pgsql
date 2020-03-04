SET search_path TO lt_model, public;

\set car_table_schema `tail -1 var1.txt`
\set car_table_name `tail -1 var2.txt`
\set car_mf_column `tail -1 var3.txt`

INSERT INTO proc1_03_is_premium 
(
  gid,
  geom,
  shape_area,
  shape_leng,
  area_loss,
  new_area,
  fla_car_premium
)
SELECT 
  gid, 
  geom,
  shape_area,
  shape_leng,
  shape_area-new_area area_loss,
  new_area,
	CASE WHEN new_area IS NULL THEN FALSE 
        WHEN num_modulo <= 4 AND (new_area/shape_area) >= 0.90 AND count_overlap <= 3 THEN TRUE
        WHEN num_modulo <= 15 AND (new_area/shape_area) >= 0.97 AND count_overlap <= 5 THEN TRUE
        WHEN num_modulo > 15 AND (new_area/shape_area) >= 0.99 AND count_overlap <= 7 THEN TRUE
        ELSE FALSE
	END fla_car_premium
FROM (
SELECT
    a.*,
    ST_Area(ST_CollectionExtract(b.geom,3)) new_area,
    d.:"car_mf_column" num_modulo,
    e.count_overlap
FROM lt_model.proc1_00_0makevalid a
LEFT JOIN lt_model.proc1_02_car_result b
    ON a.gid = b.gid
LEFT JOIN :"car_table_schema".:"car_table_name" d
    ON a.gid = d.gid
LEFT JOIN (SELECT gid, COUNT(DISTINCT gid2) AS count_overlap FROM lt_model.aux_proc1_03_z0_car_intersects GROUP BY gid) e
    ON a.gid = e.gid
WHERE (a.gid % :var_num_proc) = :var_proc) c;