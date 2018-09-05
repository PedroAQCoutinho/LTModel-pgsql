-- Function: lt_model.eliminate_car()

-- DROP FUNCTION lt_model.eliminate_car();

CREATE OR REPLACE FUNCTION lt_model.eliminate_car()
  RETURNS void AS
$BODY$
BEGIN
	DROP TABLE IF EXISTS temp_bounds_big; 
	CREATE TEMP TABLE temp_bounds_big AS --5s --
	SELECT DISTINCT a.rid, (ST_Dump(ST_ExteriorRing(a.geom))).geom::geometry(Linestring, 97823) geom, a.fla_eliminate
	FROM lt_model.proc1_11_temp_car_consolidated a;

	CREATE INDEX gix_temp_bounds_big ON temp_bounds_big USING GIST (geom); --3.7s
	CREATE INDEX gix_temp_bounds_big_eliminate ON temp_bounds_big USING BTREE (fla_eliminate); --0.3s

	DROP TABLE IF EXISTS temp_small_points CASCADE;
	CREATE TABLE IF NOT EXISTS temp_small_points AS
	SELECT rid, (dump).path[1] ind, (dump).path[2] ind2, (dump).geom
	FROM (SELECT DISTINCT a.rid, (ST_DumpPoints(a.geom)) dump, a.fla_eliminate
	FROM proc1_09_car_single a
	WHERE fla_eliminate) b;

	CREATE INDEX gix_temp_small_points ON temp_small_points USING GIST (geom);
	CREATE INDEX ix_temp_small_points_1 ON temp_small_points USING BTREE (ind);
	CREATE INDEX ix_temp_small_points_2 ON temp_small_points USING BTREE (ind2); 
	CREATE INDEX ix_temp_small_points_3 ON temp_small_points USING BTREE (rid); 
	
	

	CREATE OR REPLACE VIEW v_temp_small_points AS
	SELECT a.* 
	FROM temp_small_points a
	LEFT JOIN temp_already_process b ON a.rid = b.small
	WHERE b.small IS NULL;

	DROP TABLE IF EXISTS temp_small_big_touching;
	CREATE TEMP TABLE temp_small_big_touching AS -- 25.2s
	SELECT DISTINCT a.rid small, b.rid big
	FROM v_temp_small_points a
	JOIN temp_bounds_big b ON ST_DWithin(a.geom, b.geom, 0);

	CREATE INDEX ix_temp_small_big_touching ON temp_small_big_touching USING BTREE (small, big); --50ms


	-- Create table with nodes that are within 20m from consolidated CAR
	DROP TABLE IF EXISTS temp_small_points2; --16.6s --22.5s
	CREATE TEMP TABLE temp_small_points2 AS
	SELECT small.rid small, big.rid big, ind, ind2, small.geom geom
	FROM temp_small_big_touching touch 
	JOIN v_temp_small_points small ON small.rid = touch.small
	JOIN temp_bounds_big big ON ST_DWithin(small.geom, big.geom, 20) AND big.rid = touch.big
	WHERE NOT big.fla_eliminate;

	CREATE INDEX gix_temp_small_points2 ON temp_small_points2 USING BTREE (small, big, ind, ind2); --681ms
	
	-- Create lines from points and get id pairs of consolidated/eliminate where length is maximum
	DROP TABLE IF EXISTS temp_max_intersect; 
	CREATE TEMP TABLE temp_max_intersect AS --8.4s --10.2s --5.5s
	WITH connected_points AS
	(SELECT DISTINCT A.small, A.big, A.ind, A.ind2, A.geom
	FROM temp_small_points2 A
	JOIN temp_small_points2 B ON A.small = B.small AND A.big = B.big AND A.ind = B.ind AND (A.ind2 = (B.ind2 -1) OR A.ind2 = (B.ind2 + 1))
	ORDER BY A.small, A.big, A.ind, A.ind2),
	linestrings AS
	(SELECT small, big, ST_MakeLine(geom) geom
	FROM connected_points
	GROUP BY small, big)
	SELECT DISTINCT ON (A.small) A.small, A.big, geom
	FROM linestrings A
	ORDER BY A.small, ST_Length(A.geom) DESC;

	INSERT INTO temp_already_process
	SELECT DISTINCT small FROM temp_max_intersect;
	

	-- Union of consolidated + all eliminates associated
	UPDATE proc1_11_temp_car_consolidated a -- 21.9s -- 14.9s
 	SET geom = ST_CollectionExtract(ST_Union(a.geom, d.geom), 3)
 	FROM (SELECT b.big rid, ST_Buffer(ST_Collect(c.geom), 0.01) geom
	FROM temp_max_intersect b
		JOIN proc1_09_car_single c ON b.small = c.rid
	GROUP BY b.big) d
	WHERE d.rid = a.rid;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

