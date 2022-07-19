CREATE TABLE recorte.sp_fbds_count (
gid INT,
classe INT,
contagem INT
);

CREATE TABLE recorte.sp_fbds_count2 (
gid INT,
classe INT,
contagem INT
);

CREATE INDEX ix_ras_fbds2 ON recorte.ras_fbds2 USING BTREE ((rid % 15));

-- INSERT INTO recorte.sp_fbds_count2 
-- SELECT b.gid, (ST_ValueCount(ST_Clip(a.rast, b.geom), 
-- 	ARRAY[15::double precision, 40, 41, 42, 80, 81, 82])).* 
-- FROM recorte.ras_fbds2 a 
-- JOIN recorte.result2 b ON (rid % 15) = {num} AND ST_Intersects(a.rast, b.geom);
------------------------
------ POWERSHELL ------
------------------------
-- $sql = 'INSERT INTO recorte.sp_fbds_count2 SELECT b.gid, (ST_ValueCount(ST_Clip(a.rast, b.geom), ARRAY[15::double precision, 40, 41, 42, 80, 81, 82])).* FROM recorte.ras_fbds2 a JOIN recorte.result2 b ON (rid % 15) = {num} AND ST_Intersects(a.rast, b.geom);'
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}


SELECT COUNT(DISTINCT gid) FROM recorte.sp_fbds_count2;

DROP TABLE recorte.sp_fbds_count_agg;
CREATE TABLE recorte.sp_fbds_count_agg AS
SELECT gid, classe, SUM(contagem)/400 area
FROM recorte.sp_fbds_count
GROUP BY gid, classe;

SELECT gid, classe, a.area area_vec, area_ha area_rast, CASE WHEN a.area IS NULL THEN 0 ELSE a.area END - CASE WHEN b.area_ha IS NULL THEN 0 ELSE b.area_ha END area_diff
FROM recorte.sp_fbds_count_agg2 a
FULL JOIN fa_model.sp5m_result_fbds b ON a.gid = b.prim_key AND 'Class' || a.classe = b.luse_class
ORDER BY CASE WHEN a.area IS NULL THEN 0 ELSE a.area END - CASE WHEN b.area_ha IS NULL THEN 0 ELSE b.area_ha END DESC
LIMIT 100;

SELECT CASE WHEN classe IS NULL THEN RIGHT(b.luse_class, 2)::INTEGER ELSE classe END classe2 , SUM(CASE WHEN a.area IS NULL THEN 0 ELSE a.area END - CASE WHEN b.area_ha IS NULL THEN 0 ELSE b.area_ha END) area_diff
FROM recorte.sp_fbds_count_agg2 a
FULL JOIN fa_model.sp5m_result_fbds b ON a.gid = b.prim_key AND ('Class' || a.classe) = b.luse_class
WHERE classe <> 15 OR classe IS NULL
GROUP BY classe2;


SELECT CASE WHEN classe IS NULL THEN RIGHT(b.luse_class, 2)::INTEGER ELSE classe END classe2 , SUM(CASE WHEN a.area IS NULL THEN 0 ELSE a.area END - CASE WHEN b.area_ha IS NULL THEN 0 ELSE b.area_ha END) area_diff
FROM recorte.sp_fbds_count_agg a
FULL JOIN fa_model.sp5m_result_fbds b ON a.gid = b.prim_key AND ('Class' || a.classe) = b.luse_class
GROUP BY classe2;

DROP TABLE recorte.ras_fbds2 
CREATE TABLE recorte.ras_fbds (rid SERIAL, rast Raster);


