SET search_path TO lt_model, data, public;

ALTER TABLE recorte.result
ADD COLUMN IF NOT EXISTS cd_mun_2006 INT;

ALTER TABLE recorte.result
ADD COLUMN IF NOT EXISTS gid serial;



CREATE INDEX IF NOT EXISTS gix_result ON recorte.result USING GIST(geom);
CREATE INDEX IF NOT EXISTS ix_result ON recorte.result USING BTREE (gid);
CREATE INDEX IF NOT EXISTS pa_br_limitemunicipal_2006_ibge ON pa_br_limitemunicipal_2006_ibge USING BTREE ((codmun7 % 15));


-- UPDATE recorte.result a 
-- SET cd_mun_2006 = b.codmun7 
-- FROM pa_br_limitemunicipal_2006_ibge b JOIN data.municipio_ibge c ON b.codmun7 = c.cod_ibge AND c.fk_estado_ibge = 35 
-- WHERE ST_Within(a.geom, b.geom) AND (b.codmun7 % 15) = {num};


-- $sql = 'UPDATE recorte.result a SET cd_mun_2006 = b.codmun7 FROM pa_br_limitemunicipal_2006_ibge b JOIN data.municipio_ibge c ON b.codmun7 = c.cod_ibge AND c.fk_estado_ibge = 35 WHERE ST_Within(a.geom, b.geom) AND (b.codmun7 % 15) = {num};'
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}

DROP TABLE IF EXISTS recorte.proc2_00_lo_mun;
CREATE TABLE recorte.proc2_00_lo_mun 
(
gid INT,
codmun7 INT
);


-- INSERT INTO recorte.proc2_00_lo_mun 
-- SELECT a.gid, b.codmun7 
-- FROM recorte.result a 
--     JOIN pa_br_limitemunicipal_2006_ibge b ON ST_Intersects(a.geom, b.geom) 
-- WHERE a.cd_mun_2006 IS NULL AND b.coduf = 35 AND (b.codmun7 % 15) = {num};


-- Powershell
-- $sql = 'INSERT INTO recorte.proc2_00_lo_mun SELECT a.gid, b.codmun7 FROM  recorte.result a JOIN pa_br_limitemunicipal_2006_ibge b ON ST_Intersects(a.geom, b.geom) WHERE a.cd_mun_2006 IS NULL AND b.coduf = 35 AND (b.codmun7 % 15) = {num};'
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}


DROP TABLE IF EXISTS recorte.proc3_01_mun2;
CREATE TABLE recorte.proc3_01_mun2 (
gid INT, 
codmun7 INT,
area DOUBLE PRECISION
);

-- INSERT INTO recorte.proc3_01_mun2 
-- SELECT a.gid, a.codmun7, ST_Area(ST_Intersection(b.geom, c.geom)) area 
-- FROM recorte.proc2_00_lo_mun a 
-- JOIN public.pa_br_limitemunicipal_2006_ibge b ON a.codmun7 = b.codmun7 JOIN recorte.result c ON c.cd_mun_2006 IS NULL AND a.gid = c.gid 
-- WHERE (b.codmun7 % 15) = {num};


-- $sql = 'INSERT INTO recorte.proc3_01_mun2 SELECT a.gid, a.codmun7, ST_Area(ST_Intersection(b.geom, c.geom)) area FROM recorte.proc2_00_lo_mun a JOIN public.pa_br_limitemunicipal_2006_ibge b ON a.codmun7 = b.codmun7 JOIN recorte.result c ON c.cd_mun_2006 IS NULL AND a.gid = c.gid WHERE (b.codmun7 % 15) = {num};'
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}


DROP TABLE IF EXISTS recorte.proc3_02_mun3;
CREATE TABLE recorte.proc3_02_mun3 AS
SELECT DISTINCT ON (gid) gid, codmun7 
FROM recorte.proc3_01_mun2
ORDER BY gid, area DESC;


UPDATE recorte.result a
SET cd_mun_2006 = b.codmun7
FROM recorte.proc3_02_mun3 b
WHERE a.gid = b.gid;

VACUUM ANALYZE recorte.result;

DROP TABLE IF EXISTS recorte.result2;
CREATE TABLE recorte.result2 AS
SELECT gid, table_source, ownership_class, sub_class, area_original, 
       original_gid, ST_Multi(ST_CollectionExtract(ST_MakeValid(geom), 3))::geometry('MultiPolygon', 97823) geom, area, ag_area_loss, aru_area_loss, carpo_area_loss, 
       carpr_area_loss, com_area_loss, ml_area_loss, nd_area_loss, ql_area_loss, 
       sigef_area_loss, ti_area_loss, tlpc_area_loss, tlpl_area_loss, 
       trans_area_loss, ucpi_area_loss, ucus_area_loss, urb_area_loss, 
       cd_mun_2006
  FROM recorte.result
  WHERE cd_mun_2006 IS NOT NULL;



