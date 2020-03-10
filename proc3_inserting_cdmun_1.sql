\copy (SELECT param_text FROM lt_model.params WHERE param_name = 'mun_table_name') TO 'var4.txt' CSV header;

DROP TABLE IF EXISTS lt_model.result_cdmun;
CREATE TABLE IF NOT EXISTS lt_model.result_cdmun (
 	gid INTEGER,
  cd_mun_contain BOOLEAN,
	cd_mun INTEGER);