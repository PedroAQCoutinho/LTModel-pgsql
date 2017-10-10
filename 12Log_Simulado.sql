
DROP TABLE IF EXISTS lt_model.proc3_22_censo_modulos;
CREATE TABLE lt_model.proc3_22_censo_modulos AS
SELECT fk_estado_ibge cod_estado, b.cat_tamanho, SUM(num_imoveis) num_imoveis
FROM data.censo_modulo_imoveis_ibge a
JOIN data.censo_categoria_modulos_ibge b ON a.fk_censo_categoria_modulos_ibge = b.id 
JOIN data.municipio_ibge c ON c.cod_ibge = a.fk_municipio_ibge
GROUP BY c.fk_estado_ibge, cat_tamanho;


DROP TABLE IF EXISTS lt_model.proc3_23_conhecido_tamanho;
CREATE TABLE lt_model.proc3_23_conhecido_tamanho AS
SELECT m.fk_estado_ibge cod_estado, b.cat_tamanho, COUNT(*) num_imoveis
FROM lt_model.result3 a 
JOIN data.v_censo_modulo_tamanhos b ON a.area/10000 >= b.limiar_inferior AND a.area/10000 < b.limiar_superior AND a.cd_mun = b.fk_municipio_ibge
JOIN data.municipio_ibge m  ON a.cd_mun = m.cod_ibge
WHERE a.ownership_class = 'PL'
GROUP BY m.fk_estado_ibge, b.cat_tamanho;

DROP TABLE IF EXISTS lt_model.proc3_24_simulado_tamanho;
CREATE TABLE lt_model.proc3_24_simulado_tamanho AS
SELECT m.fk_estado_ibge cod_estado, c.cat_tamanho, COUNT(*) num_imoveis
FROM lt_model.proc3_20_voronoifinal a
JOIN data.v_censo_modulo_tamanhos c ON ST_Area(a.geom)/10000 >= c.limiar_inferior AND ST_Area(a.geom)/10000 < c.limiar_superior AND a.cd_mun = c.fk_municipio_ibge
JOIN data.municipio_ibge m ON m.cod_ibge = a.cd_mun
GROUP BY m.fk_estado_ibge, c.cat_tamanho;


DROP TABLE IF EXISTS lt_model.proc3_25_result_tamanho;
CREATE TABLE lt_model.proc3_25_result_tamanho AS
SELECT CASE WHEN a.cod_estado IS NULL THEN b.cod_estado ELSE a.cod_estado END cod_estado,
	CASE WHEN a.cat_tamanho IS NULL THEN b.cat_tamanho ELSE a.cat_tamanho END cat_tamanho,
	CASE WHEN a.num_imoveis IS NULL THEN b.num_imoveis 
		WHEN b.num_imoveis IS NULL THEN a.num_imoveis ELSE a.num_imoveis+b.num_imoveis END num_imoveis
FROM lt_model.proc3_23_conhecido_tamanho a 
FULL JOIN lt_model.proc3_24_simulado_tamanho b ON a.cod_estado = b.cod_estado AND a.cat_tamanho = b.cat_tamanho;


DROP TABLE IF EXISTS lt_model.proc3_26_state_agg;
CREATE TABLE lt_model.proc3_26_state_agg AS
SELECT c.cod_ibge cod_estado, CASE WHEN b.cat_tamanho IS NULL THEN d.cat_tamanho ELSE b.cat_tamanho END cat_tamanho2, 
	SUM(e.num_imoveis) n_imoveis_conhecido, 
	SUM(d.num_imoveis) n_imoveis_simulado, 
	SUM(b.num_imoveis) n_imoveis_censo
FROM data.estado_ibge c
LEFT JOIN lt_model.proc3_22_censo_modulos b ON b.cod_estado = c.cod_ibge
LEFT JOIN lt_model.proc3_24_simulado_tamanho d ON d.cod_estado = c.cod_ibge AND b.cat_tamanho = d.cat_tamanho
LEFT JOIN lt_model.proc3_23_conhecido_tamanho e ON e.cod_estado = c.cod_ibge AND b.cat_tamanho = e.cat_tamanho
WHERE b.cod_estado = 35
GROUP BY c.cod_ibge, cat_tamanho2;

DROP TABLE IF EXISTS lt_model.proc3_27_perc_final;
CREATE TABLE lt_model.proc3_27_perc_final AS
SELECT cod_estado, cat_tamanho2 cat_tamanho, 
	n_imoveis_conhecido, 
	n_imoveis_simulado, 
	n_imoveis_censo,
	100*(n_imoveis_conhecido+n_imoveis_simulado)/(SUM(n_imoveis_conhecido+n_imoveis_simulado) OVER (PARTITION BY cod_estado)) perc_resultado,
	100*n_imoveis_censo/(SUM(n_imoveis_censo) OVER (PARTITION BY cod_estado)) perc_censo
FROM lt_model.proc3_26_state_agg c;



DELETE FROM lt_model.log_simulate
WHERE num_run = (SELECT MAX(num_run) FROM lt_model.log_outputs);

INSERT INTO lt_model.log_simulate(
            num_run, cod_state, size, num_census, num_known, num_simulated, 
            perc_census, perc_modeled)
SELECT (SELECT MAX(num_run) FROM lt_model.log_outputs) num_run,
cod_estado cod_state,
cat_tamanho size,
n_imoveis_censo,
n_imoveis_conhecido,
n_imoveis_simulado,
perc_censo,
perc_resultado
 FROM lt_model.proc3_27_perc_final;