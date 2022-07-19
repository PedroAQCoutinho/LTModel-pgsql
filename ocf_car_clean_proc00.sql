-- CONFIGURA��ES --

-- Definindo tabela de inputs com nova hierarquia
UPDATE recorte.inputs SET fla_proc = FALSE
WHERE proc_order NOT IN (100,250,850,1100,1105);

UPDATE recorte.inputs SET fla_proc = TRUE
WHERE proc_order IN (100,250,850,1100,1105);

-- Atualizando tabela

UPDATE recorte.params
SET param_text = 'input_snci_privado_incra_null' WHERE id = 14;

UPDATE recorte.params
SET param_text = 'input_sigef_privado_incra_null' WHERE id = 17;

UPDATE recorte.params
SET param_text = 'input_car_iru' WHERE id = 26;

UPDATE recorte.params
SET param_text = 'lt_model' WHERE id = 27;


-- Criando tabelas vazias do SIGEF e do SNCI
DROP TABLE IF EXISTS recorte.input_snci_privado_incra_null;
CREATE TABLE recorte.input_snci_privado_incra_null AS 
	(SELECT * FROM recorte.input_snci_privado_incra_2020 LIMIT 0);

DROP TABLE IF EXISTS recorte.input_sigef_privado_incra_null;
CREATE TABLE recorte.input_sigef_privado_incra_null AS 
	(SELECT * FROM recorte.input_sigef_privado_incra_2020 LIMIT 0);

--PROC01--
-- Separa��o dos pol�gonos de cada tipo (IRU, AST, PCT)
DROP TABLE IF EXISTS recorte.input_car_iru;
CREATE TABLE recorte.input_car_iru AS (
	SELECT * FROM car.pa_br_20210412_areaimovel_albers
	WHERE tp_imovel = 'IRU'
);

DROP TABLE IF EXISTS recorte.input_car_ast;
CREATE TABLE recorte.input_car_ast AS (
	SELECT * FROM car.pa_br_20210412_areaimovel_albers
	WHERE tp_imovel = 'AST'
);
UPDATE recorte.input_car_ast SET geom = ST_CollectionExtract(ST_MakeValid(geom),3) WHERE ST_IsValid(geom) IS FALSE;

DROP TABLE IF EXISTS recorte.input_car_pct;
CREATE TABLE recorte.input_car_pct  AS (
	SELECT * FROM car.pa_br_20210412_areaimovel_albers
	WHERE tp_imovel = 'PCT'
);
----------

--PROC03--
-- Marca��o dos pol�gonos com geometria id�ntica
DROP TABLE IF EXISTS recorte.car_clean_proc03_ast_equalshape;
CREATE TABLE recorte.car_clean_proc03_ast_equalshape AS (
 SELECT a.fid 
 FROM 
  recorte.input_car_ast a,
  recorte.input_car_ast b 
 WHERE 
  a.fid > b.fid 
	AND 
  ((a.nu_area = b.nu_area AND ST_Intersects(a.geom,b.geom))
	OR 
  ST_Equals(a.geom,b.geom))
);

-- Marca��o dos pol�gonos inteiramente sobrepostos
DROP TABLE IF EXISTS recorte.car_clean_proc03_ast_withinshape;
CREATE TABLE recorte.car_clean_proc03_ast_withinshape AS (
  SELECT b.fid
  FROM 
	  recorte.input_car_ast a,
		recorte.input_car_ast b
  WHERE 
	  a.fid <> b.fid 
		AND
		ST_Within(b.geom,a.geom) 
		AND
		a.fid NOT IN (SELECT fid FROM recorte.car_clean_proc03_ast_equalshape WHERE fid IS NOT NULL) 
		AND
		b.fid NOT IN (SELECT fid FROM recorte.car_clean_proc03_ast_equalshape WHERE fid IS NOT NULL)
);

CREATE TABLE recorte.temp_car_clean_proc03_ast_excludelist_1 AS (
	SELECT fid FROM recorte.car_clean_proc03_ast_equalshape
	UNION
	SELECT fid FROM recorte.car_clean_proc03_ast_withinshape
);

