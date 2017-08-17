SET search_path TO lt_model, data, public;

ALTER TABLE lt_model.result
ADD COLUMN IF NOT EXISTS cd_mun_2006 INT;

ALTER TABLE lt_model.result
ADD COLUMN IF NOT EXISTS gid serial;



CREATE INDEX IF NOT EXISTS gix_result ON lt_model.result USING GIST(geom);
CREATE INDEX IF NOT EXISTS ix_result ON lt_model.result USING BTREE (gid);
CREATE INDEX IF NOT EXISTS pa_br_limitemunicipal_2006_ibge ON pa_br_limitemunicipal_2006_ibge USING BTREE ((codmun7 % 15));



-- $sql = 'UPDATE lt_model.result a SET cd_mun_2006 = b.codmun7 FROM pa_br_limitemunicipal_2006_ibge b JOIN data.municipio_ibge c ON b.codmun7 = c.cod_ibge AND c.fk_estado_ibge = 35 WHERE ST_Within(a.geom, b.geom) AND (b.codmun7 % 15) = {num};'
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}
DROP TABLE IF EXISTS lt_model.proc2_00_lo_mun;
CREATE TABLE lt_model.proc2_00_lo_mun 
(
gid INT,
codmun7 INT
);


-- Powershell
-- $sql = 'INSERT INTO lt_model.proc2_00_lo_mun SELECT a.gid, b.codmun7 FROM  lt_model.result a JOIN pa_br_limitemunicipal_2006_ibge b ON ST_Intersects(a.geom, b.geom) WHERE a.cd_mun_2006 IS NULL AND b.coduf = 35 AND (b.codmun7 % 15) = {num};'
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}


DROP TABLE IF EXISTS lt_model.proc3_01_mun2;
CREATE TABLE lt_model.proc3_01_mun2 (
gid INT, 
codmun7 INT,
area DOUBLE PRECISION
);

-- $sql = 'INSERT INTO lt_model.proc3_01_mun2 SELECT a.gid, a.codmun7, ST_Area(ST_Intersection(b.geom, c.geom)) area FROM lt_model.proc2_00_lo_mun a JOIN public.pa_br_limitemunicipal_2006_ibge b ON a.codmun7 = b.codmun7 JOIN lt_model.result c ON c.cd_mun_2006 IS NULL AND a.gid = c.gid WHERE (b.codmun7 % 15) = {num};'
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}


DROP TABLE IF EXISTS lt_model.proc3_02_mun3;
CREATE TABLE lt_model.proc3_02_mun3 AS
SELECT DISTINCT ON (gid) gid, codmun7 
FROM lt_model.proc3_01_mun2
ORDER BY gid, area DESC;


UPDATE lt_model.result a
SET cd_mun_2006 = b.codmun7
FROM lt_model.proc3_02_mun3 b
WHERE a.gid = b.gid;

CREATE TABLE lt_model.result2 AS
SELECT gid, table_source, ownership_class, sub_class, area_original, 
       original_gid, ST_Multi(ST_CollectionExtract(ST_MakeValid(geom), 3))::geometry('MultiPolygon', 97823) geom, area, ag_area_loss, aru_area_loss, carpo_area_loss, 
       carpr_area_loss, com_area_loss, ml_area_loss, nd_area_loss, ql_area_loss, 
       sigef_area_loss, ti_area_loss, tlpc_area_loss, tlpl_area_loss, 
       trans_area_loss, ucpi_area_loss, ucus_area_loss, urb_area_loss, 
       cd_mun_2006
  FROM lt_model.result
  WHERE cd_mun_2006 IS NOT NULL;



DROP TABLE IF EXISTS lt_model.proc3_03_simulate;
CREATE TABLE lt_model.proc3_03_simulate (
cd_mun INT,
geom geometry
);

SELECT * FROM exposed.numaccess 

CREATE INDEX ix_lt_model_result2 ON lt_model.result2 USING GIST (geom);