DROP TABLE IF EXISTS recorte.proc3_03_simulate;
CREATE TABLE recorte.proc3_03_simulate (
cd_mun INT,
geom geometry
);


CREATE INDEX ix_lt_model_result2 ON recorte.result2 USING GIST (geom);

-- INSERT INTO recorte.proc3_03_simulate 
-- SELECT a.codmun7 cd_mun, ST_Difference(a.geom, ST_Buffer(ST_CollectionExtract(ST_MakeValid(ST_Collect(b.geom)), 3), 0.01)) geom 
-- FROM pa_br_limitemunicipal_2006_ibge a 
-- LEFT JOIN recorte.result2 b ON ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom) 
-- WHERE (a.codmun7 % 15) = {num} 
-- GROUP BY a.codmun7, a.geom;


-- $sql = 'INSERT INTO recorte.proc3_03_simulate SELECT a.codmun7 cd_mun, ST_Difference(a.geom, ST_Buffer(ST_CollectionExtract(ST_MakeValid(ST_Collect(b.geom)), 3), 0.01)) geom FROM pa_br_limitemunicipal_2006_ibge a LEFT JOIN recorte.result2 b ON ST_Intersects(a.geom, b.geom) AND NOT ST_Touches(a.geom, b.geom) WHERE (a.codmun7 % 15) = {num} GROUP BY a.codmun7, a.geom;';
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}


DROP TABLE IF EXISTS recorte.proc3_04_simulate_single;
CREATE TABLE recorte.proc3_04_simulate_single (
gid SERIAL PRIMARY KEY,
cd_mun INT,
geom geometry
);

-- Powershell
-- $sql = 'INSERT INTO recorte.proc3_04_simulate_single(cd_mun, geom) SELECT cd_mun, (ST_Dump(geom)).geom FROM recorte.proc3_03_simulate WHERE (cd_mun % 15) = {num};'
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}


--Imoveis a simular
DROP TABLE IF EXISTS proc3_05_1_malha_municipio;
CREATE TEMP TABLE proc3_05_1_malha_municipio AS
SELECT a.gid, b.id fk_censo_categoria_areas_ibge, cd_mun_2006 cod_mun, area/10000 area
FROM recorte.result2 AS a
JOIN data.censo_categoria_areas_ibge AS b ON a.area/10000 >= b.limiar_inferior AND a.area/10000 < b.limiar_superior
WHERE a.ownership_class = 'PL';

CREATE INDEX ix_malha ON proc3_05_1_malha_municipio USING BTREE (gid);


DROP TABLE IF EXISTS proc3_05_2_malha_municipio2;
CREATE TEMP TABLE proc3_05_2_malha_municipio2 AS
SELECT cod_mun, fk_censo_categoria_areas_ibge, COUNT(*) contagem, SUM(area) area 
FROM proc3_05_1_malha_municipio a
GROUP BY cod_mun, fk_censo_categoria_areas_ibge;




--CASO municipio 3548054
-- Classes do censo
SELECT *, CASE WHEN limiar_inferior = 2500 THEN 5000 ELSE (limiar_superior+limiar_inferior)/2 END area_central FROM data.censo_categoria_areas_ibge ;

-- Propriedades conhecidas
DROP TABLE IF EXISTS proc3_05_prop_conhecidas;
CREATE TABLE proc3_05_prop_conhecidas AS
SELECT cod_mun, b.nom_categoria, contagem, area 
FROM data.censo_categoria_areas_ibge b
LEFT JOIN proc3_05_2_malha_municipio2 a ON b.id = a.fk_censo_categoria_Areas_ibge
ORDER BY b.id;

-- Percentuais do censo
DROP TABLE IF EXISTS proc3_06_percentuais_censo;
CREATE TABLE proc3_06_percentuais_censo AS
SELECT fk_municipio_ibge cd_mun, b.nom_categoria, num_imoveis, area_ha, num_imoveis::numeric/SUM(num_imoveis) OVER (PARTITION BY fk_municipio_ibge) percentual 
FROM data.censo_categoria_areas_ibge b
JOIN data.censo_areaimovel_ibge a ON a.fk_censo_categoria_areas_ibge = b.id;


-- Área a simular
DROP TABLE IF EXISTS proc3_07_area_simular;
CREATE TABLE proc3_07_area_simular AS
SELECT cd_mun, SUM(ST_Area(geom))/10000 area 
FROM recorte.proc3_04_simulate_single a
JOIN data.municipio_ibge b ON a.cd_mun = b.cod_ibge
GROUP BY cd_mun;


