\copy (SELECT param_text FROM lt_model.params WHERE param_name = 'mun_table_name') TO 'var4.txt' CSV header;
\copy (SELECT param_text FROM lt_model.params WHERE param_name = 'biome_table_name') TO 'var5.txt' CSV header;
\copy (SELECT param_text FROM lt_model.params WHERE param_name = 'otto_table_name') TO 'var6.txt' CSV header;

--Breaking municipalities by biome
DROP TABLE IF EXISTS lt_model.v_pacotes_proc01_breakbiome; 
CREATE TABLE lt_model.v_pacotes_proc01_breakbiome
(
  cd_mun integer,
  cd_bioma integer,
  geom geometry
);

--Breaking municipalities+biome by ottobacia
DROP TABLE IF EXISTS lt_model.v_pacotes_proc02_ottobacia;
CREATE TABLE lt_model.v_pacotes_proc02_ottobacia
(
  cd_mun bigint,
  cd_bioma integer,
  cd_bacia character varying(14),
  geom geometry
);

--Table with rural properties and unregistred lands
DROP TABLE IF EXISTS lt_model.v_pacotes_proc03_unregistered; 
CREATE TABLE lt_model.v_pacotes_proc03_unregistered
(
  gid integer,
  cd_mun bigint,
  cd_bioma integer,
  cd_bacia character varying(14),
  geom geometry
);

--Table with rural properties breaks
DROP TABLE IF EXISTS lt_model.v_pacotes_proc04_flagprop; 
CREATE TABLE lt_model.v_pacotes_proc04_flagprop
(
  gid integer,
  cd_mun bigint,
  cd_bioma integer,
  cd_bacia character varying(14),
  geom geometry
);

--Table with final dataset
DROP TABLE IF EXISTS lt_model.v_pacotes_proc05_imoveisfull; 
CREATE TABLE lt_model.v_pacotes_proc05_imoveisfull
(
  id serial not null,
  gid_break integer,
  cd_mun bigint,
  cd_bioma integer,
  cd_bacia character varying(14),
  geom geometry
);
