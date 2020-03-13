ALTER TABLE lt_model_old.inputs_out
  ADD CONSTRAINT inputs_pkey PRIMARY KEY(id);

ALTER TABLE lt_model_old.inputs_out
  ADD CONSTRAINT uc_inputs UNIQUE(proc_order, fla_proc);

ALTER TABLE lt_model_old.inputs_out
  ADD CONSTRAINT inputs_ownership_class_check CHECK (ownership_class = ANY (ARRAY['PC'::text, 'PL'::text, 'NP'::text, 'ND'::text]));

ALTER TABLE lt_model_old.inputs_out
  ADD CONSTRAINT inputs_sub_class_check CHECK (sub_class = ANY (ARRAY['ML'::text, 'TI'::text, 'TI_H'::text, 'TI_N'::text, 'UCPI'::text, 'UCUS'::text, 'APA'::text, 'ARU'::text, 'QL'::text, 'COM'::text, 'CAR'::text, 'CARpo'::text, 'CARpr'::text, 'AG'::text, 'SIGEF'::text, 'ND'::text, 'ND_B'::text, 'ND_I'::text, 'TRANS'::text, 'URB'::text, 'TLPL'::text, 'TLPC'::text]));

CREATE INDEX ix_inputs
  ON lt_model_old.inputs_out
  USING btree
  (proc_order DESC);
ALTER TABLE lt_model_old.inputs_out CLUSTER ON ix_inputs;