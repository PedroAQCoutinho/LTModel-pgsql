﻿SELECT 'DROP TABLE lt_model.' || table_name || ';' FROM information_schema.tables WHERE table_schema = 'lt_model' AND LENGTH(table_name) > 20;




-- Table: lt_model.result

DROP TABLE lt_model.result;

CREATE TABLE lt_model.result
(
  gid serial NOT NULL,
  original_gid integer NOT NULL,
  table_source text,
  ownership_class text,
  sub_class text,
  apa_area_loss numeric(30,2),
  aru_area_loss numeric(30,2),
  car_area_loss numeric(30,2),
  com_area_loss numeric(30,2),
  incra_area_loss numeric(30,2),
  ml_area_loss numeric(30,2),
  nd_area_loss numeric(30,2),
  ql_area_loss numeric(30,2),
  ti_area_loss numeric(30,2),
  trans_area_loss numeric(30,2),
  ucpi_area_loss numeric(30,2),
  ucus_area_loss numeric(30,2),
  urb_area_loss numeric(30,2),
  wt_area_loss numeric(30,2),
  area numeric(30,2),
  area_original numeric(30,2),
  geom geometry(Geometry,97823),
  CONSTRAINT result_pkey PRIMARY KEY (gid),
  CONSTRAINT result_ukey UNIQUE (original_gid, table_source)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE lt_model.result
  OWNER TO postgres;

-- Index: lt_model.ix_result_geom

-- DROP INDEX lt_model.ix_result_geom;

CREATE INDEX ix_result_geom
  ON lt_model.result
  USING gist
  (geom);

-- Index: lt_model.ix_result_key

-- DROP INDEX lt_model.ix_result_key;

CREATE INDEX ix_result_key
  ON lt_model.result
  USING btree
  (original_gid, table_source COLLATE pg_catalog.default);



SELECT lt_model.simplify_if_needed('es_sp_car_areaimovel_2016_sfb');


SELECT lt_model.solve_car('es_sp_car_areaimovel_2016_sim_sfb');
SELECT DISTINCT ST_GeometryType(geom) FROM lt_model.es_sp_car_areaimovel_2016_sim_solve_sfb;
SELECT DISTINCT ST_GeometryType(geom) FROM lt_model.result;

BEGIN TRANSACTION;
SET search_path TO public, lt_model;
SELECT DISTINCT ST_GeometryType(geom) FROM lt_model.result;

DELETE FROM lt_model.result a
USING lt_model.es_sp_car_areaimovel_2016_sim_solve_sfb b
WHERE ST_Contains(b.geom, a.geom);

UPDATE lt_model.result r
SET
	geom = CASE WHEN ST_IsValid(A.geom) THEN A.geom ELSE ST_MakeValid(A.geom) END,
	car_area_loss = CASE WHEN A.sub_class = 'CAR' THEN NULL ELSE CASE WHEN car_area_loss IS NULL THEN 0 ELSE car_area_loss END + (previous_area - current_area) END,
	area = current_area
FROM (
	SELECT *, ST_Area(B.geom) current_area
	FROM (
	SELECT count(*)
-- 		r.original_gid,
-- 		r.table_source,
-- 		r.sub_class,
-- 		ST_Force2D(ST_Difference(r.geom, ST_UNION(m.geom))) geom,
-- 		r.area previous_area
	FROM lt_model.result r
	JOIN es_sp_car_areaimovel_2016_sim_solve_sfb m ON NOT ST_IsEmpty(m.geom) AND ST_IsValid(m.geom) AND ST_Intersects(r.geom, m.geom)
	GROUP BY r.original_gid, r.table_source, r.geom, r.area, r.sub_class) B
	) A
WHERE r.original_gid = A.original_gid AND r.table_source = A.table_source;

CREATE TABLE lt_model.testing as
SELECT 
		r.original_gid,
		r.table_source,
		r.sub_class,
		ST_Force2D(ST_Difference(r.geom, ST_UNION(m.geom))) geom,
		r.area previous_area
	FROM lt_model.result r
	JOIN es_sp_car_areaimovel_2016_sim_solve_sfb m ON NOT ST_IsEmpty(m.geom) AND ST_IsValid(m.geom) AND ST_Intersects(r.geom, m.geom)
	GROUP BY r.original_gid, r.table_source, r.geom, r.area, r.sub_class;

DROP TABLE lt_model.buffer_test2;
EXEC SQL WHENEVER SQLERROR SQLPRINT;
CREATE TABLE lt_model.buffer_test2 AS



DO $$
BEGIN
SELECT r.original_gid gid, ST_Force2D(ST_Difference(r.geom, ST_Collect(m.geom))) geom
FROM lt_model.result r
JOIN lt_model.es_sp_car_areaimovel_2016_sim_solve_sfb m ON NOT ST_IsEmpty(m.geom) AND ST_IsValid(m.geom) AND ST_Intersects(r.geom, m.geom)
 GROUP BY r.original_gid, r.table_source, r.geom, r.area, r.sub_class;

EXCEPTION WHEN others THEN 
	RAISE NOTICE 'O que?'; 
END $$;

 SELECT * FROM lt_model.buffer_test WHERE ST_IsEmpty(geom)

ROLLBACK TRANSACTION;

DROP TABLE lt_model.result_single_polygon;
CREATE TABLE lt_model.result_single_polygon AS
SELECT ROW_NUMBER() OVER () rid, * 
FROM (
	SELECT gid, original_gid, table_source, ownership_class, sub_class, 
	       apa_area_loss, aru_area_loss, car_area_loss, com_area_loss, incra_area_loss, 
	       ml_area_loss, nd_area_loss, ql_area_loss, ti_area_loss, trans_area_loss, 
	       ucpi_area_loss, ucus_area_loss, urb_area_loss, wt_area_loss, 
	       area, area_original, (ST_Dump(geom)).geom::geometry(Polygon, 97823)
	FROM lt_model.result) A;

UPDATE lt_model.result_single_polygon 
SET area = ST_Area(geom);

CREATE INDEX ix_result_single_polygon ON lt_model.result_single_polygon USING gist (geom);
CREATE INDEX ix_result_single_polygon_area ON lt_model.result_single_polygon USING BTREE (area);
