SET search_path TO lt_model, data, public;

--Imoveis a simular
DROP TABLE IF EXISTS malha_municipio;
CREATE TEMP TABLE malha_municipio AS
SELECT a.id, b.id fk_censo_categoria_areas_ibge, m.codmun7 cod_mun, CASE WHEN COUNT(m.coduf) = 1 THEN a.area ELSE ST_Area(ST_Intersection(a.geom, m.geom))/10000 END area
FROM lt_model.result AS a
JOIN censo_categoria_areas_ibge AS b ON a.area/10000 >= b.limiar_inferior AND a.area/10000 < b.limiar_superior
JOIN public.pa_br_limitemunicipal_2006_ibge m ON ST_Intersects(a.geom, m.geom) AND NOT ST_Touches(a.geom, m.geom)
WHERE a.ownership_class = 'PR' AND m.coduf = 35 AND m.codmun7 = 3538709
GROUP BY a.id, b.id, m.codmun7, a.area, a.geom, m.geom;

CREATE INDEX ix_malha ON malha_municipio USING BTREE (id);

DROP TABLE IF EXISTS malha_municipio2;
CREATE TEMP TABLE malha_municipio2 AS
SELECT cod_mun, fk_censo_categoria_areas_ibge, COUNT(*) contagem, SUM(area) area FROM malha_municipio a
GROUP BY cod_mun, fk_censo_categoria_areas_ibge;

DROP TABLE IF EXISTS num_imoveis_municipio_simular;
CREATE TEMP TABLE num_imoveis_municipio_simular AS
SELECT a.fk_municipio_ibge, a.fk_censo_categoria_areas_ibge, quantidade - CASE WHEN b.contagem IS NULL THEN 0 ELSE b.contagem END a_simular 
FROM lt_model.num_propriedades_necessario a
LEFT JOIN malha_municipio2 b ON b.cod_mun = a.fk_municipio_ibge AND b.fk_censo_categoria_areas_ibge = a.fk_censo_categoria_areas_ibge
WHERE fk_municipio_ibge = 3548054
ORDER BY a.fk_municipio_ibge, a.fk_censo_categoria_areas_ibge;





--CASO municipio 3548054
-- Classes do censo
SELECT *, CASE WHEN limiar_inferior = 2500 THEN 5000 ELSE (limiar_superior+limiar_inferior)/2 END area_central FROM data.censo_categoria_areas_ibge ;

-- Propriedades conhecidas
DROP TABLE IF EXISTS prop_conhecidas;
CREATE TEMP TABLE prop_conhecidas AS
SELECT b.nom_categoria, contagem, area FROM data.censo_categoria_areas_ibge b
LEFT JOIN malha_municipio2 a ON b.id = a.fk_censo_categoria_Areas_ibge
ORDER BY b.id;

-- Percentuais do censo
DROP TABLE IF EXISTS percentuais_censo;
CREATE TEMP TABLE percentuais_censo AS
SELECT b.nom_categoria, num_imoveis, area_ha, num_imoveis::numeric/SUM(num_imoveis) OVER (PARTITION BY fk_municipio_ibge) percentual FROM data.censo_categoria_areas_ibge b
JOIN data.censo_areaimovel_ibge a ON a.fk_censo_categoria_areas_ibge = b.id
WHERE fk_municipio_ibge = 3538709;


-- Área a simular
DROP TABLE IF EXISTS area_simular;
CREATE TEMP TABLE area_simular AS
SELECT cd_mun, SUM(ST_Area(geom))/10000 area 
FROM to_simulate
WHERE cd_mun = 3538709
GROUP BY cd_mun;


-- Tabela agregada de dados
DROP TABLE IF EXISTS todos_dados;
CREATE TEMP TABLE todos_dados AS
SELECT *, ai*ni ai_ni, ai*pi ai_pi
FROM (
SELECT b.nom_categoria, b.area_ha/b.num_imoveis ai, a.contagem ni, b.percentual pi
FROM prop_conhecidas a 
JOIN percentuais_censo b ON a.nom_categoria = b.nom_categoria
JOIN data.censo_categoria_areas_ibge c ON c.nom_categoria = b.nom_categoria) A;


-- Tabela somatorios
DROP TABLE IF EXISTS somatorios;
CREATE TEMP TABLE somatorios AS
SELECT SUM(ai_ni) soma_ai_ni, SUM(ai_pi) soma_ai_pi, SUM(ni) soma_ni
FROM todos_dados;

-- Total a simular
DROP TABLE IF EXISTS a_simular;
CREATE TEMP TABLE a_simular AS
SELECT ((s.area + soma_ai_ni)/soma_ai_pi) - soma_ni n FROM somatorios a, area_simular s;

DROP TABLE IF EXISTS tudo_junto;
CREATE TEMP TABLE tudo_junto AS
SELECT todos_dados.*, (soma_ni+sim.n)*pi - ni si FROM todos_dados, somatorios sum, a_simular sim;


DROP TABLE IF EXISTS a_limpar_area_simulada;
CREATE TEMP TABLE a_limpar_area_simulada AS
SELECT cd_mun, geom
FROM to_simulate
WHERE cd_mun = 3538709;


SELECT lt_model.limpa_area_simulada();


ALTER TABLE limpa_area_simulada_result
RENAME TO to_simulate_single;

