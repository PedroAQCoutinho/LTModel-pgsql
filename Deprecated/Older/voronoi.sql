﻿DROP TABLE recorte.voronoisheipinho;
CREATE TABLE recorte.voronoisheipinho AS
SELECT gid, ST_CollectionExtract(ST_Intersection((ST_Dump(ST_CollectionExtract(ST_VoronoiPolygons(ST_GeneratePoints(geom, 2), 0, geom), 3))).geom, geom), 3) geom
FROM recorte.sheipinho

