DROP TABLE IF EXISTS recorte.proc3_20_voronoifinal;
CREATE TABLE recorte.proc3_20_voronoifinal AS
SELECT cd_mun, row_number() OVER () as gid, geom, ST_Area(geom)::numeric(30,4) area
FROM (
SELECT b.cd_mun, b.gid, CASE WHEN a.gid IS NULL THEN b.geom ELSE ST_CollectionExtract(ST_Intersection((ST_Dump(ST_CollectionExtract(ST_VoronoiPolygons(ST_GeneratePoints(geom, n_pontos), 0, geom), 3))).geom, geom), 3) END geom
FROM recorte.proc3_19_npontos a
RIGHT JOIN recorte.proc3_14_area_simulada_sem_1ha b ON a.cd_mun = b.cd_mun AND a.gid = b.gid) a;
