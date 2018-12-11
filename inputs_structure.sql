-- Table: lt_model.inputs

-- DROP TABLE lt_model.inputs;

CREATE TABLE lt_model.inputs_whoowns
(
  proc_order integer NOT NULL,
  table_name text NOT NULL,
  ownership_class text,
  sub_class text,
  where_clause text,
  fla_proc boolean NOT NULL DEFAULT true,
  layer_name text,
  layer_source text,
  year smallint,
  orig_name text,
  id serial NOT NULL,
  column_name text
)
WITH (
  OIDS=FALSE
);