-- CAR SOLVING
SET search_path TO lt_model, public;
\set car_table_schema `tail -1 var1.txt`
\set car_table_name `tail -1 var2.txt`

INSERT INTO proc1_00_0makevalid
SELECT 
	a.gid, 
	cod_imovel cod_imovel, 
	ST_Area(geom) shape_area, 
	ST_Perimeter(geom) shape_leng, 
	ST_CollectionExtract(ST_MakeValid(geom), 3) geom,
	ST_IsValid(geom) is_valid
FROM (SELECT gid, cod_imovel, ST_Transform(geom, 97823) geom FROM :"car_table_schema".:"car_table_name" b
WHERE (gid % :var_num_proc) = :var_proc AND ST_Contains(ST_MakeEnvelope(-180, -90, 180, 90, 4326), ST_Transform(geom, 4326))) a;