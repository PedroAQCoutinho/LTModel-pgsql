SET search_path TO lt_model, public;

\copy (SELECT param_text FROM lt_model.params WHERE param_name = 'car_table_schema') TO 'var1.txt' CSV header;
\copy (SELECT param_text FROM lt_model.params WHERE param_name = 'car_table_name') TO 'var2.txt' CSV header;
\copy (SELECT param_text FROM lt_model.params WHERE param_name = 'car_mf_column') TO 'var3.txt' CSV header;

\copy (SELECT param_value FROM lt_model.params WHERE param_name = 'car_premium_overlap_tolerance_p') TO 'var7.txt' CSV header;
\copy (SELECT param_value FROM lt_model.params WHERE param_name = 'car_premium_overlap_tolerance_m') TO 'var8.txt' CSV header;
\copy (SELECT param_value FROM lt_model.params WHERE param_name = 'car_premium_overlap_tolerance_g') TO 'var9.txt' CSV header;
\copy (SELECT param_value FROM lt_model.params WHERE param_name = 'car_premium_overlap_count_p') TO 'var10.txt' CSV header;
\copy (SELECT param_value FROM lt_model.params WHERE param_name = 'car_premium_overlap_count_m') TO 'var11.txt' CSV header;
\copy (SELECT param_value FROM lt_model.params WHERE param_name = 'car_premium_overlap_count_g') TO 'var12.txt' CSV header;

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