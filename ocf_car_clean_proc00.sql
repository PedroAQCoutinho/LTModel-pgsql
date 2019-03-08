-- CONFIGURA��ES --

-- Definindo tabela de inputs com nova hierarquia
create table lt_model.inputs_carocf as (select * from lt_model.inputs);

update lt_model.inputs_carocf set fla_proc = FALSE
where proc_order NOT IN (100,200,800,1100,1105);

update lt_model.inputs_carocf
set table_name = 'input_car_pct_20180901_sfb',
	layer_name = 'Imoveis do CAR do tipo PCT',
	fla_proc = TRUE,
  column_name = 'cod_imovel'
where proc_order = 200; 

update lt_model.inputs_carocf
set table_name = 'input_car_ast_20180901_sfb_cleaned',
	layer_name = 'Imoveis do CAR do tipo AST',
	fla_proc = TRUE,
  column_name = 'cod_imovel'
where proc_order = 800; 

ALTER TABLE lt_model.inputs
RENAME TO inputs_old;

ALTER TABLE lt_model.inputs_carocf
RENAME TO inputs;

-- Alterando tabela params com novos inputs
create table lt_model.params_carocf as (select * from lt_model.params);

-- Atualizando tabela
update lt_model.params_carocf
set param_text = 'input_acervofundiario_snci_particular_2018_incra_null' where id = 14;

update lt_model.params_carocf
set param_text = 'input_acervofundiario_sigef_particular_2018_incra_null' where id = 17;

update lt_model.params_carocf
set param_text = 'input_car_iru_20180901_sfb' where id = 26;

update lt_model.params_carocf
set param_text = 'lt_model' where id = 27;

ALTER TABLE lt_model.params
RENAME TO params_old;

ALTER TABLE lt_model.params_carocf
RENAME TO params;

-- Criando tabelas vazias do SIGEF e do SNCI
create table lt_model.input_acervofundiario_snci_particular_2018_incra_null AS (select * from lt_model.input_acervofundiario_snci_particular_2018_incra limit 0);
create table lt_model.input_acervofundiario_sigef_particular_2018_incra_null AS (select * from lt_model.input_acervofundiario_sigef_particular_2018_incra limit 0);

--PROC01--
-- Separa��o dos pol�gonos de cada tipo (IRU, AST, PCT)
CREATE TABLE lt_model.input_car_iru_20180901_sfb AS (
	SELECT * FROM car.input_pa_br_areaimovel_20180901_sfb
	WHERE tipo = 'IRU'
);

CREATE TABLE lt_model.input_car_ast_20180901_sfb AS (
	SELECT * FROM car.input_pa_br_areaimovel_20180901_sfb
	WHERE tipo = 'AST'
);

CREATE TABLE lt_model.input_car_pct_20180901_sfb  AS (
	SELECT * FROM car.input_pa_br_areaimovel_20180901_sfb
	WHERE tipo = 'PCT'
);
----------

--PROC03--
-- Marca��o dos pol�gonos com geometria id�ntica
DROP TABLE IF EXISTS lt_model.car_clean_proc03_ast_equalshape;
CREATE TABLE lt_model.car_clean_proc03_ast_equalshape AS (
 SELECT a.gid 
 FROM 
  lt_model.input_car_ast_20180901_sfb a,
  lt_model.input_car_ast_20180901_sfb b 
 WHERE 
  a.gid > b.gid 
	AND 
  ((a.area_orig = b.area_orig AND ST_Intersects(a.geom,b.geom))
	OR 
  ST_Equals(a.geom,b.geom))
);

-- Marca��o dos pol�gonos inteiramente sobrepostos
DROP TABLE IF EXISTS lt_model.car_clean_proc03_ast_withinshape;
CREATE TABLE lt_model.car_clean_proc03_ast_withinshape AS (
  SELECT b.gid
  FROM 
	  lt_model.input_car_ast_20180901_sfb a,
		lt_model.input_car_ast_20180901_sfb b
  WHERE 
	  a.gid <> b.gid 
		AND
		ST_Within(b.geom,a.geom) 
		AND
		a.gid NOT IN (SELECT gid FROM lt_model.car_clean_proc03_ast_equalshape WHERE gid IS NOT NULL) 
		AND
		b.gid NOT IN (SELECT gid FROM lt_model.car_clean_proc03_ast_equalshape WHERE gid IS NOT NULL)
);

CREATE TABLE lt_model.temp_car_clean_proc03_ast_excludelist_1 AS (
	SELECT gid FROM lt_model.car_clean_proc03_ast_equalshape
	UNION
	SELECT gid FROM lt_model.car_clean_proc03_ast_withinshape
);

