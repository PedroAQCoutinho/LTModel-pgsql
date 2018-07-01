SET search_path TO lt_model, public;



DROP TABLE IF EXISTS temp_lines;
CREATE TABLE v_temp_lines AS
SELECT rid, ST_MakeLine(geom) geom
FROM (SELECT * FROM temp_small_points2 ORDER BY rid, ind) A
GROUP BY rid;


CREATE INDEX gix_temp_lines ON temp_lines USING GIST (geom);

DROP TABLE IF EXISTS temp_max_intersect;
CREATE TABLE temp_max_intersect AS --53.2s
SELECT small.rid small, big.rid big, ST_CollectionExtract(ST_Intersection(ST_Snap(big.geom, small.geom, 0.01), small.geom), 2) geom, ST_Length(ST_Intersection(ST_Snap(big.geom, small.geom, 0.1), small.geom)) len
FROM temp_lines small
JOIN temp_bounds big ON ST_DWithin(small.geom, big.geom, 10)
WHERE NOT big.fla_eliminate AND small.rid = 64731
ORDER BY small.rid, ST_Length(ST_Intersection(ST_Snap(big.geom, small.geom, 0.0001), ST_Snap(small.geom, big.geom, 0.0001))) DESC;

SELECT big.rid, COUNT(small.rid) contagem
FROM temp_small_points small
JOIN temp_bounds big ON ST_Intersects(ST_Snap(small.geom, big.geom, 0.0000001), ST_Snap(big.geom, small.geom, 0.0000001)) AND ST_DWithin(small.geom, big.geom, 10)
WHERE small.rid = 64731 AND big.rid = 64911
GROUP BY big.rid