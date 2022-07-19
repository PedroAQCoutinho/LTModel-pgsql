CREATE TABLE projetos.a2017_tematico_01_num_conhecido (
categoria TEXT,
n_imoveis INT,
area_ha INT
);

-- CAR declarado
INSERT INTO projetos.a2017_tematico_01_num_conhecido
SELECT 'CAR Declarado', COUNT(*)::integer, ROUND(SUM(ST_Area(geom))/10000)::integer 
FROM public.es_sp_car_merge_050517_albers;

-- CAR processado premium
INSERT INTO projetos.a2017_tematico_01_num_conhecido
SELECT 'CAR Premium', COUNT(*)::integer, ROUND(SUM(area)/10000)::integer 
FROM recorte.result 
WHERE sub_class = 'CARpr';

-- CAR processado linha
INSERT INTO projetos.a2017_tematico_01_num_conhecido
SELECT 'CAR Linha', COUNT(*)::integer, ROUND(SUM(area)/10000)::integer 
FROM recorte.result 
WHERE sub_class = 'CARpo';


-- SIGEF declarado acervo
INSERT INTO projetos.a2017_tematico_01_num_conhecido
SELECT 'SIGEF Acervo', COUNT(*)::integer, ROUND(SUM(ST_Area(geom))/10000)::integer 
FROM public.pa_br_acervofundiario_basefundiaria_privado_2016_incra a
WHERE cod_uf14 = '35';


-- SIGEF declarado 2001
INSERT INTO projetos.a2017_tematico_01_num_conhecido
SELECT 'SIGEF 2001', COUNT(*)::integer, ROUND(SUM(ST_Area(CASE WHEN ST_WIthin(a.geom, b.geom) THEN a.geom ELSE ST_Intersection(a.geom, b.geom) END))/10000)::integer 
FROM data.municipio_ibge c
JOIN public.pa_br_municipios_250_2015_ibge_albers b ON c.cod_ibge = b.cd_mun AND fk_estado_ibge = 35
JOIN public.pa_br_acervofundiario_certimoveisruraislei10267_2001_privado_in a ON ST_Intersects(a.geom, b.geom);


-- CAR processado linha
INSERT INTO projetos.a2017_tematico_01_num_conhecido
SELECT 'SIGEF Processado', COUNT(*)::integer, ROUND(SUM(area)/10000)::integer 
FROM recorte.result2 
WHERE sub_class = 'SIGEF';

SELECT * FROM projetos.a2017_tematico_01_num_conhecido;



SELECT sub_class, MAX(proc_order) proc_order FROM recorte.inputs
GROUP BY sub_class
ORDER BY proc_order;

DROP TABLE projetos.a2017_tematico_02_matriz_sobreposicao_area;
CREATE TABLE projetos.a2017_tematico_02_matriz_sobreposicao_area (
sub_class TEXT,
TRANS INT, 
AG INT, 
ML INT, 
TI INT, 
UCPI INT, 
UCUS INT, 
SIGEF INT, 
ARU INT, 
QL INT, 
CARpr INT, 
CARpo INT, 
ND INT, 
URB INT
);