-- Marca��o dos pol�gonos com mais de 75% de sobreposi��o
DROP TABLE IF EXISTS lt_model.car_clean_proc03_ast_overlapshape;
CREATE TABLE lt_model.car_clean_proc03_ast_overlapshape AS (
	SELECT DISTINCT ON (gid)
		CASE WHEN (sub.area_sobreposta / sub.area_orig_a) BETWEEN 0.75 AND 1.0 THEN
			CASE WHEN (sub.area_sobreposta / sub.area_orig_a) <  (sub.area_sobreposta / sub.area_orig_b) THEN gid_b
				ELSE gid_a
			END
			ELSE NULL
		END AS gid
	FROM 
		(SELECT
			a.gid gid_a,
			b.gid gid_b,
			a.area_orig area_orig_a,
			b.area_orig area_orig_b,
			ST_Area(ST_Intersection(a.geom,b.geom))/10000 area_sobreposta
		FROM lt_model.input_car_ast_20180901_sfb a
		JOIN lt_model.input_car_ast_20180901_sfb b
			ON ST_Intersects(a.geom,b.geom) AND a.gid <> b.gid
		WHERE 		  
			a.gid NOT IN (SELECT gid FROM lt_model.temp_car_clean_proc03_ast_excludelist_1 WHERE gid IS NOT NULL)
			AND
			b.gid NOT IN (SELECT gid FROM lt_model.temp_car_clean_proc03_ast_excludelist_1 WHERE gid IS NOT NULL)
		ORDER BY a.gid, area_sobreposta DESC) sub
);


CREATE TABLE lt_model.temp_car_clean_proc03_ast_excludelist_2 AS (
	SELECT gid FROM lt_model.temp_car_clean_proc03_ast_excludelist_1
	UNION
	SELECT gid FROM lt_model.car_clean_proc03_ast_overlapshape
);

-- Limpeza tempor�ria da base original a partir da marca��o dos pol�gonos
DROP TABLE IF EXISTS lt_model.temp_input_car_ast_20180901_sfb_cleaned;
CREATE TABLE lt_model.temp_input_car_ast_20180901_sfb_cleaned AS (
 SELECT * FROM lt_model.input_car_ast_20180901_sfb 
 WHERE gid NOT IN (SELECT gid FROM lt_model.temp_car_clean_proc03_ast_excludelist_2 WHERE gid IS NOT NULL)
);

-- Marca��o dos pol�gonos com mais de uma sobreposi��o
DROP TABLE IF EXISTS lt_model.car_clean_proc03_ast_overlaps_shapes;
CREATE TABLE lt_model.car_clean_proc03_ast_overlaps_shapes AS (
	SELECT DISTINCT ON (gid)
		CASE WHEN ROUND((sub.area_sobreposta / sub.area_orig_a)::NUMERIC,2) BETWEEN 0.75 AND 1.0 THEN gid_a
			ELSE NULL
		END AS gid
	FROM 
		(SELECT
			a.gid gid_a,
			a.area_orig AS area_orig_a,
			ST_Area(ST_Intersection(a.geom,
				ST_Union(b.geom)))/10000 area_sobreposta
		FROM lt_model.temp_input_car_ast_20180901_sfb_cleaned a
		JOIN lt_model.temp_input_car_ast_20180901_sfb_cleaned b
			ON ST_Intersects(a.geom,b.geom) AND a.gid <> b.gid
		GROUP BY a.gid,a.geom,a.area_orig
		ORDER BY a.gid, area_sobreposta DESC) sub
);

CREATE TABLE lt_model.temp_car_clean_proc03_ast_excludelist_3 AS (
	SELECT gid FROM lt_model.temp_car_clean_proc03_ast_excludelist_2
	UNION
	SELECT gid FROM lt_model.car_clean_proc03_ast_overlaps_shapes
);

-- Limpeza final da base original a partir da marca��o dos pol�gonos
DROP TABLE IF EXISTS lt_model.input_car_ast_20180901_sfb_cleaned;
CREATE TABLE lt_model.input_car_ast_20180901_sfb_cleaned AS (
 SELECT * FROM lt_model.input_car_ast_20180901_sfb 
 WHERE gid NOT IN (SELECT gid FROM lt_model.temp_car_clean_proc03_ast_excludelist_3 WHERE gid IS NOT NULL)
);


-- Exclus�o das tabelas tempor�rias
DROP TABLE lt_model.temp_car_clean_proc03_ast_excludelist_1;
DROP TABLE lt_model.temp_car_clean_proc03_ast_excludelist_2;
DROP TABLE lt_model.temp_car_clean_proc03_ast_excludelist_3;
DROP TABLE lt_model.temp_input_car_ast_20180901_sfb_cleaned;
----------
-------------------------------------------------------