-- Tabela agregada de dados
DROP TABLE IF EXISTS proc3_08_todos_dados;
CREATE TABLE proc3_08_todos_dados AS
SELECT *, ai*ni ai_ni, ai*pi ai_pi
FROM (
SELECT b.cd_mun, b.nom_categoria, b.area_ha/b.num_imoveis ai, a.contagem ni, b.percentual pi
FROM proc3_05_prop_conhecidas a 
JOIN proc3_06_percentuais_censo b ON a.nom_categoria = b.nom_categoria AND a.cod_mun = b.cd_mun
JOIN data.censo_categoria_areas_ibge c ON c.nom_categoria = b.nom_categoria) A;

-- Tabela somatorios
DROP TABLE IF EXISTS proc3_09_somatorios;
CREATE TABLE proc3_09_somatorios AS
SELECT cd_mun, SUM(ai_ni) soma_ai_ni, SUM(ai_pi) soma_ai_pi, SUM(ni) soma_ni
FROM proc3_08_todos_dados
GROUP BY cd_mun;

-- Total a simular
DROP TABLE IF EXISTS proc3_10_a_simular;
CREATE TABLE proc3_10_a_simular AS
SELECT a.cd_mun, ((s.area + soma_ai_ni)/soma_ai_pi) - soma_ni n FROM proc3_09_somatorios a
JOIN proc3_07_area_simular s ON a.cd_mun = s.cd_mun;

DROP TABLE IF EXISTS proc3_11_tudo_junto;
CREATE TABLE proc3_11_tudo_junto AS
SELECT a.*, (soma_ni+sim.n)*pi - ni si FROM proc3_08_todos_dados a
JOIN proc3_09_somatorios sum ON a.cd_mun = sum.cd_mun
JOIN proc3_10_a_simular sim ON a.cd_mun = sim.cd_mun;


DROP TABLE IF EXISTS proc3_12_a_limpar_area_simulada;
CREATE TABLE proc3_12_a_limpar_area_simulada AS
SELECT cd_mun, geom
FROM proc3_04_simulate_single;

DROP TABLE IF EXISTS proc3_13_limpa_area_simulada_result;
CREATE TABLE proc3_13_limpa_area_simulada_result (
cd_mun INT,
geom geometry,
gid INT,
area_ha INT,
rnd DOUBLE PRECISION DEFAULT random()
);

-- ALTER TABLE recorte.proc3_13_limpa_area_simulada_result
-- ADD COLUMN rnd DOUBLE PRECISION DEFAULT random();

SELECT recorte.clean_simulate_area(15, 0);