-- $sql = 'INSERT INTO lt_model.proc3_03_simulate SELECT a.codmun7 cd_mun, ST_Difference(a.geom, ST_Buffer(ST_CollectionExtract(ST_MakeValid(ST_Collect(b.geom)), 3), 0.01)) geom FROM pa_br_limitemunicipal_2006_ibge a LEFT JOIN lt_model.result2 b ON ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom) WHERE (a.codmun7 % 15) = {num} GROUP BY a.codmun7, a.geom;';
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}


DROP TABLE IF EXISTS lt_model.proc3_04_simulate_single;
CREATE TABLE lt_model.proc3_04_simulate_single (
gid SERIAL PRIMARY KEY,
cd_mun INT,
geom geometry
);


-- Powershell
-- $sql = 'INSERT INTO lt_model.proc3_04_simulate_single(cd_mun, geom) SELECT cd_mun, (ST_Dump(geom)).geom FROM lt_model.proc3_03_simulate WHERE (cd_mun % 15) = {num};'
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}



-- Powershell
-- $sql = 'INSERT INTO lt_model.result (ownership_class, sub_class, original_gid, area, geom) SELECT ''SI'', ''SI'', gid, ST_Area(geom), geom FROM lt_model.proc3_02_simulate_single WHERE (gid % 15) = {num};'
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}

-- 
-- DROP TABLE IF EXISTS proc3_03_malha_municipio;
-- CREATE TABLE lt_model.proc3_03_malha_municipio
-- (
-- id INT,
-- cod_mun INT,
-- area DOUBLE PRECISION
-- );
-- 
-- 
-- -- $sql = 'INSERT INTO lt_model.proc3_03_malha_municipio SELECT a.gid id, m.cd_mun cod_mun, CASE WHEN ST_Within(a.geom, m.geom) THEN a.area ELSE ST_Area(ST_Intersection(a.geom, m.geom)) END area FROM lt_model.result AS a JOIN public.pa_br_municipios_250_2015_ibge_albers m ON ST_Intersects(a.geom, m.geom) AND NOT ST_Touches(a.geom, m.geom) JOIN data.municipio_ibge c ON m.cd_mun = c.cod_ibge AND fk_estado_ibge = 35 WHERE (m.cd_mun % 15) = {num}'
-- -- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}
-- 
-- 
-- CREATE INDEX ix_proc3_03_malha_municipio ON lt_model.proc3_03_malha_municipio USING BTREE (id);
-- CREATE INDEX ix_proc3_03_malha_municipio_1 ON lt_model.proc3_03_malha_municipio USING BTREE (cod_mun);
-- CREATE INDEX ix_proc3_03_malha_municipio_2 ON lt_model.proc3_03_malha_municipio USING BTREE (id, area);
-- 
-- 
-- SELECT DISTINCT ON (id) id, cod_mun, area
-- FROM proc3_03_malha_municipio a
-- WHERE (a.cod_mun % 15) = {num}
-- ORDER BY id, area DESC

--Imoveis a simular
DROP TABLE IF EXISTS malha_municipio;
CREATE TEMP TABLE malha_municipio AS
SELECT a.gid, b.id fk_censo_categoria_areas_ibge, cd_mun_2006 cod_mun, area/10000 area
FROM lt_model.result2 AS a
JOIN data.censo_categoria_areas_ibge AS b ON a.area/10000 >= b.limiar_inferior AND a.area/10000 < b.limiar_superior
WHERE a.ownership_class = 'PL';

CREATE INDEX ix_malha ON malha_municipio USING BTREE (gid);

DROP TABLE IF EXISTS malha_municipio2;
CREATE TEMP TABLE malha_municipio2 AS
SELECT cod_mun, fk_censo_categoria_areas_ibge, COUNT(*) contagem, SUM(area)/10000 area FROM malha_municipio a
GROUP BY cod_mun, fk_censo_categoria_areas_ibge;

