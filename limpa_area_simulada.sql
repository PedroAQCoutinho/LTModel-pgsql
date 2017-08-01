	DROP TABLE IF EXISTS sheipinho_temp;
	CREATE TEMP TABLE sheipinho_temp AS
	SELECT ROW_NUMBER() OVER () gid, geom FROM (
	SELECT (ST_Dump(geom)).geom
	FROM lt_model.sheipinho2) A;

	DROP TABLE IF EXISTS nodes_max;
        CREATE TEMP TABLE nodes_max AS
        WITH nodes AS (
        SELECT gid, (geom).path[1] path1, (geom).path[2] path2, (geom).geom FROM
        (SELECT gid, (ST_DumpPoints(geom)) geom
        FROM sheipinho_temp) A
        ), nodes_max AS (
        SELECT *, MAX(path2) OVER (PARTITION BY gid, path1) max_path FROM nodes
        )
        SELECT * FROM nodes_max;

        CREATE INDEX ix_nodes_max3 ON nodes_max USING BTREE (gid);
        CREATE INDEX ix_nodes_max ON nodes_max USING BTREE (path1, path2);
        CREATE INDEX gix_nodes_max ON nodes_max USING GIST (geom);

	

        DROP TABLE IF EXISTS path_pair;
        CREATE TEMP TABLE path_pair AS
        SELECT a.gid, a.path1, a.path2, a.geom, MAX(b.path2) path3
        FROM nodes_max a
        JOIN nodes_max b ON a.gid = b.gid AND ST_DWithin(a.geom, b.geom, 60) AND a.path1 = b.path1 AND a.path2 < b.path2 AND(b.path2-a.path2) > 1 AND ((a.path2 + b.max_path - 1) - b.path2) > 1
        GROUP BY a.gid, a.path1, a.path2, a.geom;

        CREATE TEMP TABLE path_pair2 AS
        SELECT a.gid, a.path1, a.path2, a.geom, MAX(b.path2) path3
        FROM nodes_max a
        JOIN nodes_max b ON a.gid = b.gid AND a.path1 = b.path1 AND a.path2 < b.path2 AND ((a.path2 + b.max_path - 1) - b.path2) > 1
        JOIN nodes_max c ON a.gid = c.gid AND a.path1 = c.path1 AND b.path2 + 1 = c.path2
        GROUP BY a.gid, a.path1, a.path2, a.geom;

        CREATE INDEX ix_path_pair5 ON path_pair USING BTREE (gid, path1, path2, path3);
        CREATE INDEX gix_path_pair ON path_pair USING GIST (geom);

        DROP TABLE IF EXISTS path_dist;
        CREATE TEMP TABLE path_dist AS
        SELECT a.gid, MIN(a.path2) path, a.geom, a.path1, a.path3
        FROM path_pair a
        JOIN nodes_max b ON a.gid = b.gid AND a.path1 = b.path1 AND (((a.path3 - a.path2) > (b.max_path/2.0) AND (b.path2 < a.path2 OR b.path2 > a.path3)) OR ((a.path3 - a.path2) <= (b.max_path/2) AND b.path2 BETWEEN a.path2+1 AND a.path3-1)) AND NOT ST_DWithin(a.geom, b.geom, 200)
        GROUP BY a.gid, a.geom, a.path1, a.path3;

        

	DROP TABLE IF EXISTS sheipinho_nodes;
        CREATE TABLE sheipinho_nodes AS
        SELECT a.*, b.geom geom2
        FROM path_dist a
        JOIN nodes_max b ON a.gid = b.gid AND a.path1 = b.path1 AND a.path3 = b.path2;




	DROP TABLE IF EXISTS lt_model.sheipinhocortado2;
	CREATE TABLE lt_model.sheipinhocortado2 AS
        SELECT a.gid, (ST_Dump(geom)).geom
        FROM (SELECT a.gid, lt_model.cut_polygon_multilinestring(a.geom, ST_Collect(ST_MakeLine(b.geom, b.geom2))) geom
        FROM sheipinho_temp a
        LEFT JOIN sheipinho_nodes b ON a.gid = b.gid
        GROUP BY a.gid, a.geom) A;
