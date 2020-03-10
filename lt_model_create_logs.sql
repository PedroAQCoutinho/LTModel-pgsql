CREATE TABLE lt_model.log_erros
(
  geom1 geometry,
  geom2 geometry
)
WITH (
  OIDS=FALSE
);
ALTER TABLE lt_model.log_erros
  OWNER TO atlas;
GRANT ALL ON TABLE lt_model.log_erros TO atlas;

CREATE TABLE lt_model.log_operation
(
  id serial NOT NULL,
  nom_operation text,
  proc_num smallint,
  proc_order smallint,
  CONSTRAINT log_operation_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE lt_model.log_operation
  OWNER TO atlas;
GRANT ALL ON TABLE lt_model.log_operation TO atlas;

CREATE TABLE lt_model.log_outputs
(
  id serial NOT NULL,
  num_run integer,
  fk_operation integer,
  num_geom integer,
  val_area numeric,
  CONSTRAINT log_outputs_pkey PRIMARY KEY (id),
  CONSTRAINT log_outputs_fk_operation_fkey FOREIGN KEY (fk_operation)
      REFERENCES lt_model_old.log_operation (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE lt_model.log_outputs
  OWNER TO atlas;
GRANT ALL ON TABLE lt_model.log_outputs TO atlas;

CREATE TABLE lt_model.log_simulate
(
  num_run integer,
  cod_state smallint,
  size character varying(1),
  num_census integer,
  num_known integer,
  num_simulated integer,
  perc_census numeric(5,2),
  perc_modeled numeric(5,2),
  CONSTRAINT log_simulate_size_check CHECK (size::text = ANY (ARRAY['S'::character varying::text, 'M'::character varying::text, 'L'::character varying::text]))
)
WITH (
  OIDS=FALSE
);
ALTER TABLE lt_model.log_simulate
  OWNER TO atlas;
GRANT ALL ON TABLE lt_model.log_simulate TO atlas;