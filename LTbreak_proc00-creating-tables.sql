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
  gid integer,
  cd_mun bigint,
  cd_bioma integer,
  cd_bacia character varying(14),
  geom geometry
);
