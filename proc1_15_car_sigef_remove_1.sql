DROP TABLE IF EXISTS recorte.proc1_14_car_sigef_cleaned;
CREATE TABLE recorte.proc1_14_car_sigef_cleaned AS
SELECT *
FROM recorte.proc1_13_car_sigef WHERE area_loss < (SELECT param_value FROM recorte.params WHERE param_name = 'car_incra_tolerance');


\copy (SELECT param_text FROM recorte.params WHERE param_name = 'car_table_schema') TO 'var1.txt' CSV header;
\copy (SELECT param_text FROM recorte.params WHERE param_name = 'car_table_name') TO 'var2.txt' CSV header;
\copy (SELECT param_text FROM recorte.params WHERE param_name = 'car_mf_column') TO 'var3.txt' CSV header;
\set car_table_schema `tail -1 var1.txt`
\set car_table_name `tail -1 var2.txt`


ALTER TABLE recorte.proc1_14_car_sigef_cleaned
ADD COLUMN IF NOT EXISTS cod_imovel TEXT;

UPDATE recorte.proc1_14_car_sigef_cleaned a
SET cod_imovel = b.cod_imovel 
FROM :"car_table_schema".:"car_table_name" b
WHERE a.gid = b.gid;

\echo `rm var1.txt`
\echo `rm var2.txt`
\echo `rm var3.txt`

DROP TABLE IF EXISTS recorte.lt_model_car_po;
CREATE TABLE recorte.lt_model_car_po AS
SELECT * FROM recorte.proc1_14_car_sigef_cleaned
WHERE NOT is_premium;

DROP TABLE IF EXISTS recorte.lt_model_car_pr;
CREATE TABLE recorte.lt_model_car_pr AS
SELECT * FROM recorte.proc1_14_car_sigef_cleaned
WHERE is_premium;