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
        WHEN num_modulo <= 4 AND (new_area/shape_area) >= (SELECT param_value FROM recorte.params WHERE param_name = 'car_premium_overlap_tolerance_p') AND count_overlap <= (SELECT param_value FROM recorte.params WHERE param_name = 'car_premium_overlap_count_p') THEN TRUE
        WHEN num_modulo <= 15 AND (new_area/shape_area) >= (SELECT param_value FROM recorte.params WHERE param_name = 'car_premium_overlap_tolerance_m') AND count_overlap <= (SELECT param_value FROM recorte.params WHERE param_name = 'car_premium_overlap_count_m') THEN TRUE
        WHEN num_modulo > 15 AND (new_area/shape_area) >= (SELECT param_value FROM recorte.params WHERE param_name = 'car_premium_overlap_tolerance_g') AND count_overlap <= (SELECT param_value FROM recorte.params WHERE param_name = 'car_premium_overlap_count_g') THEN TRUE
        ELSE FALSE
	END fla_car_premium
FROM (
SELECT
    a.*,
    ST_Area(ST_CollectionExtract(b.geom,3)) new_area,
    d.:"car_mf_column"::numeric num_modulo,
    e.count_overlap
FROM recorte.proc1_00_0makevalid a
LEFT JOIN recorte.proc1_02_car_result b
    ON a.gid = b.gid
LEFT JOIN :"car_table_schema".:"car_table_name" d
    ON a.gid = d.gid
LEFT JOIN (SELECT gid, COUNT(DISTINCT gid2) AS count_overlap FROM recorte.proc1_03_z0_car_intersects GROUP BY gid) e
    ON a.gid = e.gid
WHERE (a.gid % :var_num_proc) = :var_proc) c;