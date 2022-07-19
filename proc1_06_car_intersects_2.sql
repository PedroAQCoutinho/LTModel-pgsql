SET search_path TO recorte, public;

INSERT INTO recorte.proc1_03_z0_car_intersects
SELECT a.gid, b.gid gid2, ST_Area(ST_CollectionExtract(c.geom,3)) new_area
FROM proc1_00_0makevalid a
JOIN proc1_00_0makevalid b ON a.gid <> b.gid AND ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom)
LEFT JOIN proc1_02_car_result c ON a.gid = c.gid
WHERE (a.gid % :var_num_proc) = :var_proc;