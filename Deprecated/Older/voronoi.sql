DROP TABLE lt_model.voronoisheipinho;
CREATE TABLE lt_model.voronoisheipinho AS
SELECT gid, ST_CollectionExtract(ST_Intersection((ST_Dump(ST_CollectionExtract(ST_VoronoiPolygons(ST_GeneratePoints(geom, 2), 0, geom), 3))).geom, geom), 3) geom
FROM lt_model.sheipinho

