SET search_path TO recorte, public;

\copy (SELECT param_text FROM recorte.params WHERE param_name = 'car_table_schema') TO 'var1.txt' CSV header;
\copy (SELECT param_text FROM recorte.params WHERE param_name = 'car_table_name') TO 'var2.txt' CSV header;
\copy (SELECT param_text FROM recorte.params WHERE param_name = 'car_mf_column') TO 'var3.txt' CSV header;

-- DROP VIEW IF EXISTS projetos_2017.malha_relatorio_01_car_bruto_eliminate;
DROP TABLE IF EXISTS proc1_03_is_premium;
CREATE TABLE proc1_03_is_premium
(
  gid bigint,
  geom geometry,
  shape_area double precision,
  shape_leng double precision,
  area_loss DOUBLE PRECISION,
  new_area double precision,
  fla_car_premium boolean,
  rnd double precision DEFAULT random()
);

CREATE INDEX gix_proc1_03_is_premium
  ON proc1_03_is_premium
  USING gist
  (geom);
CREATE INDEX ix_proc1_03_is_premium
  ON proc1_03_is_premium
  USING btree
  (gid);
CREATE INDEX ix_proc1_03_is_premium_2
  ON proc1_03_is_premium
  USING btree
  (fla_car_premium);
CREATE INDEX ix_proc1_03_is_premium_3
  ON proc1_03_is_premium
  USING btree
  (rnd);