DELETE FROM to_simulate_single WHERE area_ha < 1;


ALTER TABLE to_simulate_single
		ADD COLUMN rnd double precision DEFAULT random();
		

DROP TABLE IF EXISTS to_simulate_distribuicao;
CREATE TEMP TABLE to_simulate_distribuicao AS
SELECT CASE WHEN b.id <= 8 THEN 'De 0 a menos de 5 ha' ELSE b.nom_categoria END nom_categoria2, COUNT(a.*) soma
FROM data.censo_categoria_areas_ibge b
LEFT JOIN to_simulate_single a ON a.area_ha >= b.limiar_inferior AND a.area_ha < b.limiar_superior
GROUP BY CASE WHEN b.id <= 8 THEN 1 ELSE b.id END, nom_categoria2
ORDER BY CASE WHEN b.id <= 8 THEN 1 ELSE b.id END;


-- Agrupar as primeiras classes
DROP TABLE IF EXISTS tudo_final;
CREATE TEMP TABLE tudo_final AS
SELECT 
	CASE WHEN rid <= 8 THEN 1 ELSE rid - 7 END rid2,
	CASE WHEN rid <= 8 THEN 'De 0 a menos de 5 ha' ELSE A.nom_categoria END nom_categoria2,
	CASE WHEN rid <= 8 THEN 0 ELSE limiar_inferior END limiar_inferior2,
	CASE WHEN rid <= 8 THEN 5 ELSE limiar_superior END limiar_superior2,
	CASE WHEN rid <= 8 THEN 2.5 ELSE ai END ai2,
	SUM(ni) ni,
	SUM(pi) pi,
	SUM(ai_ni) ai_ni,
	SUM(ai_pi) ai_pi, 
	SUM(si) si
FROM 
(SELECT row_number() OVER () rid, * FROM tudo_junto) A
JOIN data.censo_categoria_areas_ibge B ON A.rid = B.id
GROUP BY rid2, nom_categoria2, ai2, limiar_inferior2, limiar_superior2
ORDER BY rid2;

DROP TABLE IF EXISTS final_simular;
CREATE TEMP TABLE final_simular AS
SELECT a.*, b.soma ja_simulado, (ROUND(si - b.soma)) n_simular
FROM tudo_final a
JOIN to_simulate_distribuicao b ON a.nom_categoria2 = b.nom_categoria2;


SELECT * FROM final_simular
UPDATE final_simular 
SET n_simular = -16
WHERE rid2 = 3;

DROP TABLE IF EXISTS ultimo_necessario;
CREATE TEMP TABLE ultimo_necessario AS
SELECT DISTINCT ON (rid2) a.rid2, a.ai2, a.n_simular, b.limiar_inferior2, b.limiar_superior2, c.gid, c.rnd
FROM (SELECT * FROM final_simular WHERE n_simular > 0 LIMIT 1) a
LEFT JOIN final_simular b ON b.rid2 > a.rid2 AND a.n_simular > 0 AND b.n_simular < 0
LEFT JOIN to_simulate_single c ON c.area_ha >= b.limiar_inferior2 AND c.area_ha < b.limiar_superior2 AND c.area_ha > (1.75 * a.ai2)
LEFT JOIN to_simulate_single d ON d.area_ha >= b.limiar_inferior2 AND d.area_ha < b.limiar_superior2 AND d.rnd <= c.rnd AND d.area_ha > (1.75 * a.ai2)
GROUP BY a.rid2, a.n_simular, a.ai2, b.rid2, b.limiar_inferior2, b.limiar_superior2,b.ai2, c.gid, c.rnd 
HAVING SUM(d.area_ha) BETWEEN (a.ai2*a.n_simular) - (b.ai2/2) AND (a.ai2*a.n_simular) + (b.ai2/2)
ORDER BY a.rid2, b.rid2, c.rnd;

SELECT a.gid, ai2, ROUND(a.area_ha/ai2) n_pontos, area_ha FROM to_simulate_single a
JOIN ultimo_necessario b ON a.area_ha >= b.limiar_inferior2 AND a.area_ha < b.limiar_superior2 AND a.rnd <= b.rnd AND a.area_ha > (1.75 * ai2)


SELECT a.*, fk_categoria
FROM to_simulate_single a

WHERE fk_categoria > 2
ORDER BY fk_categoria, rnd
LIMIT 20;

DO $$
DECLARE pcursor REFCURSOR;
DECLARE var_linha record;
DECLARE rid_atual INT;
BEGIN
OPEN pcursor FOR SELECT * FROM final_simular WHERE n_simular > 0;

	LOOP
		FETCH FROM pcursor INTO var_linha;
		EXIT WHEN NOT FOUND;
		SELECT a.rid2, ROUND(SUM(70/b.ai2)) n_prop,  
		FROM final_simular a
		LEFT JOIN final_simular b ON b.rid2 <= a.rid2
		WHERE a.rid2 > 2 AND a.n_simular < 0 AND b.n_simular < 0 AND b.rid2 > 2
		GROUP BY a.rid2
		HAVING SUM(b.n_simular * b.ai2) < -70
		ORDER BY a.rid2;

		
		SELECT rnd FROM 
		to_simulate_single a
		LIMIT 10
		IF rid_atual IS NOT NULL THEN
		RAISE NOTICE '%', rid_atual;
		END IF;
	END LOOP;
END $$;