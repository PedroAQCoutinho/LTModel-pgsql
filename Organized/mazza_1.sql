DROP TABLE IF EXISTS projetos_2017.mazza_01_car_intersections;


CREATE TABLE projetos_2017.mazza_01_car_intersections AS
SELECT a.*, (ST_Area(a.geom)/10000)::numeric(30,4) area_ha2, CASE COUNT(b.gid) WHEN 0 THEN 0 ELSE 100*(ST_Area(a.geom)-ST_Area(ST_Difference(a.geom, ST_Buffer(ST_Collect(b.geom), 0.01))))/ST_Area(a.geom)::numeric(10,4) END perc_intersect, COUNT(b.gid) count
FROM lt_model.proc1_00_0makevalid a
LEFT JOIN lt_model.proc1_00_0makevalid b 
	ON ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom)
GROUP BY a.gid, a.cod_imovel, a.shape_area, a.shape_leng, a.geom, a.is_valid
LIMIT 0;

CREATE INDEX gix_mazza_01_car_intersections ON projetos_2017.mazza_01_car_intersections USING GIST (geom);