-- powershell 
-- $sql = 'SELECT recorte.clean_simulate_area(15, {num});'
-- 0..14 | % {start-process cmd "/k `"echo $($_) & psql -U postgres -h geonode -d atlas -c ""$($sql -Replace '{num}', $_)`""}

DROP TABLE IF EXISTS proc3_14_area_simulada_sem_1ha;
CREATE TABLE proc3_14_area_simulada_sem_1ha AS
SELECT *
FROM proc3_13_limpa_area_simulada_result
WHERE area_ha > 1 AND (2*SQRT(PI()*area_ha*10000))/ST_Perimeter(geom) > 0.12;


DROP TABLE IF EXISTS recorte.proc3_15_to_simulate_distribuicao;
CREATE TABLE recorte.proc3_15_to_simulate_distribuicao AS
SELECT cd_mun, CASE WHEN b.id <= 8 THEN 'De 0 a menos de 5 ha' ELSE b.nom_categoria END nom_categoria2, COUNT(a.*) soma
FROM data.censo_categoria_areas_ibge b
LEFT JOIN recorte.proc3_14_area_simulada_sem_1ha a ON a.area_ha >= b.limiar_inferior AND a.area_ha < b.limiar_superior
GROUP BY CASE WHEN b.id <= 8 THEN 1 ELSE b.id END, nom_categoria2, cd_mun
ORDER BY CASE WHEN b.id <= 8 THEN 1 ELSE b.id END;

-- Agrupar as primeiras classes
DROP TABLE IF EXISTS recorte.proc3_16_tudo_final;
CREATE TABLE recorte.proc3_16_tudo_final AS
SELECT 
	cd_mun,
	CASE WHEN B.id <= 8 THEN 1 ELSE B.id - 7 END rid2,
	CASE WHEN B.id <= 8 THEN 'De 0 a menos de 5 ha' ELSE A.nom_categoria END nom_categoria2,
	CASE WHEN B.id <= 8 THEN 0 ELSE limiar_inferior END limiar_inferior2,
	CASE WHEN B.id <= 8 THEN 5 ELSE limiar_superior END limiar_superior2,
	CASE WHEN B.id <= 8 THEN 2.5 ELSE ai END ai2,
	SUM(ni) ni,
	SUM(pi) pi,
	SUM(ai_ni) ai_ni,
	SUM(ai_pi) ai_pi, 
	SUM(si) si
FROM 
recorte.proc3_11_tudo_junto A
JOIN data.censo_categoria_areas_ibge B ON A.nom_categoria = B.nom_categoria
GROUP BY cd_mun, rid2, nom_categoria2, ai2, limiar_inferior2, limiar_superior2
ORDER BY rid2;

DROP TABLE IF EXISTS recorte.proc3_17_final_simular;
CREATE TABLE recorte.proc3_17_final_simular AS
SELECT a.*, b.soma ja_simulado, (ROUND(si - b.soma)) n_simular
FROM recorte.proc3_16_tudo_final a
JOIN recorte.proc3_15_to_simulate_distribuicao b ON a.cd_mun = b.cd_mun AND a.nom_categoria2 = b.nom_categoria2;


DROP TABLE IF EXISTS recorte.proc3_18_ultimo_necessario;
CREATE TABLE recorte.proc3_18_ultimo_necessario AS
SELECT DISTINCT ON (a.cd_mun, rid2) a.cd_mun, a.rid2, a.ai2, a.n_simular, b.limiar_inferior2, b.limiar_superior2, c.gid, c.rnd
FROM (SELECT DISTINCT ON (cd_mun) * FROM recorte.proc3_17_final_simular WHERE n_simular > 0 ORDER BY cd_mun, rid2) a
LEFT JOIN recorte.proc3_17_final_simular b ON b.rid2 > a.rid2 AND a.n_simular > 0 AND b.n_simular < 0 AND a.cd_mun = b.cd_mun
LEFT JOIN recorte.proc3_14_area_simulada_sem_1ha c ON c.area_ha >= b.limiar_inferior2 AND c.area_ha < b.limiar_superior2 AND c.area_ha > (1.75 * a.ai2) AND b.cd_mun = c.cd_mun
LEFT JOIN recorte.proc3_14_area_simulada_sem_1ha d ON d.area_ha >= b.limiar_inferior2 AND d.area_ha < b.limiar_superior2 AND d.rnd <= c.rnd AND d.area_ha > (1.75 * a.ai2) AND c.cd_mun = d.cd_mun
GROUP BY a.cd_mun, a.rid2, a.n_simular, a.ai2, b.rid2, b.limiar_inferior2, b.limiar_superior2,b.ai2, c.gid, c.rnd 
HAVING SUM(d.area_ha) BETWEEN (a.ai2*a.n_simular) - (b.ai2/2) AND (a.ai2*a.n_simular) + (b.ai2/2)
ORDER BY a.cd_mun, a.rid2, b.rid2, c.rnd;

CREATE TABLE recorte.proc3_19_npontos AS
SELECT a.cd_mun, a.gid, ai2, ROUND(a.area_ha/ai2) n_pontos, area_ha FROM proc3_14_area_simulada_sem_1ha a
JOIN proc3_18_ultimo_necessario b ON a.cd_mun = b.cd_mun AND a.area_ha >= b.limiar_inferior2 AND a.area_ha < b.limiar_superior2 AND a.rnd <= b.rnd AND a.area_ha > (1.75 * ai2);

DROP TABLE IF EXISTS recorte.proc3_20_voronoifinal;
CREATE TABLE recorte.proc3_20_voronoifinal AS
SELECT cd_mun, row_number() OVER () as gid, geom, ST_Area(geom)::numeric(30,4) area
FROM (
SELECT b.cd_mun, b.gid, CASE WHEN a.gid IS NULL THEN b.geom ELSE ST_CollectionExtract(ST_Intersection((ST_Dump(ST_CollectionExtract(ST_VoronoiPolygons(ST_GeneratePoints(geom, n_pontos), 0, geom), 3))).geom, geom), 3) END geom
FROM recorte.proc3_19_npontos a
RIGHT JOIN recorte.proc3_14_area_simulada_sem_1ha b ON a.cd_mun = b.cd_mun AND a.gid = b.gid) a;


INSERT INTO recorte.result2 (gid, ownership_class, sub_class, area, area_original, geom)
SELECT gid + (SELECT MAX(gid) FROM recorte.result3), 'PL', 'SI', area, area, ST_Multi(ST_Force2D(geom)) FROM proc3_20_voronoifinal;