INSERT INTO projetos.a2017_tematico_02_matriz_sobreposicao_area
SELECT sub_class, 
ROUND(SUM(CASE WHEN TRANS_area_loss IS NULL THEN 0 ELSE TRANS_area_loss END)/10000), 
ROUND(SUM(CASE WHEN AG_area_loss IS NULL THEN 0 ELSE AG_area_loss END)/10000), 
ROUND(SUM(CASE WHEN ML_area_loss IS NULL THEN 0 ELSE ML_area_loss END)/10000), 
ROUND(SUM(CASE WHEN TI_area_loss IS NULL THEN 0 ELSE TI_area_loss END)/10000), 
ROUND(SUM(CASE WHEN UCPI_area_loss IS NULL THEN 0 ELSE UCPI_area_loss END)/10000), 
ROUND(SUM(CASE WHEN UCUS_area_loss IS NULL THEN 0 ELSE UCUS_area_loss END)/10000), 
ROUND(SUM(CASE WHEN SIGEF_area_loss IS NULL THEN 0 ELSE SIGEF_area_loss END)/10000), 
ROUND(SUM(CASE WHEN ARU_area_loss IS NULL THEN 0 ELSE ARU_area_loss END)/10000), 
ROUND(SUM(CASE WHEN QL_area_loss IS NULL THEN 0 ELSE QL_area_loss END)/10000), 
ROUND(SUM(CASE WHEN CARpr_area_loss IS NULL THEN 0 ELSE CARpr_area_loss END)/10000), 
ROUND(SUM(CASE WHEN CARpo_area_loss IS NULL THEN 0 ELSE CARpo_area_loss END)/10000), 
ROUND(SUM(CASE WHEN ND_area_loss IS NULL THEN 0 ELSE ND_area_loss END)/10000), 
ROUND(SUM(CASE WHEN URB_area_loss IS NULL THEN 0 ELSE URB_area_loss END)/10000)
FROM recorte.result
GROUP BY sub_class;



SELECT a.* FROM projetos.a2017_tematico_02_matriz_sobreposicao_area a
JOIN recorte.inputs b ON a.sub_class = b.sub_class
GROUP BY a.sub_class, ag, aru, carpo, carpr, ml, nd, ql, sigef, ti, 
       trans, ucpi, ucus, urb
ORDER BY MAX(b.proc_order);



DROP TABLE projetos.a2017_tematico_02_matriz_sobreposicao_qde;
CREATE TABLE projetos.a2017_tematico_02_matriz_sobreposicao_qde (
sub_class TEXT,
TRANS INT, 
AG INT, 
ML INT, 
TI INT, 
UCPI INT, 
UCUS INT, 
SIGEF INT, 
ARU INT, 
QL INT, 
CARpr INT, 
CARpo INT, 
ND INT, 
URB INT
);

INSERT INTO projetos.a2017_tematico_02_matriz_sobreposicao_qde
SELECT sub_class, 
COUNT(TRANS_area_loss), 
COUNT(AG_area_loss), 
COUNT(ML_area_loss), 
COUNT(TI_area_loss), 
COUNT(UCPI_area_loss), 
COUNT(UCUS_area_loss), 
COUNT(SIGEF_area_loss), 
COUNT(ARU_area_loss), 
COUNT(QL_area_loss), 
COUNT(CARpr_area_loss), 
COUNT(CARpo_area_loss), 
COUNT(ND_area_loss), 
COUNT(URB_area_loss)
FROM recorte.result
GROUP BY sub_class;



SELECT a.* FROM projetos.a2017_tematico_02_matriz_sobreposicao_qde a
JOIN recorte.inputs b ON a.sub_class = b.sub_class
GROUP BY a.sub_class, ag, aru, carpo, carpr, ml, nd, ql, sigef, ti, 
       trans, ucpi, ucus, urb
ORDER BY MAX(b.proc_order);


SELECT ST_Area(ST_Transform(the_geom, 97823))::numeric(30,7)/10000 FROM public.pa_br_limiteestadual_250_2015_ibge WHERE "NM_ESTADO" = 'SP';

DROP TABLE IF EXISTS projetos.a2017_tematico_02_num_area_class;
CREATE TABLE projetos.a2017_tematico_02_num_area_class (
priority INT,
sub_class TEXT,
num_imoveis INT,
area_ha INT
);

CREATE VIEW recorte.sub_class_priority AS
SELECT sub_class, MAX(proc_order) priority
FROM recorte.inputs
GROUP BY sub_class
ORDER BY priority ASC;


INSERT INTO projetos.a2017_tematico_02_num_area_class
SELECT priority, b.sub_class, COUNT(a.gid), ROUND(SUM(CASE WHEN area IS NULL THEN 0 ELSE area END)/10000) 
FROM recorte.sub_class_priority b
LEFT JOIN  recorte.result2 a ON a.sub_class = b.sub_class
GROUP BY priority, b.sub_class;


SELECT * FROM projetos.a2017_tematico_02_num_area_class ORDER BY priority;