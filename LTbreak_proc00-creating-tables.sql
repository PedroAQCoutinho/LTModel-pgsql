--Table with unregistred lands
DROP TABLE IF EXISTS testes.v_pacotes_proc01_unregistered; 
CREATE TABLE testes.v_pacotes_proc01_unregistered
(
  gid integer,
  cd_mun integer,
  geom geometry
);

--Table with rural properties and unregistred lands
DROP TABLE IF EXISTS testes.v_pacotes_proc02_imoveisfull; 
CREATE TABLE testes.v_pacotes_proc02_imoveisfull
(
  gid integer,
  geom geometry
);

--Table with municipalities breaks
DROP TABLE IF EXISTS testes.v_pacotes_proc03_breakmun; 
CREATE TABLE testes.v_pacotes_proc03_breakmun
(
  gid integer,
  cd_mun bigint,
  geom geometry
);

--Table with biomes breaks
DROP TABLE IF EXISTS testes.v_pacotes_proc04_breakbiome;
CREATE TABLE testes.v_pacotes_proc04_breakbiome
(
  gid integer,
  cd_mun bigint,
  cd_bioma integer,
  geom geometry
);

--Table with watershed breaks
DROP TABLE IF EXISTS testes.v_pacotes_proc05_ottobacia;
CREATE TABLE testes.v_pacotes_proc05_ottobacia
(
  gid integer,
  cd_mun bigint,
  cd_bioma integer,
  cd_bacia character varying(14),
  geom geometry
);