-- Marca��o dos pol�gonos com mais de 75% de sobreposi��o
DROP TABLE IF EXISTS recorte.car_clean_proc03_ast_overlapshape;
CREATE TABLE recorte.car_clean_proc03_ast_overlapshape AS (
	SELECT DISTINCT ON (fid)
		CASE WHEN (sub.area_sobreposta / sub.nu_area_a) BETWEEN 0.75 AND 1.0 THEN
			CASE WHEN (sub.area_sobreposta / sub.nu_area_a) <  (sub.area_sobreposta / sub.nu_area_b) THEN fid_b
				ELSE fid_a
			END
			ELSE NULL
		END AS fid
	FROM 
		(SELECT
			a.fid fid_a,
			b.fid fid_b,
			a.nu_area nu_area_a,
			b.nu_area nu_area_b,
			ST_Area(ST_Intersection(a.geom,b.geom))/10000 area_sobreposta
		FROM recorte.input_car_ast a
		JOIN recorte.input_car_ast b
			ON ST_Intersects(a.geom,b.geom) AND a.fid <> b.fid
		WHERE 		  
			a.fid NOT IN (SELECT fid FROM recorte.temp_car_clean_proc03_ast_excludelist_1 WHERE fid IS NOT NULL)
			AND
			b.fid NOT IN (SELECT fid FROM recorte.temp_car_clean_proc03_ast_excludelist_1 WHERE fid IS NOT NULL)
		ORDER BY a.fid, area_sobreposta DESC) sub
);


CREATE TABLE recorte.temp_car_clean_proc03_ast_excludelist_2 AS (
	SELECT fid FROM recorte.temp_car_clean_proc03_ast_excludelist_1
	UNION
	SELECT fid FROM recorte.car_clean_proc03_ast_overlapshape
);

-- Limpeza tempor�ria da base original a partir da marca��o dos pol�gonos
DROP TABLE IF EXISTS recorte.temp_input_car_ast_cleaned;
CREATE TABLE recorte.temp_input_car_ast_cleaned AS (
 SELECT * FROM recorte.input_car_ast 
 WHERE fid NOT IN (SELECT fid FROM recorte.temp_car_clean_proc03_ast_excludelist_2 WHERE fid IS NOT NULL)
);

-- Marca��o dos pol�gonos com mais de uma sobreposi��o
DROP TABLE IF EXISTS recorte.car_clean_proc03_ast_overlaps_shapes;
CREATE TABLE recorte.car_clean_proc03_ast_overlaps_shapes AS (
	SELECT DISTINCT ON (fid)
		CASE WHEN ROUND((sub.area_sobreposta / sub.nu_area_a)::NUMERIC,2) BETWEEN 0.75 AND 1.0 THEN fid_a
			ELSE NULL
		END AS fid
	FROM 
		(SELECT
			a.fid fid_a,
			a.nu_area AS nu_area_a,
			ST_Area(ST_Intersection(a.geom,
				ST_Union(b.geom)))/10000 area_sobreposta
		FROM recorte.temp_input_car_ast_cleaned a
		JOIN recorte.temp_input_car_ast_cleaned b
			ON ST_Intersects(a.geom,b.geom) AND a.fid <> b.fid
		GROUP BY a.fid,a.geom,a.nu_area
		ORDER BY a.fid, area_sobreposta DESC) sub
);

CREATE TABLE recorte.temp_car_clean_proc03_ast_excludelist_3 AS (
	SELECT fid FROM recorte.temp_car_clean_proc03_ast_excludelist_2
	UNION
	SELECT fid FROM recorte.car_clean_proc03_ast_overlaps_shapes
);

-- Limpeza final da base original a partir da marca��o dos pol�gonos
DROP TABLE IF EXISTS recorte.input_car_ast_cleaned;
CREATE TABLE recorte.input_car_ast_cleaned AS (
 SELECT * FROM recorte.input_car_ast 
 WHERE fid NOT IN (SELECT fid FROM recorte.temp_car_clean_proc03_ast_excludelist_3 WHERE fid IS NOT NULL)
);


-- Exclus�o das tabelas tempor�rias
DROP TABLE recorte.temp_car_clean_proc03_ast_excludelist_1;
DROP TABLE recorte.temp_car_clean_proc03_ast_excludelist_2;
DROP TABLE recorte.temp_car_clean_proc03_ast_excludelist_3;
DROP TABLE recorte.temp_input_car_ast_cleaned;
----------
-------------------------------------------------------

-- ROLLBACK PARA MALHA FUNDIÁRIA
-- UPDATE recorte.inputs SET fla_proc = TRUE
-- WHERE proc_order NOT IN (56,250,850);

-- UPDATE recorte.inputs SET fla_proc = FALSE
-- WHERE proc_order IN (56,250,850);

-- UPDATE recorte.params
-- SET param_text = 'input_snci_privado_incra_2020' WHERE id = 14;
-- UPDATE recorte.params
-- SET param_text = 'input_sigef_privado_incra_2020' WHERE id = 17;
-- UPDATE recorte.params
-- SET param_text = 'pa_br_20210122_areaimovel_albers' WHERE id = 26;
-- UPDATE recorte.params
-- SET param_text = 'car' WHERE id = 27;
