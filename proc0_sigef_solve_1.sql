SET search_path TO recorte, public;

--SELECT setval('seq_current_run', (SELECT MAX(num_run) FROM recorte.log_outputs));
SELECT nextval('seq_current_run');

-- SIGEF clean
SELECT recorte.clean_sigef((SELECT param_text FROM recorte.params WHERE param_name = 'snci_input_table'), (SELECT param_text FROM recorte.params WHERE param_name = 'snci_code_column'), (SELECT param_text FROM recorte.params WHERE param_name = 'snci_cert_date_column'), currval('seq_current_run')::int);

DROP TABLE IF EXISTS proc0_01_snci;
CREATE TABLE recorte.proc0_01_snci AS
SELECT * FROM sigef_cleaned;


-- SIGEF law clean
SELECT recorte.clean_sigef((SELECT param_text FROM recorte.params WHERE param_name = 'sigef_input_table'), (SELECT param_text FROM recorte.params WHERE param_name = 'sigef_code_column'), (SELECT param_text FROM recorte.params WHERE param_name = 'sigef_cert_date_column'), currval('seq_current_run')::int);

DROP TABLE IF EXISTS proc0_02_sigef;
CREATE TABLE recorte.proc0_02_sigef AS
SELECT * FROM sigef_cleaned;

DROP TABLE IF EXISTS recorte.proc0_03_sigef_union;
CREATE TABLE recorte.proc0_03_sigef_union AS
SELECT row_number() OVER ()::int rid, *
FROM (SELECT *, true is_law2001 FROM proc0_01_snci
UNION ALL
SELECT *, false FROM proc0_02_sigef) a;

CREATE INDEX gix_proc0_03_sigef_union ON proc0_03_sigef_union USING GIST (geom);
CREATE INDEX ix_proc0_03_sigef_union ON proc0_03_sigef_union USING BTREE (cert_date);
CREATE INDEX ix_proc0_03_sigef_union_1 ON proc0_03_sigef_union USING BTREE (rid);


-- Overlay SIGEF x SIGEF2001, priority to most recent
DROP TABLE IF EXISTS proc0_04_sigef_solved;
CREATE TABLE proc0_04_sigef_solved AS
SELECT rid, original_gid, cod, original_area, area1, ST_Area(geom) area2, cert_date, area_loss area_loss1, (1-(ST_Area(geom)/original_area))*100 area_loss2, is_law2001, does_overlay, geom FROM 
(SELECT a.rid, a.original_gid, a.cod, a.original_area, a.new_area area1, a.cert_date, a.area_loss, a.is_law2001, MAX(b.is_law2001::int) IS NOT NULL does_overlay,
	CASE COUNT(b.rid) 
		WHEN 0 THEN 
			a.geom
		WHEN 1 THEN
			ST_Difference(a.geom, ST_GeometryN(ST_Collect(b.geom), 1))
		ELSE
			ST_Difference(a.geom, ST_Buffer(ST_MakeValid(ST_Collect(b.geom)), 0))
		END geom
FROM proc0_03_sigef_union a
LEFT JOIN proc0_03_sigef_union b ON a.rid <> b.rid AND b.cert_date > a.cert_date AND ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom)
GROUP BY a.rid, a.original_gid, a.cod, a.original_area, a.new_area, a.cert_date, a.area_loss, a.geom, a.is_law2001) c;

CREATE INDEX gix_sigef_solved ON proc0_04_sigef_solved USING GIST (geom);
CREATE INDEX ix_sigef_solved ON proc0_04_sigef_solved USING BTREE (cert_date);

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
		operation.id,
		COUNT(*),
		SUM(area1 - area2)
	FROM log_operation operation,
	proc0_04_sigef_solved b
	WHERE operation.nom_operation = 'sigef_base_lost_to_law' AND NOT is_law2001 AND does_overlay
	GROUP BY operation.id;

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
		operation.id,
		COUNT(*),
		SUM(area1 - area2)
	FROM log_operation operation,
	proc0_04_sigef_solved b
	WHERE operation.nom_operation = 'sigef_law_lost_to_base' AND is_law2001 AND does_overlay
	GROUP BY operation.id;


DROP TABLE IF EXISTS proc0_05_sigef_result;
CREATE TABLE proc0_05_sigef_result AS
SELECT * FROM proc0_04_sigef_solved;


DELETE FROM log_outputs a
USING log_operation b
WHERE a.fk_operation = b.id AND b.nom_operation = 'incra_pr_mischaracterized' AND num_run = currval('seq_current_run');

INSERT INTO log_outputs (num_run, fk_operation, num_geom, val_area)
	SELECT currval('seq_current_run'),
		operation.id,
		COUNT(*),
		SUM(area2)
	FROM log_operation operation,
	proc0_05_sigef_result b
	WHERE operation.nom_operation = 'incra_pr_mischaracterized' AND b.area_loss2 > (SELECT param_value FROM recorte.params WHERE param_name = 'incra_pr_exclusion_tolerance')
	GROUP BY operation.id;

DELETE FROM proc0_05_sigef_result
WHERE area_loss2 > (SELECT param_value FROM recorte.params WHERE param_name = 'incra_pr_exclusion_tolerance');

DROP TABLE IF EXISTS recorte.lt_model_incra_pr;
CREATE TABLE recorte.lt_model_incra_pr AS
SELECT rid, original_gid gid, cod, original_area, area1, area2, cert_date, 
       area_loss1, area_loss2, is_law2001, does_overlay, ST_CollectionExtract(ST_MakeValid(geom),3) geom
  FROM proc0_05_sigef_result;

CREATE INDEX gix_lt_model_incra_pr ON recorte.lt_model_incra_pr USING GIST (geom);