-- DROP TABLE IF EXISTS num_imoveis_municipio_simular;
-- CREATE TEMP TABLE num_imoveis_municipio_simular AS
-- SELECT a.fk_municipio_ibge, a.fk_censo_categoria_areas_ibge, quantidade - CASE WHEN b.contagem IS NULL THEN 0 ELSE b.contagem END a_simular 
-- FROM lt_model.num_propriedades_necessario a
-- LEFT JOIN malha_municipio2 b ON b.cod_mun = a.fk_municipio_ibge AND b.fk_censo_categoria_areas_ibge = a.fk_censo_categoria_areas_ibge
-- ORDER BY a.fk_municipio_ibge, a.fk_censo_categoria_areas_ibge;


-- Passo 1
DROP TABLE IF EXISTS lt_model.proc3_07_censo_percentual_categoria;
CREATE TABLE lt_model.proc3_07_censo_percentual_categoria AS
SELECT fk_municipio_ibge, fk_censo_categoria_areas_ibge, CASE WHEN num_imoveis IS NULL THEN 0::numeric ELSE num_imoveis::numeric END / (SUM(num_imoveis) OVER (PARTITION BY fk_municipio_ibge)) percentual 
FROM data.censo_areaimovel_ibge;

-- Passo 2
DROP TABLE IF EXISTS lt_model.proc3_08_propriedades_area;
CREATE TABLE lt_model.proc3_08_propriedades_area AS
SELECT cod_mun, SUM(contagem) contagem, SUM(contagem)::NUMERIC/SUM(area) densidade_imoveis
FROM malha_municipio2
GROUP BY cod_mun;

-- Passo 3
DROP TABLE IF EXISTS lt_model.proc3_09_area_simulate;
CREATE TABLE lt_model.proc3_09_area_simulate AS
SELECT cd_mun, SUM(ST_Area(geom))/10000 area 
FROM lt_model.proc3_04_simulate_single
GROUP BY cd_mun;

DROP TABLE IF EXISTS lt_model.proc3_10_num_prop_estimada;
CREATE TABLE lt_model.proc3_10_num_prop_estimada AS
SELECT cd_mun, a.area * densidade_imoveis num_prop_estimada
FROM lt_model.proc3_09_area_simulate a
JOIN lt_model.proc3_08_propriedades_area b ON a.cd_mun = b.cod_mun;

-- Passo 4
DROP TABLE IF EXISTS lt_model.proc3_11_num_propriedades_necessario;
CREATE TABLE lt_model.proc3_11_num_propriedades_necessario AS
SELECT a.fk_municipio_ibge, a.fk_censo_categoria_areas_ibge, ROUND(a.percentual * (b.num_prop_estimada + c.contagem)) quantidade
FROM lt_model.proc3_07_censo_percentual_categoria a
JOIN lt_model.proc3_10_num_prop_estimada b ON a.fk_municipio_ibge = b.cd_mun
JOIN lt_model.proc3_08_propriedades_area c ON c.cod_mun = a.fk_municipio_ibge
ORDER BY a.fk_municipio_ibge, a.fk_censo_categoria_areas_ibge;


DROP TABLE IF EXISTS lt_model.proc3_12_properties_to_simulate;
CREATE TEMP TABLE lt_model.proc3_12_properties_to_simulate AS
SELECT fk_municipio_ibge, b.fk_censo_categoria_areas_ibge, COUNT(a.*) contagem, SUM(a.area/10000) area_exist, a_simular
FROM lt_model.proc3_04_simulate_single a
JOIN num_imoveis_municipio_simular b ON a.cd_mun = b.fk_municipio_ibge
JOIN data.censo_categoria_areas_ibge c ON b.fk_censo_categoria_ar	eas_ibge = c.id AND (a.area/10000) >= c.limiar_inferior AND (a.area/10000) < c.limiar_superior
GROUP BY fk_municipio_ibge, b.fk_censo_categoria_areas_ibge, a_simular
ORDER BY fk_municipio_ibge, b.fk_censo_categoria_areas_ibge;





