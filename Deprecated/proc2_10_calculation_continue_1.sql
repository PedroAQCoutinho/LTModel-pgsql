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
