SET search_path TO lt_model, data, public;


--Imoveis a simular
DROP TABLE IF EXISTS malha_municipio;
CREATE TEMP TABLE malha_municipio AS
SELECT a.id, b.id fk_censo_categoria_areas_ibge, m.codmun7 cod_mun, CASE WHEN COUNT(m.coduf) = 1 THEN a.area ELSE ST_Area(ST_Intersection(a.geom, m.geom)) END area
FROM lt_model.result AS a
JOIN censo_categoria_areas_ibge AS b ON a.area >= b.limiar_inferior AND a.area < b.limiar_superior
JOIN public.pa_br_limitemunicipal_2006_ibge m ON ST_Intersects(a.geom, m.geom) AND NOT ST_Touches(a.geom, m.geom)
WHERE a.ownership_class = 'PR' AND m.coduf = 35
GROUP BY a.id, b.id, m.codmun7, a.area, a.geom, m.geom;

CREATE INDEX ix_malha ON malha_municipio USING BTREE (id);

DROP TABLE IF EXISTS malha_municipio2;
CREATE TEMP TABLE malha_municipio2 AS
SELECT cod_mun, fk_censo_categoria_areas_ibge, COUNT(*) contagem, SUM(area)/10000 area FROM malha_municipio a
GROUP BY cod_mun, fk_censo_categoria_areas_ibge;

DROP TABLE IF EXISTS num_imoveis_municipio_simular;
CREATE TEMP TABLE num_imoveis_municipio_simular AS
SELECT a.fk_municipio_ibge, a.fk_censo_categoria_areas_ibge, quantidade - CASE WHEN b.contagem IS NULL THEN 0 ELSE b.contagem END a_simular 
FROM lt_model.num_propriedades_necessario a
LEFT JOIN malha_municipio2 b ON b.cod_mun = a.fk_municipio_ibge AND b.fk_censo_categoria_areas_ibge = a.fk_censo_categoria_areas_ibge
WHERE fk_municipio_ibge = 3548054
ORDER BY a.fk_municipio_ibge, a.fk_censo_categoria_areas_ibge;


-- Passo 1
DROP TABLE IF EXISTS lt_model.censo_percentual_categoria;
CREATE TABLE lt_model.censo_percentual_categoria AS
SELECT fk_municipio_ibge, fk_censo_categoria_areas_ibge, CASE WHEN num_imoveis IS NULL THEN 0::numeric ELSE num_imoveis::numeric END / (SUM(num_imoveis) OVER (PARTITION BY fk_municipio_ibge)) percentual 
FROM censo_areaimovel_ibge;

-- Passo 2
DROP TABLE IF EXISTS propriedades_area;
CREATE TEMP TABLE propriedades_area AS
SELECT cod_mun, SUM(contagem) contagem, SUM(contagem)::NUMERIC/SUM(area) densidade_imoveis
FROM malha_municipio2
GROUP BY cod_mun;

-- Passo 3
DROP TABLE IF EXISTS area_simulate;
CREATE TEMP TABLE area_simulate AS
SELECT cd_mun, SUM(ST_Area(geom))/10000 area 
FROM to_simulate
GROUP BY cd_mun;

DROP TABLE IF EXISTS num_prop_estimada;
CREATE TEMP TABLE num_prop_estimada AS
SELECT cd_mun, a.area * densidade_imoveis num_prop_estimada
FROM area_simulate a
JOIN propriedades_area b ON a.cd_mun = b.cod_mun;

-- Passo 4
DROP TABLE IF EXISTS lt_model.num_propriedades_necessario;
CREATE TABLE lt_model.num_propriedades_necessario AS
SELECT a.fk_municipio_ibge, a.fk_censo_categoria_areas_ibge, ROUND(a.percentual * (b.num_prop_estimada + c.contagem)) quantidade
FROM lt_model.censo_percentual_categoria a
JOIN num_prop_estimada b ON a.fk_municipio_ibge = b.cd_mun
JOIN propriedades_area c ON c.cod_mun = a.fk_municipio_ibge
ORDER BY a.fk_municipio_ibge, a.fk_censo_categoria_areas_ibge;


DROP TABLE IF EXISTS properties_to_simulate;
CREATE TEMP TABLE properties_to_simulate AS
SELECT fk_municipio_ibge, b.fk_censo_categoria_areas_ibge, COUNT(a.*) contagem, SUM(a.area/10000) area_exist, a_simular
FROM lt_model.to_simulate a
JOIN num_imoveis_municipio_simular b ON a.cd_mun = b.fk_municipio_ibge
JOIN data.censo_categoria_areas_ibge c ON b.fk_censo_categoria_areas_ibge = c.id AND (a.area/10000) >= c.limiar_inferior AND (a.area/10000) < c.limiar_superior
GROUP BY fk_municipio_ibge, b.fk_censo_categoria_areas_ibge, a_simular
ORDER BY fk_municipio_ibge, b.fk_censo_categoria_areas_ibge;


DO $$
DECLARE pcursor REFCURSOR;
BEGIN
	
	LOOP
		FETCH FROM pcursor INTO var_input;
		EXIT WHEN NOT FOUND;
		RAISE NOTICE '%: %', var_input.proc_order, var_input.table_name;
	END LOOP;

END $$;

