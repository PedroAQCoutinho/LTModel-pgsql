DROP TABLE IF EXISTS proc3_05_1_malha_municipio;
CREATE TEMP TABLE proc3_05_1_malha_municipio AS
SELECT a.gid, b.id fk_censo_categoria_areas_ibge, cd_mun_2006 cod_mun, area/10000 area
FROM lt_model.result2 AS a
JOIN data.censo_categoria_areas_ibge AS b ON a.area/10000 >= b.limiar_inferior AND a.area/10000 < b.limiar_superior
WHERE a.ownership_class = 'PL';

CREATE INDEX ix_malha ON proc3_05_1_malha_municipio USING BTREE (gid);


DROP TABLE IF EXISTS proc3_05_2_malha_municipio2;
CREATE TEMP TABLE proc3_05_2_malha_municipio2 AS
SELECT cod_mun, fk_censo_categoria_areas_ibge, COUNT(*) contagem, SUM(area) area 
FROM proc3_05_1_malha_municipio a
GROUP BY cod_mun, fk_censo_categoria_areas_ibge;

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
FROM lt_model.proc3_04_simulate_single a
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