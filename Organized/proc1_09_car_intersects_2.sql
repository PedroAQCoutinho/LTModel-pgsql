SET search_path TO lt_model, public;

INSERT INTO lt_model.proc1_03_z1_car_intersects
SELECT a.gid, b.gid gid2, a.fla_car_premium, b.fla_car_premium fla_car_premium2, a.new_area
FROM proc1_03_is_premium a
JOIN proc1_03_is_premium b ON a.gid <> b.gid AND ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom)
WHERE (a.gid % :var_num_proc) = :var_proc;