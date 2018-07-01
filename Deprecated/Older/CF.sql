INSERT INTO pu_tibr2 (geom)
SELECT ST_GeometryN(geom, generate_series(1, ST_NumGeometries(geom))) AS geom 
FROM pu_tibr;


CREATE INDEX ix_pu_tibr2 ON pu_tibr2 USING GIST (geom);
CREATE INDEX ix_pu_mlbr2 ON pu_mlbr2 USING GIST (geom);

CREATE TABLE result
(
  gid serial NOT NULL PRIMARY KEY,
  geom geometry(Polygon,97823),
  overlay1 TEXT,
  overlay2 TEXT
)


DELETE FROM result;

-- Insert TI without conflict with ML
INSERT INTO result(geom, overlay1)
SELECT t.geom, 'TI'
FROM pu_tibr2 t
LEFT JOIN pu_mlbr2 m ON ST_DWithin(t.geom, m.geom, 0.01)
WHERE m.gid IS NULL;

-- Insert ML without conflict with TI
INSERT INTO result(geom, overlay1)
SELECT m.geom, 'ML'
FROM pu_tibr2 t
RIGHT JOIN pu_mlbr2 m ON ST_DWithin(t.geom, m.geom, 0.01)
WHERE t.gid IS NULL;

-- Insert TI with ML erased
INSERT INTO result(geom, overlay1)
SELECT (ST_Dump(ST_Difference(t.geom, ST_UNION(m.geom)))).geom, 'TI'
FROM pu_tibr2 t
JOIN pu_mlbr2 m ON ST_Intersects(t.geom, m.geom)
GROUP BY t.gid;

-- Insert ML with TI erased
INSERT INTO result(geom, overlay1)
SELECT (ST_Dump(ST_Difference(m.geom, ST_UNION(t.geom)))).geom, 'ML'
FROM pu_mlbr2 m
JOIN pu_tibr2 t ON ST_Intersects(t.geom, m.geom)
GROUP BY m.gid;

-- Insert intersection
INSERT INTO result(geom, overlay1, overlay2)
SELECT * FROM (
SELECT (ST_Dump(ST_Intersection(t.geom, m.geom))).geom geom, 'ML', 'TI'
FROM pu_tibr2 t
JOIN pu_mlbr2 m ON ST_Intersects(t.geom, m.geom)) a
WHERE ST_GeometryType(geom) = 'ST_Polygon';




-- Analyzing CAR
DROP TABLE ca_ac2 CASCADE;


CREATE TABLE ca_ac2 AS
SELECT gid, num_area, ST_GeometryN(geom, generate_series(1, ST_NumGeometries(geom))) AS geom 
FROM ca_ac;



-- SOBREPOSIÇÃO ENTRE OS CAR
CREATE INDEX ix_ca_ac2 ON ca_ac2 USING GIST (geom);


CREATE TABLE ca_ac_diff AS
SELECT c1.gid, CASE WHEN MAX(c2.gid) IS NULL THEN c1.geom ELSE ST_Difference(c1.geom, ST_Union(c2.geom)) END geom FROM ca_ac2 c1 
LEFT JOIN ca_ac2 c2 ON c1.gid != c2.gid AND ST_Intersects(c1.geom, c2.geom) AND ST_Area(c2.geom) < ST_Area(c1.geom)
GROUP BY c1.gid, c1.geom




CREATE VIEW ca_ac_view2 AS
SELECT gid, num_area, geom FROM (
SELECT c1.gid gid2, c2.gid, c2.num_area, ST_Intersection(c1.geom, c2.geom) geom FROM ca_ac2 c1 
JOIN ca_ac2 c2 ON ST_Intersects(c1.geom, c2.geom)
WHERE c1.gid = 13780
ORDER BY ST_Area(c2.geom) ASC
LIMIT 1) a WHERE gid <> gid2
