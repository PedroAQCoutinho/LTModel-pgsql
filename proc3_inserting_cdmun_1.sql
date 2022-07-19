\copy (SELECT param_text FROM recorte.params WHERE param_name = 'mun_table_name') TO 'var4.txt' CSV header;

DROP TABLE IF EXISTS recorte.result_cdmun;
CREATE TABLE IF NOT EXISTS recorte.result_cdmun (
 	gid INTEGER,
  cd_mun_contain BOOLEAN,
	cd_mun INTEGER);