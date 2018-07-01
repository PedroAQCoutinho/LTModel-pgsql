-- gid, id, gridcode, shape_area, geom
SET search_path = lt_model,public;


-- Create temporary copy of CAR to be consolidated
DROP TABLE IF EXISTS temp_car_consolidated;
CREATE TABLE temp_car_consolidated AS --2.6s
SELECT *, false fla_multipolygon FROM lt_model.car_single WHERE NOT fla_eliminate;

-- Extract boundaries as linestrings
DROP TABLE IF EXISTS temp_bounds; 
CREATE TABLE temp_bounds AS --5s --
SELECT DISTINCT a.rid, (ST_Dump(ST_ExteriorRing(a.geom))).geom::geometry(Linestring, 97823) geom, a.fla_eliminate
FROM lt_model.car_single a;

CREATE INDEX gix_temp_bounds ON temp_bounds USING GIST (geom); --3.7s
CREATE INDEX gix_temp_bounds_eliminate ON temp_bounds USING BTREE (fla_eliminate); --0.3s


--Extract nodes from linestrings
DROP TABLE IF EXISTS temp_small_points; -- 0.7s
CREATE TABLE temp_small_points AS
SELECT rid, (dp).path[1] ind, (dp).geom geom
FROM (SELECT rid, (ST_DumpPoints(geom)) dp
FROM temp_bounds
WHERE fla_eliminate) A;

CREATE INDEX gix_temp_small_points ON temp_small_points USING GIST (geom); --5.1s

-- Create table with nodes that are within 20m from consolidated CAR
DROP TABLE IF EXISTS temp_small_points2; --16.6s
CREATE TABLE temp_small_points2 AS
SELECT small.rid small, big.rid big, ind, small.geom geom
FROM temp_small_points small
JOIN temp_bounds big ON ST_DWithin(small.geom, big.geom, 20)
WHERE NOT big.fla_eliminate;

CREATE INDEX gix_temp_small_points2 ON temp_small_points2 USING BTREE (small, big, ind); --681ms

DROP TABLE IF EXISTS temp_small_points3;
CREATE TEMP TABLE temp_small_points3 AS
SELECT c.small, c.big, CASE WHEN MIN(ST_Distance(b.geom, c.geom)) = 0 THEN 0 ELSE 1 END min_dist
FROM temp_bounds b
JOIN temp_small_points2 c ON b.rid = c.big
GROUP BY c.small, c.big;

-- ALTER TABLE temp_small_points2
-- ADD COLUMN big_gid_255 INT;
-- 
-- UPDATE temp_small_points2
-- SET big_gid_255 = big % 255;


-- DROP TABLE IF EXISTS temp_max_intersect_visual; 
-- CREATE TABLE temp_max_intersect_visual AS --8.4s
-- SELECT small, big, ST_MakeLine(geom) geom
-- FROM (SELECT DISTINCT A.small, A.big, A.ind, A.geom
-- FROM temp_small_points2 A
-- JOIN temp_small_points2 B ON A.small = B.small AND A.big = B.big AND (A.ind = (B.ind -1) OR A.ind = (B.ind + 1))
-- ORDER BY A.small, A.big, A.ind) C
-- GROUP BY small, big
-- ORDER BY small, ST_Length(ST_MakeLine(geom)) DESC;


-- Create lines from points and get id pairs of consolidated/eliminate where length is maximum
DROP TABLE IF EXISTS temp_max_intersect; 
CREATE TABLE temp_max_intersect AS --8.4s --10.2s
WITH connected_points AS
(SELECT DISTINCT A.small, A.big, A.ind, A.geom
FROM temp_small_points2 A
JOIN temp_small_points2 B ON A.small = B.small AND A.big = B.big AND (A.ind = (B.ind -1) OR A.ind = (B.ind + 1))
ORDER BY A.small, A.big, A.ind),
linestrings AS
(SELECT small, big, ST_MakeLine(geom) geom
FROM connected_points
GROUP BY small, big)
SELECT DISTINCT ON (A.small) A.small, A.big, geom
FROM linestrings A
JOIN temp_small_points3 B ON A.small = B.small AND A.big = B.big
ORDER BY A.small, B.min_dist, ST_Length(A.geom) DESC;

-- Union of consolidated + all eliminates associated
UPDATE temp_car_consolidated a -- 21.9s -- 15.3s
SET geom = ST_CollectionExtract(ST_Union(a.geom, d.geom), 3)
FROM (SELECT b.big rid, ST_Buffer(ST_Collect(c.geom), 0.01) geom
FROM temp_max_intersect b
	JOIN car_single c ON b.small = c.rid
GROUP BY b.big) d
WHERE d.rid = a.rid;

UPDATE temp_car_consolidated
SET fla_multipolygon = ST_GeometryType(geom) = 'ST_MultiPolygon'

-- DELETE FROM temp_bounds a
-- USING temp_max_intersect b 
-- WHERE b.small = a.gid;
-- 
-- SELECT DISTINCT ST_GeometryType(geom) from temp_car_consolidated;
-- 
-- UPDATE temp_bounds a
-- SET geom = ST_ExteriorRing(b.geom)::geometry(Linestring, 97823)
-- FROM temp_car_consolidated b
-- WHERE b.gid = a.gid;
-- 
-- CREATE TABLE temp_max_intersect2 AS
-- SELECT DISTINCT ON (small) small, big
-- FROM temp_max_intersect
-- ORDER BY small, len DESC;
-- 
-- DROP TABLE IF EXISTS temp_max_intersect;
-- CREATE TABLE temp_max_intersect AS
-- SELECT small.gid small, big.gid big, ST_Length(big.geom) len
-- FROM teste small, teste big 
-- WHERE small.fla_eliminate AND NOT big.fla_eliminate AND ST_DWithin(small.geom, big.geom, 1) AND (ST_Within(small.geom, big.geom) OR ST_Within(big.geom, small.geom));
-- 
-- DROP TABLE IF EXISTS elim_join;
-- CREATE TABLE elim_join AS
-- SELECT small, big
-- FROM (SELECT small, big, ROW_NUMBER() OVER (PARTITION BY small ORDER BY SUM(len) DESC) ranque FROM temp_max_intersect
-- GROUP BY small, big) A
-- WHERE ranque = 1;
-- 
-- DROP TABLE IF EXISTS elim_corrected;
-- CREATE TABLE elim_corrected AS
-- SELECT e3.gid, ST_Union(e3.geom, ST_Union(e1.geom)) geom
-- FROM simreg_to_eliminate e1
-- JOIN elim_join e2 ON e1.gid = e2.small
-- JOIN simreg_to_eliminate e3 ON e3.gid = e2.big
-- GROUP BY e3.gid, e3.geom;
-- 
-- INSERT INTO elim_corrected 
-- SELECT a.gid, a.geom
-- FROM simreg_to_eliminate a
-- LEFT JOIN  elim_corrected b ON a.gid = b.gid
-- WHERE a.shape_area > 50000 AND b.gid IS NULL;
-- 
-- ALTER TABLE elim_corrected
-- ALTER COLUMN geom TYPE geometry(geometry, 97823) USING ST_SetSRID(geom, 97823);
-- 
-- 
-- 
