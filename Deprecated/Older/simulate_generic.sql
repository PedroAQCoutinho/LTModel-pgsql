SET search_path TO recorte, public;
 CREATE INDEX IF NOT EXISTS ix_limpa_area_simulada_15 ON proc3_12_a_limpar_area_simulada USING BTREE ((cd_mun % 15));

-- Simplify multipolygon
DROP TABLE IF EXISTS sheipinho_temp;
CREATE TEMP TABLE sheipinho_temp AS
SELECT ROW_NUMBER() OVER () gid, cd_mun, geom FROM (
SELECT cd_mun, (ST_Dump(geom)).geom
FROM proc3_12_a_limpar_area_simulada
WHERE (cd_mun % 15) = var_n_process) as A;


-- Get max node index
    DROP TABLE IF EXISTS nodes_max;
    CREATE TEMP TABLE nodes_max AS
    SELECT *, MAX(path2) OVER (PARTITION BY cd_mun, gid, path1) max_path FROM (
    SELECT cd_mun, gid, (geom).path[1] path1, (geom).path[2] path2, (geom).geom FROM
    (SELECT cd_mun, gid, (ST_DumpPoints(geom)) geom
    FROM sheipinho_temp) A) b;

    CREATE INDEX gix_nodes_max ON nodes_max USING GIST (geom);
    ANALYZE nodes_max;


-- Create nodes pair, based on distance <= 60m
    DROP TABLE IF EXISTS path_pair;
    CREATE TEMP TABLE path_pair AS
    SELECT a.cd_mun, a.gid, a.path1, a.path2, a.geom, MAX(b.path2) path3
    FROM nodes_max a
    JOIN nodes_max b ON a.cd_mun = b.cd_mun AND a.gid = b.gid AND ST_DWithin(a.geom, b.geom, 60) AND a.path1 = b.path1 AND a.path2 < b.path2 AND(b.path2-a.path2) > 1 AND ((a.path2 + b.max_path - 1) - b.path2) > 1
    GROUP BY a.cd_mun, a.gid, a.path1, a.path2, a.geom;

    CREATE INDEX ix_path_pair_1 ON path_pair USING BTREE (cd_mun, gid, path1);
    CREATE INDEX ix_nodes_max_2 ON nodes_max USING BTREE (cd_mun, gid, path1);
    
    
    ANALYZE path_pair;

-- Create nodes pair if at least one intermediate is at least at 200m of distance    
    DROP TABLE IF EXISTS path_dist;
    CREATE TEMP TABLE path_dist AS
    SELECT a.cd_mun, a.gid, MIN(a.path2) path, a.geom, a.path1, a.path3
    FROM path_pair a
    JOIN nodes_max b ON a.cd_mun = b.cd_mun AND a.gid = b.gid AND a.path1 = b.path1 AND (((a.path3 - a.path2) > (b.max_path/2) AND (b.path2 < a.path2 OR b.path2 > a.path3)) OR ((a.path3 - a.path2) <= (b.max_path/2) AND b.path2 BETWEEN a.path2+1 AND a.path3-1)) AND NOT ST_DWithin(a.geom, b.geom, 200)
    GROUP BY a.cd_mun, a.gid, a.geom, a.path1, a.path3;

    CREATE INDEX ix_path_dist ON path_dist USING BTREE (cd_mun, gid, path1, path3);
    CREATE INDEX ix_nodes_max_3 ON nodes_max USING BTREE (cd_mun, gid, path1, path2);
    ANALYZE path_dist;
    ANALYZE nodes_max;

    
-- Create nodes pair geometry
DROP TABLE IF EXISTS sheipinho_nodes;
    CREATE TEMP TABLE sheipinho_nodes AS
    SELECT a.*, b.geom geom2
    FROM path_dist a
    JOIN nodes_max b ON a.cd_mun = b.cd_mun AND a.gid = b.gid AND a.path1 = b.path1 AND a.path3 = b.path2;

    CREATE INDEX ix_sheipinho_nodes ON sheipinho_nodes USING BTREE (cd_mun, gid);
    CREATE INDEX ix_sheipinho_temp ON sheipinho_temp USING BTREE (cd_mun, gid);


-- Returns the result of the cutting
INSERT INTO proc3_13_limpa_area_simulada_result
SELECT *, row_number() OVER () gid, ST_Area(geom)/10000 area_ha FROM
    (SELECT cd_mun, (ST_Dump(geom)).geom
    FROM (SELECT a.cd_mun, a.gid, recorte.cut_polygon_multilinestring(a.geom, ST_Collect(ST_MakeLine(b.geom, b.geom2))) geom
    FROM sheipinho_temp a
    LEFT JOIN sheipinho_nodes b ON a.cd_mun = b.cd_mun AND a.gid = b.gid
    GROUP BY a.cd_mun, a.gid, a.geom) A) B;