-- CAR SOLVING
SET search_path TO lt_model, public;

INSERT INTO proc1_00_0makevalid
SELECT 
	a.gid, 
	cod_imovel cod_imovel, 
	ST_Area(geom) shape_area, 
	ST_Perimeter(geom) shape_leng, 
	ST_Buffer(ST_CollectionExtract(ST_MakeValid(geom), 3), 0) geom,
	ST_IsValid(geom) is_valid
FROM :car_table a
WHERE (gid % :var_num_proc) = :var_proc;