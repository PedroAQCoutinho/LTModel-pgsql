-- lt_model.lt_model_car_sim_po definition

-- Drop table

-- DROP TABLE lt_model.lt_model_car_sim_po;

CREATE TABLE lt_model.lt_model_car_sim_po (
	gid int4 NULL,
	original_gid int4 NULL,
	area float8 NULL,
	area_loss numeric(10, 6) NULL,
	area_original float8 NULL,
	cod_imovel text NULL,
	is_premium bool NULL,
	geom public.geometry NULL
);
CREATE INDEX ix_lt_model_car_sim_po ON lt_model.lt_model_car_sim_po USING gist (geom);
-- lt_model.lt_model_car_sim_pr definition

-- Drop table

-- DROP TABLE lt_model.lt_model_car_sim_pr;

CREATE TABLE lt_model.lt_model_car_sim_pr (
	gid int4 NULL,
	original_gid int4 NULL,
	area float8 NULL,
	area_loss numeric(10, 6) NULL,
	area_original float8 NULL,
	cod_imovel text NULL,
	is_premium bool NULL,
	geom public.geometry NULL
);
CREATE INDEX ix_lt_model_car_sim_pr ON lt_model.lt_model_car_sim_pr USING gist (geom);