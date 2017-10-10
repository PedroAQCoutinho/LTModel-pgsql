SET search_path TO lt_model, data, public;

ALTER TABLE lt_model.result
ADD COLUMN IF NOT EXISTS cd_mun_2006 INT;

ALTER TABLE lt_model.result
ADD COLUMN IF NOT EXISTS gid serial;

CREATE INDEX IF NOT EXISTS gix_result ON lt_model.result USING GIST(geom);
CREATE INDEX IF NOT EXISTS ix_result ON lt_model.result USING BTREE (gid);
CREATE INDEX IF NOT EXISTS pa_br_limitemunicipal_2006_ibge ON pa_br_limitemunicipal_2006_ibge USING BTREE ((codmun7 % 15));
