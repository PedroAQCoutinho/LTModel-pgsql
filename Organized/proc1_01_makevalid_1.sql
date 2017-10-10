-- CAR SOLVING
SET search_path TO lt_model, public;


-- Copy original table
DROP TABLE IF EXISTS proc1_00_0makevalid;
CREATE TABLE proc1_00_0makevalid (
 gid INT,
 cod_imovel TEXT,
 shape_area DOUBLE PRECISION,
 shape_leng DOUBLE PRECISION,
 geom geometry,
 is_valid BOOLEAN
);


CREATE INDEX gix_proc1_00_0makevalid ON proc1_00_0makevalid USING GIST (geom);
CREATE INDEX ix_proc1_00_0makevalid_1 ON proc1_00_0makevalid USING BTREE ((ST_XMin(geom)), (ST_YMin(geom)), (ST_XMax(geom)), (ST_YMax(geom))); --13.7s